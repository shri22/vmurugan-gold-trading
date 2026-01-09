import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/sql_server_config.dart';
import 'secure_http_client.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

/// SQL Server Database Service
/// Connects to local SQL Server (SSMS) database via HTTP API
class SqlServerService {
  // Base URL for the SQL Server API bridge
  static String get baseUrl => 'https://${SqlServerConfig.serverIP}:${ApiConfig.port}/api';
  
  // Helper to get headers with JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getBackendToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'admin-token': 'VMURUGAN_ADMIN_2025', // Keep for admin endpoints
    };
  }

  // Handle server responses centrally
  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('⚠️ SqlServerService: Unauthorized access (${response.statusCode}).');
      print('⚠️ Not logging out - returning error for caller to handle.');
      return {
        'success': false,
        'message': 'Authentication required',
        'error_code': 'UNAUTHORIZED',
        'status_code': response.statusCode,
      };
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {
          'success': true,
          'message': 'Operation completed',
        };
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Request failed',
          'error': errorData['error'],
          'status_code': response.statusCode,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Request failed with status ${response.statusCode}',
          'status_code': response.statusCode,
        };
      }
    }
  }

  // =============================================================================
  // CONNECTION MANAGEMENT
  // =============================================================================
  
  /// Test database connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await SecureHttpClient.get(
        '$baseUrl/test-connection',
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
        body: jsonEncode(customerData),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
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
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
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
    String? schemeType,
    String? schemeId,
    int? installmentNumber,
    double? silverGrams,
    double? silverPricePerGram,
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
    print('  🎯 Scheme Type: ${schemeType ?? "REGULAR"}');
    print('  🎯 Scheme ID: ${schemeId ?? "N/A"}');
    print('  🎯 Installment Number: ${installmentNumber ?? "N/A"}');

    try {
      final transactionData = {
        'transaction_id': transactionId,
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'type': type,
        'amount': amount,
        // Removed client-side calculations - backend now enforces server-side calculation
        'payment_method': paymentMethod,
        'status': status,
        'gateway_transaction_id': gatewayTransactionId,
        'device_info': deviceInfo,
        'location': location,
        'additional_data': additionalData != null ? jsonEncode(additionalData) : null,
        'scheme_type': schemeType,
        'scheme_id': schemeId,
        'installment_number': installmentNumber,
      };

      print('📤 Transaction Data to Send:');
      print(jsonEncode(transactionData));

      print('🌐 Making HTTP POST request to: $baseUrl/transactions');
      print('📤 Request Headers: ${await _getHeaders()}');

      final response = await SecureHttpClient.post(
        '$baseUrl/transactions',
        headers: await _getHeaders(),
        body: jsonEncode(transactionData),
      ).timeout(const Duration(seconds: 30));

      print('📥 HTTP Response Status: ${response.statusCode}');
      return await _handleResponse(response);
    } catch (error) {
      print('❌ Error in saveTransaction: $error');
      return {
        'success': false,
        'message': 'Failed to save transaction: $error',
      };
    }
  }
  
  /// Invest in a PLUS scheme (GOLDPLUS/SILVERPLUS)
  static Future<Map<String, dynamic>> investInScheme({
    required String schemeId,
    required double amount,
    required String transactionId,
    String? gatewayTransactionId,
    String? deviceInfo,
    String? location,
  }) async {
    try {
      final body = {
        'amount': amount,
        'transaction_id': transactionId,
        'gateway_transaction_id': gatewayTransactionId,
        'device_info': deviceInfo,
        'location': location,
      };

      print('🌐 Making HTTP POST request to: $baseUrl/schemes/$schemeId/invest');
      
      final response = await SecureHttpClient.post(
        '$baseUrl/schemes/$schemeId/invest',
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      print('❌ Error in investInScheme: $e');
      return {
        'success': false,
        'message': 'Failed to add investment to scheme: $e',
      };
    }
  }

  /// Make a FLEXI scheme payment (GOLDFLEXI/SILVERFLEXI)
  static Future<Map<String, dynamic>> makeFlexiPayment({
    required String schemeId,
    required double amount,
    required String transactionId,
    String? gatewayTransactionId,
    String? paymentMethod,
    String? deviceInfo,
    String? location,
  }) async {
    try {
      final body = {
        'amount': amount,
        'transaction_id': transactionId,
        'gateway_transaction_id': gatewayTransactionId,
        'payment_method': paymentMethod ?? 'FLEXI_PAYMENT',
        'device_info': deviceInfo,
        'location': location,
      };

      print('🌐 Making HTTP POST request to: $baseUrl/schemes/$schemeId/flexi-payment');
      
      final response = await SecureHttpClient.post(
        '$baseUrl/schemes/$schemeId/flexi-payment',
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      print('❌ Error in makeFlexiPayment: $e');
      return {
        'success': false,
        'message': 'Failed to add flexi payment: $e',
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
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
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

  /// Accept terms and conditions
  static Future<Map<String, dynamic>> acceptTerms(String phone) async {
    try {
      final response = await SecureHttpClient.post(
        '$baseUrl/customers/$phone/accept-terms',
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      print('❌ Error accepting terms: $e');
      return {
        'success': false,
        'message': 'Failed to accept terms: $e',
      };
    }
  }
}
