import 'sql_server_service.dart';

/// SQL Server API Service
/// This service provides the same interface as other API services
/// but stores data in local SQL Server (SSMS) database
class SqlServerApiService {
  
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  /// Initialize SQL Server database (create tables if needed)
  static Future<Map<String, dynamic>> initialize() async {
    print('SqlServerApiService: Initializing SQL Server database');
    return await SqlServerService.initializeDatabase();
  }
  
  /// Test SQL Server connection
  static Future<Map<String, dynamic>> testConnection() async {
    print('SqlServerApiService: Testing SQL Server connection');
    return await SqlServerService.testConnection();
  }
  
  // =============================================================================
  // TRANSACTION OPERATIONS
  // =============================================================================

  /// Save transaction to SQL Server database
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
  }) async {
    print('SqlServerApiService: Saving transaction to SQL Server database');
    
    return await SqlServerService.saveTransaction(
      transactionId: transactionId,
      customerPhone: customerPhone,
      customerName: customerName,
      type: type,
      amount: amount,
      goldGrams: goldGrams,
      goldPricePerGram: goldPricePerGram,
      paymentMethod: paymentMethod,
      status: status,
      gatewayTransactionId: gatewayTransactionId,
      deviceInfo: deviceInfo,
      location: location,
    );
  }

  // =============================================================================
  // CUSTOMER OPERATIONS
  // =============================================================================

  /// Save customer information to SQL Server database
  static Future<Map<String, dynamic>> saveCustomerInfo({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    print('SqlServerApiService: Saving customer to SQL Server database');
    
    return await SqlServerService.saveCustomer(
      phone: phone,
      name: name,
      email: email,
      address: address,
      panCard: panCard,
      deviceId: deviceId,
    );
  }

  /// Get customer by phone number
  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    print('SqlServerApiService: Getting customer from SQL Server database');
    
    return await SqlServerService.getCustomerByPhone(phone);
  }

  /// Get all customers
  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    print('SqlServerApiService: Getting all customers from SQL Server database');
    
    return await SqlServerService.getAllCustomers();
  }

  // =============================================================================
  // SCHEME OPERATIONS
  // =============================================================================

  /// Save scheme to SQL Server database
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
    print('SqlServerApiService: Saving scheme to SQL Server database');
    
    return await SqlServerService.saveScheme(
      schemeId: schemeId,
      customerId: customerId,
      customerPhone: customerPhone,
      customerName: customerName,
      monthlyAmount: monthlyAmount,
      durationMonths: durationMonths,
      schemeType: schemeType,
      status: status,
    );
  }

  // =============================================================================
  // ANALYTICS OPERATIONS
  // =============================================================================

  /// Log analytics event to SQL Server database
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    print('SqlServerApiService: Logging analytics to SQL Server database');
    
    await SqlServerService.logAnalytics(
      event: event,
      data: data,
    );
  }

  // =============================================================================
  // DASHBOARD & ADMIN OPERATIONS
  // =============================================================================

  /// Get dashboard data from SQL Server database
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    print('SqlServerApiService: Getting dashboard data from SQL Server database');
    
    // Simple token validation (you can enhance this)
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    return await SqlServerService.getDashboardData();
  }

  /// Get transactions with filters
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('SqlServerApiService: Getting transactions from SQL Server database');
    
    try {
      final transactions = await SqlServerService.getTransactions(
        customerPhone: customerPhone,
        status: status,
        limit: limit,
      );
      
      // Apply date filters if provided (SQL Server filtering can be enhanced)
      List<Map<String, dynamic>> filteredTransactions = transactions;
      
      if (startDate != null || endDate != null) {
        filteredTransactions = transactions.where((transaction) {
          final timestamp = DateTime.tryParse(transaction['timestamp']?.toString() ?? '');
          if (timestamp == null) return false;
          
          if (startDate != null && timestamp.isBefore(startDate)) return false;
          if (endDate != null && timestamp.isAfter(endDate)) return false;
          
          return true;
        }).toList();
      }
      
      return {
        'success': true,
        'transactions': filteredTransactions,
        'count': filteredTransactions.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get transactions: $e',
        'transactions': <Map<String, dynamic>>[],
      };
    }
  }

  // =============================================================================
  // DATA MANAGEMENT
  // =============================================================================

  /// Export all data from SQL Server database
  static Future<Map<String, dynamic>> exportData({
    required String adminToken,
  }) async {
    print('SqlServerApiService: Exporting data from SQL Server database');
    
    // Simple token validation
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    return await SqlServerService.exportAllData();
  }

  /// Get database statistics and info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    print('SqlServerApiService: Getting SQL Server database info');
    
    try {
      final info = await SqlServerService.getDatabaseInfo();
      return {
        'success': true,
        'database_info': info,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get database info: $e',
      };
    }
  }

  /// Clear all data (for testing/reset)
  static Future<Map<String, dynamic>> clearAllData({
    required String adminToken,
  }) async {
    print('SqlServerApiService: Clearing all SQL Server data');
    
    // Simple token validation
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    try {
      // Note: Implement clear data functionality in SqlServerService if needed
      return {
        'success': false,
        'message': 'Clear data functionality not implemented for SQL Server',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to clear data: $e',
      };
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Close database connection
  static Future<void> closeConnection() async {
    await SqlServerService.closeConnection();
  }

  /// Get service status
  static Map<String, dynamic> getStatus() {
    return {
      'service': 'SQL Server Database (SSMS)',
      'mode': 'Local SQL Server',
      'database_name': 'VMuruganGoldTrading',
      'business_id': 'VMURUGAN_001',
      'features': [
        'Customer Management',
        'Transaction Recording',
        'Scheme Management',
        'Analytics Logging',
        'Data Export',
        'Enterprise Database',
        'ACID Compliance',
        'Advanced Querying',
      ],
      'advantages': [
        'Enterprise-grade database',
        'High performance',
        'Advanced SQL features',
        'Backup and recovery',
        'Scalable',
        'Professional tools (SSMS)',
        'Reporting capabilities',
      ],
    };
  }

  // Get transactions with filters
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (customerPhone != null) queryParams['customer_phone'] = customerPhone;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/transactions').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transactions': data['transactions'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch transactions',
          'transactions': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'transactions': [],
      };
    }
  }
}
