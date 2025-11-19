import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../gold/services/gold_price_service.dart';
import '../../silver/services/silver_price_service.dart';
import '../../gold/services/mjdta_price_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PriceDebugScreen extends StatefulWidget {
  const PriceDebugScreen({super.key});

  @override
  State<PriceDebugScreen> createState() => _PriceDebugScreenState();
}

class _PriceDebugScreenState extends State<PriceDebugScreen> {
  final GoldPriceService _goldService = GoldPriceService();
  final SilverPriceService _silverService = SilverPriceService();
  final MjdtaPriceService _mjdtaService = MjdtaPriceService();
  
  Map<String, dynamic>? _goldDiagnostics;
  Map<String, dynamic>? _silverDiagnostics;
  Map<String, dynamic>? _mjdtaTest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goldService.initialize();
    _silverService.initialize();
  }

  @override
  void dispose() {
    _goldService.dispose();
    _silverService.dispose();
    super.dispose();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _goldDiagnostics = null;
      _silverDiagnostics = null;
      _mjdtaTest = null;
    });

    try {
      // Run MJDTA test
      _mjdtaTest = await _mjdtaService.testPriceFetching();
      setState(() {});

      // Run silver diagnostics
      _silverDiagnostics = await _silverService.runDiagnostics();
      setState(() {});

      // Run gold diagnostics (if available)
      // _goldDiagnostics = await _goldService.runDiagnostics();
      setState(() {});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running tests: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Fetch Debug'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runAllTests,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runAllTests,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? 'Running Tests...' : 'Run All Tests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Current Service Status
            _buildServiceStatusCard(),

            const SizedBox(height: AppSpacing.lg),

            // MJDTA Test Results
            if (_mjdtaTest != null) _buildMjdtaTestCard(),

            const SizedBox(height: AppSpacing.lg),

            // Silver Diagnostics
            if (_silverDiagnostics != null) _buildSilverDiagnosticsCard(),

            const SizedBox(height: AppSpacing.lg),

            // Gold Diagnostics
            if (_goldDiagnostics != null) _buildGoldDiagnosticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Service Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStatusRow('Gold Service Available', _goldService.isMjdtaAvailable),
            _buildStatusRow('Silver Service Available', _silverService.isMjdtaAvailable),
            _buildStatusRow('Gold Can Purchase', _goldService.canPurchase),
            _buildStatusRow('Silver Can Purchase', _silverService.canPurchase),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gold Price: ${_goldService.currentPrice?.formattedPrice ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Silver Price: ${_silverService.currentPrice?.formattedPrice ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildMjdtaTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MJDTA Connection Test',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _mjdtaTest.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildJsonDisplay(_mjdtaTest!),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverDiagnosticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Silver Service Diagnostics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _silverDiagnostics.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildJsonDisplay(_silverDiagnostics!),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldDiagnosticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold Service Diagnostics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildJsonDisplay(_goldDiagnostics!),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonDisplay(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(
        _formatJson(data),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _formatJsonRecursive(data, buffer, 0);
    return buffer.toString();
  }

  void _formatJsonRecursive(dynamic data, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    
    if (data is Map) {
      buffer.writeln('{');
      final entries = data.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$indentStr  "${entry.key}": ');
        _formatJsonRecursive(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr}');
    } else if (data is List) {
      buffer.write('[');
      for (int i = 0; i < data.length; i++) {
        _formatJsonRecursive(data[i], buffer, indent);
        if (i < data.length - 1) buffer.write(', ');
      }
      buffer.write(']');
    } else if (data is String) {
      buffer.write('"$data"');
    } else {
      buffer.write(data.toString());
    }
  }
}
