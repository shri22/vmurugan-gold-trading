import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_database_service.dart';

class LocalDatabaseTestPage extends StatefulWidget {
  const LocalDatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<LocalDatabaseTestPage> createState() => _LocalDatabaseTestPageState();
}

class _LocalDatabaseTestPageState extends State<LocalDatabaseTestPage> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _nameController = TextEditingController(text: 'Test Customer');
  final _emailController = TextEditingController(text: 'test@example.com');
  final _addressController = TextEditingController(text: 'Test Address, Chennai');
  final _panController = TextEditingController(text: 'ABCDE1234F');
  
  String _status = '';
  bool _isLoading = false;
  Map<String, dynamic>? _databaseInfo;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Database Test'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // Database Info Card
            _buildDatabaseInfoCard(),
            const SizedBox(height: 16),
            
            // Test Customer Form
            _buildTestForm(),
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),
            
            // Data Display
            _buildDataDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Local SQLite Database',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Current Mode: ${ApiService.mode}'),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _status.contains('✅') ? Colors.green.shade50 : Colors.red.shade50,
                  border: Border.all(
                    color: _status.contains('✅') ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_databaseInfo != null) ...[
              Text('Database: ${_databaseInfo!['database_name'] ?? 'Unknown'}'),
              Text('Version: ${_databaseInfo!['database_version'] ?? 'Unknown'}'),
              Text('Customers: ${_databaseInfo!['customers_count'] ?? 0}'),
              Text('Transactions: ${_databaseInfo!['transactions_count'] ?? 0}'),
              Text('Schemes: ${_databaseInfo!['schemes_count'] ?? 0}'),
            ] else ...[
              const Text('Loading database info...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Customer Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Card',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSaveCustomer,
                  child: const Text('Save Customer'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSaveTransaction,
                  child: const Text('Save Transaction'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadData,
                  child: const Text('Refresh Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _exportData,
                  child: const Text('Export Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear All Data'),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisplay() {
    return Column(
      children: [
        // Customers
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customers (${_customers.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_customers.isEmpty) ...[
                  const Text('No customers found'),
                ] else ...[
                  ...(_customers.take(5).map((customer) => ListTile(
                    title: Text(customer['name'] ?? 'Unknown'),
                    subtitle: Text('${customer['phone']} • ${customer['email']}'),
                    trailing: Text('₹${customer['total_invested'] ?? 0}'),
                  ))),
                  if (_customers.length > 5) ...[
                    Text('... and ${_customers.length - 5} more'),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Transactions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions (${_transactions.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_transactions.isEmpty) ...[
                  const Text('No transactions found'),
                ] else ...[
                  ...(_transactions.take(5).map((transaction) => ListTile(
                    title: Text('${transaction['type']} - ₹${transaction['amount']}'),
                    subtitle: Text('${transaction['customer_name']} • ${transaction['status']}'),
                    trailing: Text('${transaction['gold_grams']}g'),
                  ))),
                  if (_transactions.length > 5) ...[
                    Text('... and ${_transactions.length - 5} more'),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadDatabaseInfo() async {
    try {
      final info = await LocalDatabaseService.getDatabaseInfo();
      setState(() {
        _databaseInfo = info;
      });
    } catch (e) {
      print('Error loading database info: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final customers = await LocalDatabaseService.getAllCustomers();
      final transactions = await LocalDatabaseService.getTransactions();
      
      setState(() {
        _customers = customers;
        _transactions = transactions;
      });
      
      await _loadDatabaseInfo(); // Refresh counts
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _testSaveCustomer() async {
    setState(() {
      _isLoading = true;
      _status = 'Saving customer...';
    });

    try {
      final result = await ApiService.saveCustomerInfo(
        phone: _phoneController.text,
        name: _nameController.text,
        email: _emailController.text,
        address: _addressController.text,
        panCard: _panController.text,
        deviceId: 'test_device_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _status = result['success'] == true 
            ? '✅ Customer saved successfully!' 
            : '❌ Failed: ${result['message']}';
      });

      if (result['success'] == true) {
        await _loadData();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSaveTransaction() async {
    setState(() {
      _isLoading = true;
      _status = 'Saving transaction...';
    });

    try {
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ApiService.saveTransaction(
        transactionId: transactionId,
        customerPhone: _phoneController.text,
        customerName: _nameController.text,
        type: 'BUY',
        amount: 1000.0,
        goldGrams: 0.5,
        goldPricePerGram: 2000.0,
        paymentMethod: 'UPI',
        status: 'SUCCESS',
        gatewayTransactionId: 'GW_$transactionId',
        deviceInfo: 'Test Device',
        location: 'Test Location',
      );

      setState(() {
        _status = result['success'] == true 
            ? '✅ Transaction saved successfully!' 
            : '❌ Failed: ${result['message']}';
      });

      if (result['success'] == true) {
        await _loadData();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _status = 'Exporting data...';
    });

    try {
      final result = await LocalDatabaseService.exportAllData();
      
      setState(() {
        _status = result['success'] == true 
            ? '✅ Data exported successfully!' 
            : '❌ Export failed: ${result['message']}';
      });

      if (result['success'] == true) {
        print('Exported data: ${result['data']}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Export error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all local data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Clearing all data...';
    });

    try {
      await LocalDatabaseService.clearAllData();
      
      setState(() {
        _status = '✅ All data cleared successfully!';
        _customers = [];
        _transactions = [];
      });

      await _loadDatabaseInfo();
    } catch (e) {
      setState(() {
        _status = '❌ Clear error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }
}
