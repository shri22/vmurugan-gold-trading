import 'local_database_service.dart';

/// Local SQLite API Service
/// This service provides the same interface as the remote API service
/// but stores data locally in SQLite database on the device
class LocalApiService {
  
  // =============================================================================
  // TRANSACTION OPERATIONS
  // =============================================================================

  /// Save transaction to local database
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
    print('LocalApiService: Saving transaction to local database');
    
    return await LocalDatabaseService.saveTransaction(
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

  /// Save customer information to local database
  static Future<Map<String, dynamic>> saveCustomerInfo({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    print('LocalApiService: Saving customer to local database');
    
    return await LocalDatabaseService.saveCustomer(
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
    print('LocalApiService: Getting customer from local database');
    
    return await LocalDatabaseService.getCustomerByPhone(phone);
  }

  /// Get all customers
  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    print('LocalApiService: Getting all customers from local database');
    
    return await LocalDatabaseService.getAllCustomers();
  }

  // =============================================================================
  // SCHEME OPERATIONS
  // =============================================================================

  /// Save scheme to local database
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
    print('LocalApiService: Saving scheme to local database');
    
    return await LocalDatabaseService.saveScheme(
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

  /// Log analytics event to local database
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    print('LocalApiService: Logging analytics to local database');
    
    await LocalDatabaseService.logAnalytics(
      event: event,
      data: data,
    );
  }

  // =============================================================================
  // DASHBOARD & ADMIN OPERATIONS
  // =============================================================================

  /// Get dashboard data from local database
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    print('LocalApiService: Getting dashboard data from local database');
    
    // Simple token validation (you can enhance this)
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    return await LocalDatabaseService.getDashboardData();
  }

  /// Get transactions with filters
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('LocalApiService: Getting transactions from local database');
    
    try {
      final transactions = await LocalDatabaseService.getTransactions(
        customerPhone: customerPhone,
        status: status,
        limit: limit,
      );
      
      // Apply date filters if provided
      List<Map<String, dynamic>> filteredTransactions = transactions;
      
      if (startDate != null || endDate != null) {
        filteredTransactions = transactions.where((transaction) {
          final timestamp = DateTime.tryParse(transaction['timestamp'] ?? '');
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

  /// Export all data from local database
  static Future<Map<String, dynamic>> exportData({
    required String adminToken,
  }) async {
    print('LocalApiService: Exporting data from local database');
    
    // Simple token validation
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    return await LocalDatabaseService.exportAllData();
  }

  /// Get database statistics and info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    print('LocalApiService: Getting database info');
    
    try {
      final info = await LocalDatabaseService.getDatabaseInfo();
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

  /// Clear all local data (for testing/reset)
  static Future<Map<String, dynamic>> clearAllData({
    required String adminToken,
  }) async {
    print('LocalApiService: Clearing all local data');
    
    // Simple token validation
    if (adminToken != 'VMURUGAN_ADMIN_2025') {
      return {
        'success': false,
        'message': 'Invalid admin token',
      };
    }
    
    try {
      await LocalDatabaseService.clearAllData();
      return {
        'success': true,
        'message': 'All local data cleared successfully',
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

  /// Test local database connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final info = await LocalDatabaseService.getDatabaseInfo();
      return {
        'success': true,
        'message': 'Local database connection successful',
        'database_info': info,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Local database connection failed: $e',
      };
    }
  }

  /// Get service status
  static Map<String, dynamic> getStatus() {
    return {
      'service': 'Local SQLite Database',
      'mode': 'Local Storage',
      'database_name': 'vmurugan_gold_trading.db',
      'business_id': 'VMURUGAN_001',
      'features': [
        'Customer Management',
        'Transaction Recording',
        'Scheme Management',
        'Analytics Logging',
        'Data Export',
        'Offline Support',
      ],
      'advantages': [
        'Works offline',
        'Fast performance',
        'No internet required',
        'Data privacy',
        'No server costs',
      ],
    };
  }
}
