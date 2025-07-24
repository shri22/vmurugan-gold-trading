import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

class FirebaseService {
  // Use configuration from FirebaseConfig
  static String get projectId => FirebaseConfig.projectId;
  static String get apiKey => FirebaseConfig.apiKey;
  static String get baseUrl => FirebaseConfig.firestoreUrl;
  static Map<String, String> get headers => FirebaseConfig.headers;

  // Check if Firebase is properly configured
  static bool get isConfigured => FirebaseConfig.isConfigured;

  // Validate configuration before making requests
  static Map<String, dynamic> _validateConfig() {
    if (!isConfigured) {
      final status = FirebaseConfig.status;
      return {
        'success': false,
        'message': status['message'],
        'instructions': status['instructions'],
      };
    }
    return {'success': true};
  }

  // Get configuration status
  static Map<String, dynamic> getConfigurationStatus() {
    return FirebaseConfig.status;
  }

  // Save customer to Firebase
  static Future<Map<String, dynamic>> saveCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    print('🔥 FirebaseService: Starting customer save...');
    print('📱 Phone: $phone');
    print('👤 Name: $name');
    print('📧 Email: $email');

    // Validate Firebase configuration
    final configCheck = _validateConfig();
    if (!configCheck['success']) {
      print('❌ Firebase config validation failed: ${configCheck['message']}');
      return configCheck;
    }
    print('✅ Firebase config validation passed');

    try {
      final customerData = {
        'fields': {
          'phone': {'stringValue': phone},
          'name': {'stringValue': name},
          'email': {'stringValue': email},
          'address': {'stringValue': address},
          'pan_card': {'stringValue': panCard},
          'device_id': {'stringValue': deviceId},
          'registration_date': {'stringValue': DateTime.now().toUtc().toIso8601String()},
          'business_id': {'stringValue': FirebaseConfig.businessId},
          'data_type': {'stringValue': 'real_user'}, // Mark as real user data
          'total_invested': {'doubleValue': 0.0},
          'total_gold': {'doubleValue': 0.0},
          'transaction_count': {'integerValue': 0},
        }
      };

      final url = '$baseUrl/customers?documentId=$phone&key=$apiKey';
      print('🌐 Firebase URL: $url');
      print('📤 Sending customer data to Firebase...');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(customerData),
      );

