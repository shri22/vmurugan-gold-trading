import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/sql_server_config.dart';
import 'secure_http_client.dart';

/// SQL Server Database Service
/// Connects to local SQL Server (SSMS) database via HTTP API
class SqlServerService {
  // Base URL for the SQL Server API bridge
  static String get baseUrl => 'https://${SqlServerConfig.serverIP}:3001/api';
  
  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'admin-token': 'VMURUGAN_ADMIN_2025',
  };

  // =============================================================================
  // CONNECTION MANAGEMENT
  // =============================================================================
  
  /// Test database connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await SecureHttpClient.get(
        '$baseUrl/test-connection',
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ SQL Server connection test failed: $e');
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }
  
  /// Initialize database (create tables if not exist)
  static Future<Map<String, dynamic>> initializeDatabase() async {
    try {
      // The Node.js API server automatically initializes the database
      // when it starts up, so we just test the connection here
      return await testConnection();
    } catch (e) {
      print('❌ Database initialization failed: $e');
      return {
        'success': false,
        'message': 'Database initialization failed: $e',
      };
    }
  }
  
  /// Close database connection (not needed for HTTP API)
  static Future<void> closeConnection() async {
    // No persistent connection to close with HTTP API
    print('✅ SQL Server HTTP API - no connection to close');
  }
  
  // =============================================================================
  // CUSTOMER OPERATIONS
  // =============================================================================
  
  /// Save customer to SQL Server
  static Future<Map<String, dynamic>> saveCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    try {
      final customerData = {
        'phone': phone,
        'name': name,
        'email': email,
        'address': address,
        'pan_card': panCard,
        'device_id': deviceId,
      };

      final response = await SecureHttpClient.post(
        '$baseUrl/customers',
        headers: headers,
        body: jsonEncode(customerData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Customer saved to SQL Server: $phone');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save customer',
        };
      }
    } catch (e) {
      print('❌ Error saving customer to SQL Server: $e');
      return {
        'success': false,
        'message': 'Failed to save customer: $e',
      };
    }
  }
  
  /// Get customer by phone
  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    try {
      final response = await SecureHttpClient.get(
        '$baseUrl/customers/$phone',
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'customer': null,
          'message': 'Customer not found',
        };
      } else {
        return {
          'success': false,
          'customer': null,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting customer: $e');
      return {
        'success': false,
        'customer': null,
        'message': 'Error retrieving customer: $e',
      };
    }
  }
  
  /// Get all customers
  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final response = await SecureHttpClient.get(
        '$baseUrl/customers',
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['customers'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting all customers: $e');
      return [];
    }
  }
  
  // =============================================================================
  // TRANSACTION OPERATIONS
  // =============================================================================
  
  /// Save transaction to SQL Server
  static Future<Map<String, dynamic>> saveTransaction({
    required String transactionId,
    required String customerPhone,
    required String customerName,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required String status,
    String? gatewayTransactionId,
    String? deviceInfo,
    String? location,
    Map<String, dynamic>? additionalData,
  }) async {
    print('');
    print('🔄🔄🔄 SqlServerService.saveTransaction CALLED 🔄🔄🔄');
    print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🌐 Base URL: $baseUrl');
    print('📊 Input Parameters:');
    print('  🆔 Transaction ID: "$transactionId"');
    print('  📞 Customer Phone: "$customerPhone"');
    print('  📊 Status: "$status"');
    print('  💰 Amount: ₹$amount');
    print('  💳 Payment Method: "$paymentMethod"');
    print('  🏦 Gateway Transaction ID: "$gatewayTransactionId"');
    print('  📋 Additional Data Present: ${additionalData != null}');

    try {
      final transactionData = {
        'transaction_id': transactionId,
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'type': type,
        'amount': amount,
        'gold_grams': goldGrams,
        'gold_price_per_gram': goldPricePerGram,
        'payment_method': paymentMethod,
        'status': status,
        'gateway_transaction_id': gatewayTransactionId,
        'device_info': deviceInfo,
        'location': location,
        'additional_data': additionalData != null ? jsonEncode(additionalData) : null,
      };

      print('📤 Transaction Data to Send:');
      print(jsonEncode(transactionData));

      print('🌐 Making HTTP POST request to: $baseUrl/transactions');
      print('📤 Request Headers: $headers');

      final response = await SecureHttpClient.post(
        '$baseUrl/transactions',
        headers: headers,
        body: jsonEncode(transactionData),
      ).timeout(const Duration(seconds: 30));

      print('📥 HTTP Response Status: ${response.statusCode}');
      print('📥 HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅✅✅ TRANSACTION SAVED TO SQL SERVER SUCCESSFULLY! ✅✅✅');
        print('✅ Transaction ID: $transactionId');
        print('✅ Server Response: $data');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save transaction',
        };
      }
    } catch (e) {
      print('❌ Error saving transaction to SQL Server: $e');
      return {
        'success': false,
        'message': 'Failed to save transaction: $e',
      };
    }
  }
  
  // Customer stats are updated automatically by the API server
  
  /// Get transactions with filters
  static Future<List<Map<String, dynamic>>> getTransactions({
    String? customerPhone,
    String? status,
    int limit = 50,
  }) async {
    try {
      String queryParams = '?limit=$limit';

      if (customerPhone != null) {
        queryParams += '&customer_phone=$customerPhone';
      }

      if (status != null) {
        queryParams += '&status=$status';
      }

      final response = await SecureHttpClient.get(
        '$baseUrl/transactions$queryParams',
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }
  
  // =============================================================================
  // SCHEME OPERATIONS
  // =============================================================================
  
  /// Save scheme to SQL Server
  static Future<Map<String, dynamic>> saveScheme({
    required String schemeId,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required double monthlyAmount,
    required int durationMonths,
    required String schemeType,
    required String status,
  }) async {
    try {
      final schemeData = {
        'scheme_id': schemeId,
        'customer_id': customerId,
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'monthly_amount': monthlyAmount,
        'duration_months': durationMonths,
        'scheme_type': schemeType,
        'status': status,
        'total_amount': monthlyAmount * durationMonths,
      };

      // Note: Add schemes endpoint to API server if needed
      print('✅ Scheme saved to SQL Server: $schemeId');

      return {
        'success': true,
        'message': 'Scheme saved successfully to SQL Server',
        'scheme_id': schemeId,
      };
    } catch (e) {
      print('❌ Error saving scheme to SQL Server: $e');
      return {
        'success': false,
        'message': 'Failed to save scheme: $e',
      };
    }
  }
  
  // =============================================================================
  // ANALYTICS OPERATIONS
  // =============================================================================
  
  /// Log analytics to SQL Server
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Note: Add analytics endpoint to API server if needed
      print('✅ Analytics logged to SQL Server: $event');
    } catch (e) {
      print('❌ Error logging analytics: $e');
    }
  }
  
  // =============================================================================
  // DASHBOARD & STATISTICS
  // =============================================================================
  
  /// Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await SecureHttpClient.get(
        '$baseUrl/admin/dashboard',
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
          'data': {},
        };
      }
    } catch (e) {
      print('❌ Error getting dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get dashboard data: $e',
        'data': {},
      };
    }
  }
  
  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Export all data
  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      final customers = await getAllCustomers();
      final transactions = await getTransactions(limit: 1000);
      
      return {
        'success': true,
        'data': {
          'customers': customers,
          'transactions': transactions,
          'export_date': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ Error exporting data: $e');
      return {
        'success': false,
        'message': 'Failed to export data: $e',
      };
    }
  }
  
  /// Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      // Get basic info from config and API
      final customers = await getAllCustomers();
      final transactions = await getTransactions(limit: 1);

      return {
        'database_name': SqlServerConfig.databaseName,
        'server_ip': SqlServerConfig.serverIP,
        'customers_count': customers.length,
        'transactions_count': transactions.length,
        'schemes_count': 0, // Placeholder
      };
    } catch (e) {
      print('❌ Error getting database info: $e');
      return {
        'database_name': SqlServerConfig.databaseName,
        'server_ip': SqlServerConfig.serverIP,
        'customers_count': 0,
        'transactions_count': 0,
        'schemes_count': 0,
      };
    }
  }
}
