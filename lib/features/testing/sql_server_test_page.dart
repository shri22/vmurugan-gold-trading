import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/sql_server_api_service.dart';
import '../../core/config/sql_server_config.dart';

class SqlServerTestPage extends StatefulWidget {
  const SqlServerTestPage({Key? key}) : super(key: key);

  @override
  State<SqlServerTestPage> createState() => _SqlServerTestPageState();
}

class _SqlServerTestPageState extends State<SqlServerTestPage> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _nameController = TextEditingController(text: 'Test Customer');
  final _emailController = TextEditingController(text: 'test@vmurugan.com');
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
        title: const Text('SQL Server Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // Configuration Card
            _buildConfigurationCard(),
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
                Icon(Icons.dns, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'SQL Server (SSMS) Database',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Current Mode: ${ApiService.mode}'),
            Text('Configured: ${SqlServerConfig.isConfigured ? "Yes" : "No"}'),
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

  Widget _buildConfigurationCard() {
    final config = SqlServerConfig.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SQL Server Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Server IP: ${config['server_ip']}'),
            Text('Port: ${config['port']}'),
            Text('Database: ${config['database']}'),
            Text('Username: ${config['username']}'),
            Text('Password Set: ${config['password_set']}'),
            const SizedBox(height: 8),
            if (!SqlServerConfig.isConfigured) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Configuration Required',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Update sql_server_config.dart with your SQL Server details'),
                  ],
                ),
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
              Text('Server: ${_databaseInfo!['server_ip'] ?? 'Unknown'}'),
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
                  onPressed: _isLoading ? null : _testConnection,
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _initializeDatabase,
                  child: const Text('Initialize DB'),
                ),
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
                    title: Text(customer['name']?.toString() ?? 'Unknown'),
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

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing SQL Server connection...';
    });

    try {
      final result = await SqlServerApiService.testConnection();
      
      setState(() {
        _status = result['success'] == true 
            ? '✅ SQL Server connection successful!' 
            : '❌ Connection failed: ${result['message']}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing SQL Server database...';
    });

    try {
      final result = await SqlServerApiService.initialize();
      
      setState(() {
        _status = result['success'] == true 
            ? '✅ Database initialized successfully!' 
            : '❌ Initialization failed: ${result['message']}';
      });

      if (result['success'] == true) {
        await _loadDatabaseInfo();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Initialization error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDatabaseInfo() async {
    try {
      final result = await SqlServerApiService.getDatabaseInfo();
      if (result['success'] == true) {
        setState(() {
          _databaseInfo = result['database_info'];
        });
      }
    } catch (e) {
      print('Error loading database info: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final customers = await SqlServerApiService.getAllCustomers();
      final transactionsResult = await SqlServerApiService.getTransactions();
      
      setState(() {
        _customers = customers;
        _transactions = transactionsResult['success'] == true 
            ? List<Map<String, dynamic>>.from(transactionsResult['transactions'] ?? [])
            : [];
      });
      
      await _loadDatabaseInfo(); // Refresh counts
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _testSaveCustomer() async {
    setState(() {
      _isLoading = true;
      _status = 'Saving customer to SQL Server...';
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
            ? '✅ Customer saved to SQL Server successfully!' 
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
      _status = 'Saving transaction to SQL Server...';
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
            ? '✅ Transaction saved to SQL Server successfully!' 
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
      _status = 'Exporting data from SQL Server...';
    });

    try {
      final result = await SqlServerApiService.exportData(
        adminToken: 'VMURUGAN_ADMIN_2025',
      );
      
      setState(() {
        _status = result['success'] == true 
            ? '✅ Data exported from SQL Server successfully!' 
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