      print('📥 Firebase Response: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Firebase Error Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Customer saved successfully to Firebase');
        return {
          'success': true,
          'message': 'Customer saved successfully',
        };
      } else {
        print('Failed to save customer: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save customer: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving customer to Firebase: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Save transaction to Firebase
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
    // Validate Firebase configuration
    final configCheck = _validateConfig();
    if (!configCheck['success']) {
      return configCheck;
    }

    try {
      final transactionData = {
        'fields': {
          'transaction_id': {'stringValue': transactionId},
          'customer_phone': {'stringValue': customerPhone},
          'customer_name': {'stringValue': customerName},
          'type': {'stringValue': type},
          'amount': {'doubleValue': amount},
          'gold_grams': {'doubleValue': goldGrams},
          'gold_price_per_gram': {'doubleValue': goldPricePerGram},
          'payment_method': {'stringValue': paymentMethod},
          'status': {'stringValue': status},
          'gateway_transaction_id': {'stringValue': gatewayTransactionId},
          'device_info': {'stringValue': deviceInfo},
          'location': {'stringValue': location},
          'timestamp': {'stringValue': DateTime.now().toUtc().toIso8601String()},
          'business_id': {'stringValue': FirebaseConfig.businessId},
        }
      };

      print('Saving transaction to Firebase: $transactionId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions?documentId=$transactionId'),
        headers: headers,
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Transaction saved successfully to Firebase');
        
        // Update customer stats
        await _updateCustomerStats(customerPhone, amount, goldGrams);
        
        return {
          'success': true,
          'message': 'Transaction saved successfully',
        };
      } else {
        print('Failed to save transaction: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save transaction: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving transaction to Firebase: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update customer statistics
  static Future<void> _updateCustomerStats(String phone, double amount, double goldGrams) async {
    try {
      // Get current customer data
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$phone'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fields = data['fields'] ?? {};
        
        final currentInvested = double.tryParse(fields['total_invested']?['doubleValue']?.toString() ?? '0') ?? 0.0;
        final currentGold = double.tryParse(fields['total_gold']?['doubleValue']?.toString() ?? '0') ?? 0.0;
        final currentCount = int.tryParse(fields['transaction_count']?['integerValue']?.toString() ?? '0') ?? 0;

        // Update with new values
        final updateData = {
          'fields': {
            'total_invested': {'doubleValue': currentInvested + amount},
            'total_gold': {'doubleValue': currentGold + goldGrams},
            'transaction_count': {'integerValue': currentCount + 1},
            'last_transaction': {'timestampValue': DateTime.now().toIso8601String()},
          }
        };

        await http.patch(
          Uri.parse('$baseUrl/customers/$phone?updateMask.fieldPaths=total_invested&updateMask.fieldPaths=total_gold&updateMask.fieldPaths=transaction_count&updateMask.fieldPaths=last_transaction'),
          headers: headers,
          body: jsonEncode(updateData),
        );
      }
    } catch (e) {
      print('Error updating customer stats: $e');
    }
  }

  // Save analytics event
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      final analyticsData = {
        'fields': {
          'event': {'stringValue': event},
          'data': {'stringValue': jsonEncode(data)},
          'timestamp': {'timestampValue': DateTime.now().toIso8601String()},
          'business_id': {'stringValue': FirebaseConfig.businessId},
        }
      };

      final docId = '${event}_${DateTime.now().millisecondsSinceEpoch}';
      
      await http.post(
        Uri.parse('$baseUrl/analytics?documentId=$docId'),
        headers: headers,
        body: jsonEncode(analyticsData),
      );
    } catch (e) {
      print('Error logging analytics to Firebase: $e');
    }
  }

  // Get dashboard data (for admin)
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    try {
      // Simple admin token check (in production, use Firebase Auth)
      if (adminToken != FirebaseConfig.adminToken) {
        return {
          'success': false,
          'message': 'Unauthorized access',
        };
      }

      // Get customers
      final customersResponse = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: headers,
      );

      // Get transactions
      final transactionsResponse = await http.get(
        Uri.parse('$baseUrl/transactions?orderBy=timestamp desc&pageSize=50'),
        headers: headers,
      );

      if (customersResponse.statusCode == 200 && transactionsResponse.statusCode == 200) {
        final customers = _parseFirebaseDocuments(jsonDecode(customersResponse.body));
        final transactions = _parseFirebaseDocuments(jsonDecode(transactionsResponse.body));

        // Calculate stats
        final stats = _calculateStats(customers, transactions);

        return {
          'success': true,
          'data': {
            'stats': stats,
            'customers': customers.take(20).toList(),
            'recent_transactions': transactions.take(20).toList(),
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch dashboard data',
        };
      }
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Parse Firebase documents
  static List<Map<String, dynamic>> _parseFirebaseDocuments(Map<String, dynamic> response) {
    final documents = response['documents'] as List<dynamic>? ?? [];
    return documents.map((doc) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      final parsed = <String, dynamic>{};
      
      fields.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          if (value.containsKey('stringValue')) {
            parsed[key] = value['stringValue'];
          } else if (value.containsKey('doubleValue')) {
            parsed[key] = value['doubleValue'];
          } else if (value.containsKey('integerValue')) {
            parsed[key] = int.tryParse(value['integerValue'].toString()) ?? 0;
          } else if (value.containsKey('timestampValue')) {
            parsed[key] = value['timestampValue'];
          }
        }
      });
      
      return parsed;
    }).toList();
  }

  // Calculate business statistics
  static Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> customers, List<Map<String, dynamic>> transactions) {
    double totalRevenue = 0;
    double totalGoldSold = 0;
    int successfulTransactions = 0;

    for (final transaction in transactions) {
      if (transaction['status'] == 'SUCCESS') {
        totalRevenue += (transaction['amount'] as num?)?.toDouble() ?? 0;
        totalGoldSold += (transaction['gold_grams'] as num?)?.toDouble() ?? 0;
        successfulTransactions++;
      }
    }

    return {
      'total_revenue': totalRevenue,
      'total_customers': customers.length,
      'total_gold_sold': totalGoldSold,
      'total_transactions': successfulTransactions,
    };
  }
}
