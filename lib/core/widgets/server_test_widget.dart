import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../services/api_service.dart';

class ServerTestWidget extends StatefulWidget {
  const ServerTestWidget({Key? key}) : super(key: key);

  @override
  State<ServerTestWidget> createState() => _ServerTestWidgetState();
}

class _ServerTestWidgetState extends State<ServerTestWidget> {
  String _status = 'Not tested';
  bool _isLoading = false;
  Map<String, dynamic>? _serverInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.server, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Server Connection Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Configuration Status
            _buildConfigSection(),
            const SizedBox(height: 16),
            
            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                border: Border.all(color: _getStatusColor()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getStatusIcon(), color: _getStatusColor()),
                      const SizedBox(width: 8),
                      Text(
                        'Status: $_status',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_serverInfo != null) ...[
                    const SizedBox(height: 8),
                    Text('Server: ${_serverInfo!['service'] ?? 'Unknown'}'),
                    Text('Time: ${_serverInfo!['timestamp'] ?? 'Unknown'}'),
                  ],
                ],
              ),
            ),
            
            // Setup Instructions
            if (!ServerConfig.isConfigured) ...[
              const SizedBox(height: 16),
              _buildSetupInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    final config = ServerConfig.status;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('URL: ${config['base_url']}'),
          Text('IP: ${config['teammate_ip']}'),
          Text('Port: ${config['port']}'),
          Text('Configured: ${config['configured'] ? 'Yes' : 'No'}'),
        ],
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Setup Required',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ServerConfig.setupInstructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $instruction'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
      _serverInfo = null;
    });

    try {
      // Test health endpoint
      final healthUrl = ServerConfig.baseUrl.replaceAll('/api', '/health');
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.body;
        setState(() {
          _status = 'Connected ✅';
          _serverInfo = {
            'service': 'Digi Gold Business API',
            'timestamp': DateTime.now().toString(),
          };
        });
        
        // Test API endpoint
        await _testApiEndpoint();
      } else {
        setState(() {
          _status = 'Server responded with error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testApiEndpoint() async {
    try {
      // Test saving a customer
      final result = await ApiService.saveCustomerInfo(
        phone: '9999999999',
        name: 'Test Customer',
        email: 'test@example.com',
        address: 'Test Address',
        panCard: 'ABCDE1234F',
        deviceId: 'test_device',
      );

      if (result['success'] == true) {
        setState(() {
          _status = 'API Test Successful ✅';
        });
      } else {
        setState(() {
          _status = 'API Test Failed: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'API Test Error: ${e.toString()}';
      });
    }
  }

  Color _getStatusColor() {
    if (_status.contains('✅')) return Colors.green;
    if (_status.contains('failed') || _status.contains('Error')) return Colors.red;
    if (_status.contains('Testing')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_status.contains('✅')) return Icons.check_circle;
    if (_status.contains('failed') || _status.contains('Error')) return Icons.error;
    if (_status.contains('Testing')) return Icons.sync;
    return Icons.help;
  }
}
