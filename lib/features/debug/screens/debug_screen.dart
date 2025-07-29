import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/screens/enhanced_phone_entry_screen.dart';
import 'sms_debug_screen.dart';
import 'sms_provider_test_screen.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;
  bool _enhancedAuthEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadEnhancedAuthState();
  }

  Future<void> _loadEnhancedAuthState() async {
    final isEnabled = await AuthService.isEnhancedFlowEnabled();
    setState(() {
      _enhancedAuthEnabled = isEnabled;
    });
  }

  Future<void> _toggleEnhancedAuth(bool enabled) async {
    await AuthService.setEnhancedFlowEnabled(enabled);
    setState(() {
      _enhancedAuthEnabled = enabled;
    });

    _addOutput(
      enabled
          ? '✅ Enhanced authentication flow ENABLED'
          : '❌ Enhanced authentication flow DISABLED'
    );
  }

  void _testEnhancedAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedPhoneEntryScreen(),
      ),
    );
  }

  void _openSmsDebug() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SmsDebugScreen(),
      ),
    );
  }

  void _openSmsProviderTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SmsProviderTestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Test'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkCustomerInfo,
                  child: const Text('Check Customer Info'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkFirebaseData,
                  child: const Text('Check Firebase Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSchemeCreation,
                  child: const Text('Test Scheme Creation'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkTransactions,
                  child: const Text('Check Transactions'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkSchemes,
                  child: const Text('Check Schemes'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDirectFirebaseScheme,
                  child: const Text('Test Direct Firebase'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSchemeCounter,
                  child: const Text('Test Scheme Counter'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateConfiguration,
                  child: const Text('Validate Config'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearOutput,
                  child: const Text('Clear Output'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Enhanced Authentication Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Authentication Flow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'New step-by-step authentication: Phone → Registration/Login → OTP → MPIN',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Enable Enhanced Flow'),
                            subtitle: Text(
                              _enhancedAuthEnabled
                                  ? 'Enhanced flow is ACTIVE'
                                  : 'Using original login screen',
                            ),
                            value: _enhancedAuthEnabled,
                            onChanged: _toggleEnhancedAuth,
                            activeColor: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _testEnhancedAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Enhanced Flow'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _openSmsDebug,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('SMS Config'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _openSmsProviderTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('SMS Test'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Debug output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _debugOutput.isEmpty ? 'Debug output will appear here...' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Copy button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _debugOutput.isEmpty ? null : _copyOutput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Copy Output'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  void _clearOutput() {
    setState(() {
      _debugOutput = '';
    });
  }

  void _copyOutput() {
    Clipboard.setData(ClipboardData(text: _debugOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug output copied to clipboard')),
    );
  }

  Future<void> _checkCustomerInfo() async {
    setState(() => _isLoading = true);
    
    try {
      _addOutput('=== CHECKING CUSTOMER INFO ===');
      
      final customerInfo = await CustomerService.getCustomerInfo();
      _addOutput('Local Customer Info:');
      customerInfo.forEach((key, value) {
        _addOutput('  $key: $value');
      });
      
      final isRegistered = await CustomerService.isCustomerRegistered();
      _addOutput('Is Registered: $isRegistered');
      
      if (customerInfo['phone'] != null) {
        _addOutput('\n=== CHECKING FIREBASE CUSTOMER ===');
        final result = await ApiService.getCustomerByPhone(customerInfo['phone']!);
        _addOutput('Firebase Result: ${result['success']}');
        if (result['success'] && result['customer'] != null) {
          final customer = result['customer'];
          _addOutput('Firebase Customer:');
          customer.forEach((key, value) {
            _addOutput('  $key: $value');
          });
        } else {
          _addOutput('Customer not found in Firebase: ${result['message']}');
        }
      }
      
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFirebaseData() async {
    setState(() => _isLoading = true);
    
    try {
      _addOutput('=== CHECKING FIREBASE COLLECTIONS ===');
      
      // Check transactions
      _addOutput('\n--- Checking Transactions ---');
      final transactionResult = await ApiService.getTransactions();
      _addOutput('Transactions Result: ${transactionResult['success']}');
      if (transactionResult['success']) {
        final transactions = transactionResult['transactions'] as List;
        _addOutput('Total Transactions: ${transactions.length}');
        for (int i = 0; i < transactions.length && i < 3; i++) {
          final txn = transactions[i];
          _addOutput('Transaction ${i + 1}:');
          _addOutput('  ID: ${txn['transaction_id']}');
          _addOutput('  Customer ID: ${txn['customer_id']}');
          _addOutput('  Amount: ₹${txn['amount']}');
          _addOutput('  Gold: ${txn['gold_grams']}g');
          _addOutput('  Status: ${txn['status']}');
        }
      }
      
      // Check dashboard data
      _addOutput('\n--- Checking Dashboard Data ---');
      final dashboardResult = await ApiService.getDashboardData(adminToken: 'debug_token');
      _addOutput('Dashboard Result: ${dashboardResult['success']}');
      if (dashboardResult['success']) {
        final data = dashboardResult['data'];
        _addOutput('Dashboard Data:');
        data.forEach((key, value) {
          _addOutput('  $key: $value');
        });
      }
      
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSchemeCreation() async {
    setState(() => _isLoading = true);

    try {
      _addOutput('=== TESTING SCHEME CREATION ===');

      final customerInfo = await CustomerService.getCustomerInfo();
      _addOutput('Customer Info Retrieved:');
      customerInfo.forEach((key, value) {
        _addOutput('  $key: $value');
      });

      final customerId = customerInfo['customer_id'];

      if (customerId == null || customerId.isEmpty) {
        _addOutput('❌ ERROR: No customer ID found. Please login with registered number first.');
        _addOutput('💡 TIP: Go to login screen, use registered phone number + any 4-digit MPIN');
        return;
      }

      _addOutput('\n🎯 Customer ID Found: $customerId');

      // Generate scheme ID
      _addOutput('\n--- Generating Scheme ID ---');
      final schemeId = await ApiService.generateSchemeId(customerId);
      _addOutput('✅ Generated Scheme ID: $schemeId');

      // Create test scheme
      _addOutput('\n--- Creating Test Scheme ---');
      final result = await ApiService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? '',
        customerName: customerInfo['name'] ?? '',
        monthlyAmount: 1500.0,
        durationMonths: 11,
        schemeType: 'MONTHLY_SAVINGS',
        status: 'ACTIVE',
      );

      _addOutput('\n--- Scheme Creation Results ---');
      _addOutput('Success: ${result['success']}');
      _addOutput('Message: ${result['message']}');

      if (result['success']) {
        _addOutput('✅ SCHEME CREATED SUCCESSFULLY!');
        _addOutput('🆔 Scheme ID: ${result['scheme_id']}');
        _addOutput('💰 Monthly Amount: ₹1500');
        _addOutput('📅 Duration: 11 months');
        _addOutput('🎯 Total Target: ₹16,500');
        _addOutput('📊 Status: ACTIVE');

        // Try to create a second scheme
        _addOutput('\n--- Creating Second Scheme ---');
        final schemeId2 = await ApiService.generateSchemeId(customerId);
        final result2 = await ApiService.saveScheme(
          schemeId: schemeId2,
          customerId: customerId,
          customerPhone: customerInfo['phone'] ?? '',
          customerName: customerInfo['name'] ?? '',
          monthlyAmount: 2000.0,
          durationMonths: 11,
          schemeType: 'FESTIVAL_SPECIAL',
          status: 'ACTIVE',
        );

        if (result2['success']) {
          _addOutput('✅ SECOND SCHEME CREATED!');
          _addOutput('🆔 Scheme ID: ${result2['scheme_id']}');
          _addOutput('💰 Monthly Amount: ₹2000');
          _addOutput('\n🎉 SUCCESS: Customer $customerId now has 2 schemes!');
        }
      } else {
        _addOutput('❌ SCHEME CREATION FAILED');
        _addOutput('Error Details: ${result['message']}');
      }

    } catch (e) {
      _addOutput('❌ EXCEPTION: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      _addOutput('=== CHECKING TRANSACTIONS ===');
      
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'];
      
      if (customerPhone == null) {
        _addOutput('ERROR: No customer phone found');
        return;
      }
      
      _addOutput('Customer Phone: $customerPhone');
      
      // Get all transactions
      final result = await ApiService.getTransactions();
      _addOutput('Get Transactions Result: ${result['success']}');
      
      if (result['success']) {
        final allTransactions = result['transactions'] as List;
        _addOutput('Total Transactions in Firebase: ${allTransactions.length}');
        
        // Filter transactions for this customer
        final customerTransactions = allTransactions.where((txn) => 
          txn['customer_phone'] == customerPhone
        ).toList();
        
        _addOutput('Customer Transactions: ${customerTransactions.length}');
        
        for (int i = 0; i < customerTransactions.length; i++) {
          final txn = customerTransactions[i];
          _addOutput('\nTransaction ${i + 1}:');
          _addOutput('  ID: ${txn['transaction_id']}');
          _addOutput('  Customer ID: ${txn['customer_id']}');
          _addOutput('  Scheme ID: ${txn['scheme_id']}');
          _addOutput('  Amount: ₹${txn['amount']}');
          _addOutput('  Gold: ${txn['gold_grams']}g');
          _addOutput('  Date: ${txn['timestamp']}');
          _addOutput('  Status: ${txn['status']}');
        }
      }
      
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSchemes() async {
    setState(() => _isLoading = true);

    try {
      _addOutput('=== CHECKING SCHEMES ===');

      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'];
      final customerId = customerInfo['customer_id'];

      if (customerPhone == null) {
        _addOutput('ERROR: No customer phone found');
        return;
      }

      _addOutput('Customer Phone: $customerPhone');
      _addOutput('Customer ID: $customerId');

      // For now, we'll need to implement a getSchemes method in ApiService
      // Let's check if we can find schemes by making a direct Firebase call
      _addOutput('\n--- Checking Firebase for Schemes ---');
      _addOutput('Note: Scheme checking functionality needs to be implemented');
      _addOutput('Schemes should be stored in Firebase under "schemes" collection');
      _addOutput('Each scheme should have customer_id field linking to customer');

      if (customerId != null) {
        _addOutput('\n--- Expected Scheme IDs for this customer ---');
        _addOutput('First scheme: $customerId-S01');
        _addOutput('Second scheme: $customerId-S02');
        _addOutput('Third scheme: $customerId-S03');
        _addOutput('etc...');
      }

    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDirectFirebaseScheme() async {
    setState(() => _isLoading = true);

    try {
      _addOutput('=== TESTING DIRECT FIREBASE SCHEME CREATION ===');

      final customerInfo = await CustomerService.getCustomerInfo();
      _addOutput('Customer Info:');
      customerInfo.forEach((key, value) {
        _addOutput('  $key: $value');
      });

      final customerId = customerInfo['customer_id'];

      if (customerId == null || customerId.isEmpty) {
        _addOutput('❌ ERROR: No customer ID found');
        _addOutput('💡 Please login with registered phone number first');
        return;
      }

      _addOutput('\n🎯 Testing with Customer ID: $customerId');

      // Test scheme ID generation
      _addOutput('\n--- Testing Scheme ID Generation ---');
      final schemeId = await ApiService.generateSchemeId(customerId);
      _addOutput('✅ Generated Scheme ID: $schemeId');

      // Test direct Firebase scheme save
      _addOutput('\n--- Testing Direct Firebase Save ---');
      final result = await ApiService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? 'unknown',
        customerName: customerInfo['name'] ?? 'Test User',
        monthlyAmount: 1500.0,
        durationMonths: 11,
        schemeType: 'DEBUG_TEST_SCHEME',
        status: 'ACTIVE',
      );

      _addOutput('\n--- Firebase Save Results ---');
      _addOutput('Success: ${result['success']}');
      _addOutput('Message: ${result['message']}');

      if (result['success']) {
        _addOutput('✅ SCHEME SAVED TO FIREBASE!');
        _addOutput('🆔 Scheme ID: ${result['scheme_id']}');
        _addOutput('📍 Collection: schemes');
        _addOutput('🔗 Document ID: $schemeId');
        _addOutput('\n🎯 CHECK FIREBASE CONSOLE NOW!');
        _addOutput('1. Go to Firebase Console');
        _addOutput('2. Select vmurugan-gold-trading project');
        _addOutput('3. Go to Firestore Database');
        _addOutput('4. Look for "schemes" collection');
        _addOutput('5. Find document: $schemeId');
      } else {
        _addOutput('❌ FIREBASE SAVE FAILED');
        _addOutput('Error: ${result['message']}');
      }

      // Test creating a second scheme
      _addOutput('\n--- Testing Second Scheme Creation ---');
      final schemeId2 = await ApiService.generateSchemeId(customerId);
      _addOutput('Generated Second Scheme ID: $schemeId2');

      final result2 = await ApiService.saveScheme(
        schemeId: schemeId2,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? 'unknown',
        customerName: customerInfo['name'] ?? 'Test User',
        monthlyAmount: 2000.0,
        durationMonths: 11,
        schemeType: 'DEBUG_TEST_SCHEME_2',
        status: 'ACTIVE',
      );

      if (result2['success']) {
        _addOutput('✅ SECOND SCHEME SAVED!');
        _addOutput('🆔 Second Scheme ID: ${result2['scheme_id']}');
        _addOutput('\n🎉 SUCCESS: Customer $customerId now has 2 schemes!');
        _addOutput('Scheme 1: $schemeId (₹1500/month)');
        _addOutput('Scheme 2: $schemeId2 (₹2000/month)');
      }

    } catch (e) {
      _addOutput('❌ EXCEPTION: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSchemeCounter() async {
    setState(() => _isLoading = true);

    try {
      _addOutput('=== TESTING SCHEME COUNTER SYSTEM ===');

      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      if (customerId == null || customerId.isEmpty) {
        _addOutput('❌ ERROR: No customer ID found');
        return;
      }

      _addOutput('🎯 Customer ID: $customerId');

      // Test scheme ID generation multiple times
      _addOutput('\n--- Testing Scheme ID Generation ---');
      for (int i = 1; i <= 3; i++) {
        final schemeId = await ApiService.generateSchemeId(customerId);
        _addOutput('Attempt $i: $schemeId');
      }

      // Test if counter exists in Firebase
      _addOutput('\n--- Checking Counter in Firebase ---');
      _addOutput('Counter should be at: counters/scheme_counter_$customerId');
      _addOutput('Expected format: $customerId-S01, $customerId-S02, etc.');

      // Test actual scheme creation with detailed logging
      _addOutput('\n--- Testing Scheme Creation with Full Logging ---');
      final testSchemeId = await ApiService.generateSchemeId(customerId);
      _addOutput('Generated ID: $testSchemeId');

      _addOutput('Creating scheme with these details:');
      _addOutput('  Scheme ID: $testSchemeId');
      _addOutput('  Customer ID: $customerId');
      _addOutput('  Phone: ${customerInfo['phone']}');
      _addOutput('  Name: ${customerInfo['name']}');
      _addOutput('  Monthly Amount: ₹1000');
      _addOutput('  Duration: 11 months');
      _addOutput('  Type: DEBUG_COUNTER_TEST');

      final result = await ApiService.saveScheme(
        schemeId: testSchemeId,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? 'unknown',
        customerName: customerInfo['name'] ?? 'Test User',
        monthlyAmount: 1000.0,
        durationMonths: 11,
        schemeType: 'DEBUG_COUNTER_TEST',
        status: 'ACTIVE',
      );

      _addOutput('\n--- Scheme Creation Result ---');
      _addOutput('Success: ${result['success']}');
      _addOutput('Message: ${result['message']}');

      if (result['success']) {
        _addOutput('✅ SCHEME CREATED SUCCESSFULLY!');
        _addOutput('🆔 Scheme ID: ${result['scheme_id']}');
        _addOutput('\n🔍 NOW CHECK FIREBASE CONSOLE:');
        _addOutput('1. Go to Firebase Console');
        _addOutput('2. Open Firestore Database');
        _addOutput('3. Look for "schemes" collection');
        _addOutput('4. Find document: $testSchemeId');
        _addOutput('5. Also check "counters" collection');
        _addOutput('6. Find document: scheme_counter_$customerId');
      } else {
        _addOutput('❌ SCHEME CREATION FAILED');
        _addOutput('This is why you don\'t see schemes in Firebase!');
      }

    } catch (e) {
      _addOutput('❌ EXCEPTION: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateConfiguration() async {
    setState(() => _isLoading = true);

    try {
      _addOutput('=== VALIDATING FIREBASE CONFIGURATION ===');

      _addOutput('📋 Current Configuration:');
      _addOutput('  Project ID: ${FirebaseConfig.projectId}');
      _addOutput('  API Key: ${FirebaseConfig.apiKey.substring(0, 20)}...');
      _addOutput('  Business ID: ${FirebaseConfig.businessId}');
      _addOutput('  Firestore URL: ${FirebaseConfig.firestoreUrl}');

      _addOutput('\n🔍 Configuration Status:');
      final status = FirebaseConfig.status;
      _addOutput('  Configured: ${status['configured']}');
      _addOutput('  Message: ${status['message']}');

      if (status['configured']) {
        _addOutput('✅ CONFIGURATION IS VALID');

        // Test actual Firebase connectivity
        _addOutput('\n🌐 Testing Firebase Connectivity...');

        try {
          final result = await ApiService.getCustomerByPhone('test');
          _addOutput('✅ Firebase API accessible');
        } catch (e) {
          _addOutput('❌ Firebase API error: $e');
        }

        // Test scheme creation permissions
        _addOutput('\n🔐 Testing Scheme Creation Permissions...');

        final customerInfo = await CustomerService.getCustomerInfo();
        final customerId = customerInfo['customer_id'];

        if (customerId != null && customerId.isNotEmpty) {
          _addOutput('✅ Customer ID available: $customerId');

          // Test scheme ID generation
          try {
            final schemeId = await ApiService.generateSchemeId(customerId);
            _addOutput('✅ Scheme ID generation works: $schemeId');
          } catch (e) {
            _addOutput('❌ Scheme ID generation failed: $e');
          }
        } else {
          _addOutput('⚠️ No customer ID - please login first');
        }

      } else {
        _addOutput('❌ CONFIGURATION IS INVALID');
        if (status['instructions'] != null) {
          _addOutput('\n📝 Instructions:');
          for (String instruction in status['instructions']) {
            _addOutput('  $instruction');
          }
        }
      }

    } catch (e) {
      _addOutput('❌ VALIDATION ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
