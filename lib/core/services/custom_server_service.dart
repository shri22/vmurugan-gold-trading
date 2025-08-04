// CUSTOM SERVER IMPLEMENTATION
// Local MySQL server implementation for testing

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';

class CustomServerService {
  // Use centralized server configuration
  static String get baseUrl => ServerConfig.baseUrl;
  static String get adminToken => ServerConfig.adminToken;
  static Map<String, String> get headers => ServerConfig.headers;

  // Save customer to your server
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
        'registration_date': DateTime.now().toIso8601String(),
        'business_id': 'VMURUGAN_001',
        'total_invested': 0.0,
        'total_gold': 0.0,
        'transaction_count': 0,
      };

      print('Saving customer to custom server: $phone');
      
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: headers,
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Customer saved successfully to custom server');
        return {
          'success': true,
          'message': 'Customer saved successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        print('Failed to save customer: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save customer: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving customer to custom server: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Save transaction to your server
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
  }) async {
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
        'timestamp': DateTime.now().toIso8601String(),
        'business_id': 'DIGI_GOLD_001',
      };

      print('Saving transaction to custom server: $transactionId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Transaction saved successfully to custom server');
        return {
          'success': true,
          'message': 'Transaction saved successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        print('Failed to save transaction: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save transaction: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving transaction to custom server: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update transaction status
  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? failureReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (failureReason != null) 'failure_reason': failureReason,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$transactionId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Transaction status updated',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update transaction status',
        };
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Save analytics event
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      final analyticsData = {
        'event': event,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'business_id': 'DIGI_GOLD_001',
      };

      await http.post(
        Uri.parse('$baseUrl/analytics'),
        headers: headers,
        body: jsonEncode(analyticsData),
      );
    } catch (e) {
      print('Error logging analytics to custom server: $e');
    }
  }

  // Get dashboard data (for admin)
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {
          ...headers,
          'Admin-Token': adminToken,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Unauthorized access or server error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get customer data
  static Future<Map<String, dynamic>> getCustomer(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$phone'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Customer not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get customer transactions
  static Future<Map<String, dynamic>> getCustomerTransactions(String phone, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$phone/transactions?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch transactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Export data (for migration or backup)
  static Future<Map<String, dynamic>> exportAllData({
    required String adminToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/export'),
        headers: {
          ...headers,
          'Admin-Token': adminToken,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Export failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}

