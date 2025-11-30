import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/sql_server_service.dart';

/// Monthly Report Screen
class MonthlyReportScreen extends StatefulWidget {
  final String? customerPhone;

  const MonthlyReportScreen({
    Key? key,
    this.customerPhone,
  }) : super(key: key);

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  Future<void> _loadMonthlyReport() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement API call to fetch monthly report
      // For now, using placeholder data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _reportData = {
          'total_transactions': 5,
          'total_amount': 25000.0,
          'total_gold_grams': 2.5,
          'total_silver_grams': 10.0,
          'scheme_payments': 3,
          'direct_purchases': 2,
        };
      });
    } catch (e) {
      print('❌ Error loading monthly report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: AppColors.primaryGreen,
        ),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryGold.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                    _loadMonthlyReport();
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedMonth.month == DateTime.now().month &&
                          _selectedMonth.year == DateTime.now().year
                      ? null
                      : () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          });
                          _loadMonthlyReport();
                        },
                ),
              ],
            ),
          ),

          // Report Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData == null
                    ? const Center(child: Text('No data available'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 16),
                          _buildMetalAccumulationCard(),
                          const SizedBox(height: 16),
                          _buildTransactionBreakdownCard(),
                        ],
                      ),
          ),

          // Download Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryRow('Total Transactions', '${_reportData!['total_transactions']}'),
            _buildSummaryRow('Total Amount', '₹${_reportData!['total_amount'].toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalAccumulationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metal Accumulated',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryRow('Gold', '${_reportData!['total_gold_grams'].toStringAsFixed(4)} g'),
            _buildSummaryRow('Silver', '${_reportData!['total_silver_grams'].toStringAsFixed(4)} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryRow('Scheme Payments', '${_reportData!['scheme_payments']}'),
            _buildSummaryRow('Direct Purchases', '${_reportData!['direct_purchases']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _downloadReport() {
    // TODO: Implement PDF download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF download feature coming soon!')),
    );
  }
}

