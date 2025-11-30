import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'custom_server_service.dart';
import 'local_api_service.dart';
import 'sql_server_api_service.dart';
import '../config/server_config.dart';
import 'secure_http_client.dart';

class ApiService {
  // CONFIGURATION: Choose your data storage method
  static const String storageMode = 'sqlserver'; // Options: 'firebase', 'server', 'local', 'sqlserver'

  // Legacy compatibility
  static bool get useFirebase => storageMode == 'firebase';

  // Current mode description
  static String get mode {
    switch (storageMode) {
      case 'firebase':
        return 'Firebase Cloud';
      case 'server':
        return 'Custom Server';
      case 'local':
        return 'Local SQLite Database';
      case 'sqlserver':
        return 'SQL Server (SSMS)';
      default:
        return 'Unknown';
    }
  }

  // Smart router: Save transaction to active service
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
    required String gatewayTransactionId,
    required String deviceInfo,
    required String location,
    Map<String, dynamic>? additionalData,
    String? schemeType,
    String? schemeId,
    int? installmentNumber,
    double? silverGrams,
    double? silverPricePerGram,
  }) async {
    print('');
    print('🔄🔄🔄 ApiService.saveTransaction CALLED 🔄🔄🔄');
    print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🎯 Storage Mode: $storageMode');
    print('📊 Transaction Data:');
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
    print('🔄 Routing to $storageMode for transaction save...');

    switch (storageMode) {
      case 'firebase':
        return await FirebaseService.saveTransaction(
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
          additionalData: additionalData,
          schemeType: schemeType,
          schemeId: schemeId,
          installmentNumber: installmentNumber,
          silverGrams: silverGrams,
          silverPricePerGram: silverPricePerGram,
        );
      case 'server':
        return await CustomServerService.saveTransaction({
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
        });
      case 'local':
        return await LocalApiService.saveTransaction({
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
        });
      case 'sqlserver':
        return await SqlServerApiService.saveTransaction(
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
          additionalData: additionalData,
          schemeType: schemeType,
          schemeId: schemeId,
          installmentNumber: installmentNumber,
          silverGrams: silverGrams,
          silverPricePerGram: silverPricePerGram,
        );
      default:
        return {
          'success': false,
          'message': 'Invalid storage mode: $storageMode',
        };
    }
  }

  // Update transaction status
  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
    required String? failureReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (failureReason != null) 'failure_reason': failureReason,
      };

      // This method is not used in current implementation
      // Will be implemented when custom server is ready
      return {'success': false, 'message': 'Update not implemented yet'};

    } catch (e) {
      print('Error updating transaction status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Smart router: Save customer information
  static Future<Map<String, dynamic>> saveCustomerInfo({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    print('ApiService: Routing to $mode for customer save');

    switch (storageMode) {
      case 'firebase':
        return await FirebaseService.saveCustomer(
          phone: phone,
          name: name,
          email: email,
          address: address,
          panCard: panCard,
          deviceId: deviceId,
        );
      case 'server':
        return await CustomServerService.saveCustomer({
          'phone': phone,
          'name': name,
          'email': email,
          'address': address,
          'pan_card': panCard,
          'device_id': deviceId,
        });
      case 'local':
        return await LocalApiService.saveCustomerInfo({
          'phone': phone,
          'name': name,
          'email': email,
          'address': address,
          'pan_card': panCard,
          'device_id': deviceId,
        });
      case 'sqlserver':
        return await SqlServerApiService.saveCustomerInfo(
          phone: phone,
          name: name,
          email: email,
          address: address,
          panCard: panCard,
          deviceId: deviceId,
        );
      default:
        return {
          'success': false,
          'message': 'Invalid storage mode: $storageMode',
        };
    }
  }

  // Smart router: Generate scheme ID
  static Future<String> generateSchemeId(String customerId) async {
    print('ApiService: Routing to $mode for scheme ID generation');

    if (useFirebase) {
      return await FirebaseService.generateUniqueSchemeId(customerId);
    } else {
      // For custom server, implement scheme ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$customerId-S${timestamp.toString().substring(timestamp.toString().length - 2)}';
    }
  }

  // Smart router: Save scheme
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
    print('ApiService: Routing to $mode for scheme save');

    if (useFirebase) {
      return await FirebaseService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerPhone,
        customerName: customerName,
        monthlyAmount: monthlyAmount,
        durationMonths: durationMonths,
        schemeType: schemeType,
        status: status,
      );
    } else {
      // For custom server, implement scheme saving
      return {
        'success': true,
        'message': 'Scheme saved to custom server',
        'scheme_id': schemeId,
      };
    }
  }

  // Smart router: Get customer by phone
  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    print('ApiService: Routing to $mode for customer lookup');

    if (useFirebase) {
      return await FirebaseService.getCustomerByPhone(phone);
    } else {
      // For SQL Server, call the /api/customers/:phone endpoint
      try {
        print('🔍 ApiService: Fetching customer from SQL Server for phone: $phone');
        final url = '${ServerConfig.baseUrl}/api/customers/$phone';

        final response = await SecureHttpClient.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ ApiService: Customer data fetched successfully');
          print('   Customer ID: ${data['user']?['customer_id']}');
          return {
            'success': true,
            'customer': data['user'],
            'message': 'Customer found',
          };
        } else {
          print('❌ ApiService: Failed to fetch customer - Status: ${response.statusCode}');
          return {
            'success': false,
            'customer': null,
            'message': 'Customer not found',
          };
        }
      } catch (e) {
        print('❌ ApiService: Error fetching customer: $e');
        return {
          'success': false,
          'customer': null,
          'message': 'Error: $e',
        };
      }
    }
  }

  // Smart router: Log analytics
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    print('ApiService: Routing to $mode for analytics');

    if (useFirebase) {
      await FirebaseService.logAnalytics(event: event, data: data);
    } else {
      await CustomServerService.logAnalytics(event: event, data: data);
    }
  }

  // Smart router: Get transactions for admin
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('ApiService: Routing to $mode for transactions');

    if (useFirebase) {
      return await FirebaseService.getTransactions(
        limit: limit,
        customerPhone: customerPhone,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      return await SqlServerApiService.getTransactions(
        limit: limit,
        customerPhone: customerPhone,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  // Smart router: Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    print('ApiService: Routing to $mode for dashboard data');

    if (useFirebase) {
      return await FirebaseService.getDashboardData(adminToken: adminToken);
    } else {
      return await CustomServerService.getDashboardData(adminToken: adminToken);
    }
  }
}
