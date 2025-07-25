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

  // Generate unique customer ID
  static Future<String> _generateUniqueCustomerId() async {
    try {
      // Get the current counter from Firebase
      final counterUrl = '$baseUrl/counters/customer_counter?key=$apiKey';

      final response = await http.get(Uri.parse(counterUrl), headers: headers);

      int currentCounter = 1; // Default starting number

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['fields'] != null && data['fields']['count'] != null) {
          currentCounter = int.parse(data['fields']['count']['integerValue'].toString()) + 1;
        }
      }

      // Update the counter in Firebase
      final updateCounterData = {
        'fields': {
          'count': {'integerValue': currentCounter},
          'last_updated': {'stringValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      await http.patch(
        Uri.parse(counterUrl),
        headers: headers,
        body: jsonEncode(updateCounterData),
      );

      // Generate customer ID with VM prefix and 6-digit number
      final customerId = 'VM${currentCounter.toString().padLeft(6, '0')}';
      print('🆔 Generated Customer ID: $customerId');

      return customerId;

    } catch (e) {
      print('❌ Error generating customer ID: $e');
      // Fallback to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'VM${timestamp.toString().substring(timestamp.toString().length - 6)}';
    }
  }

  // Generate unique scheme ID for a customer
  static Future<String> generateUniqueSchemeId(String customerId) async {
    try {
      // Get the current scheme counter for this customer from Firebase
      final counterUrl = '$baseUrl/counters/scheme_counter_$customerId?key=$apiKey';

      final response = await http.get(Uri.parse(counterUrl), headers: headers);

      int currentCounter = 1; // Default starting number for first scheme

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['fields'] != null && data['fields']['count'] != null) {
          currentCounter = int.parse(data['fields']['count']['integerValue'].toString()) + 1;
        }
      }

      // Update the scheme counter in Firebase
      final updateCounterData = {
        'fields': {
          'count': {'integerValue': currentCounter},
          'customer_id': {'stringValue': customerId},
          'last_updated': {'stringValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      await http.patch(
        Uri.parse(counterUrl),
        headers: headers,
        body: jsonEncode(updateCounterData),
      );

      // Generate scheme ID: CustomerID-S01, CustomerID-S02, etc.
      final schemeId = '$customerId-S${currentCounter.toString().padLeft(2, '0')}';
      print('🎯 Generated Scheme ID: $schemeId for Customer: $customerId');

      return schemeId;

    } catch (e) {
      print('❌ Error generating scheme ID: $e');
      // Fallback to timestamp-based scheme ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$customerId-S${timestamp.toString().substring(timestamp.toString().length - 2)}';
    }
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
      // Generate unique customer ID
      final customerId = await _generateUniqueCustomerId();

      final customerData = {
        'fields': {
          'customer_id': {'stringValue': customerId}, // Add unique customer ID
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
          'customer_id': customerId, // Return the generated customer ID
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

  // Save scheme to Firebase
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
    print('🎯 FirebaseService: Starting scheme save...');
    print('🆔 Scheme ID: $schemeId');
    print('👤 Customer ID: $customerId');
    print('💰 Monthly Amount: ₹$monthlyAmount');
    print('📅 Duration: $durationMonths months');

    // Validate Firebase configuration
    final configCheck = _validateConfig();
    if (!configCheck['success']) {
      print('❌ Firebase config validation failed: ${configCheck['message']}');
      return configCheck;
    }
    print('✅ Firebase config validation passed');

    try {
      final schemeData = {
        'fields': {
          'scheme_id': {'stringValue': schemeId},
          'customer_id': {'stringValue': customerId},
          'customer_phone': {'stringValue': customerPhone},
          'customer_name': {'stringValue': customerName},
          'monthly_amount': {'doubleValue': monthlyAmount},
          'duration_months': {'integerValue': durationMonths},
          'scheme_type': {'stringValue': schemeType},
          'status': {'stringValue': status}, // ACTIVE, COMPLETED, PAUSED, CANCELLED
          'start_date': {'stringValue': DateTime.now().toUtc().toIso8601String()},
          'end_date': {'stringValue': DateTime.now().add(Duration(days: durationMonths * 30)).toUtc().toIso8601String()},
          'total_target_amount': {'doubleValue': monthlyAmount * durationMonths},
          'paid_amount': {'doubleValue': 0.0},
          'paid_months': {'integerValue': 0},
          'remaining_months': {'integerValue': durationMonths},
          'gold_accumulated': {'doubleValue': 0.0},
          'business_id': {'stringValue': FirebaseConfig.businessId},
          'data_type': {'stringValue': 'real_scheme'}, // Mark as real scheme data
          'created_date': {'stringValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      final url = '$baseUrl/schemes?documentId=$schemeId&key=$apiKey';
      print('🌐 Firebase URL: $url');
      print('📤 Sending scheme data to Firebase...');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(schemeData),
      );

      print('📥 Firebase Response: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Firebase Error Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Scheme saved successfully to Firebase');
        return {
          'success': true,
          'message': 'Scheme saved successfully',
          'scheme_id': schemeId,
        };
      } else {
        print('Failed to save scheme: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save scheme: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving scheme to Firebase: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get customer by phone number
  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    print('🔍 Searching for customer with phone: $phone');

    try {
      // Get all customers and search for the phone number
      final customersUrl = '$baseUrl/customers?key=$apiKey';
      final response = await http.get(Uri.parse(customersUrl), headers: headers);

      print('📥 Firebase response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Firebase response data: $data');

        if (data['documents'] != null) {
          // Search through all customers for matching phone number
          for (final doc in data['documents']) {
            final fields = doc['fields'];
            final customerPhone = fields['phone']?['stringValue'];

            print('🔍 Checking customer phone: $customerPhone vs $phone');

            if (customerPhone == phone) {
              // Found matching customer
              final customer = {
                'customer_id': fields['customer_id']?['stringValue'],
                'phone': fields['phone']?['stringValue'],
                'name': fields['name']?['stringValue'],
                'email': fields['email']?['stringValue'],
                'address': fields['address']?['stringValue'],
                'pan_card': fields['pan_card']?['stringValue'],
                'registration_date': fields['registration_date']?['stringValue'],
                'total_invested': fields['total_invested']?['doubleValue'] ?? 0.0,
                'total_gold': fields['total_gold']?['doubleValue'] ?? 0.0,
                'transaction_count': fields['transaction_count']?['integerValue'] ?? 0,
              };

              print('✅ Customer found: ${customer['customer_id']} - ${customer['name']}');

              return {
                'success': true,
                'customer': customer,
                'message': 'Customer found',
              };
            }
          }
        }
      }

      print('⚠️ Customer not found for phone: $phone');
      return {
        'success': false,
        'customer': null,
        'message': 'Customer not found',
      };
    } catch (e) {
      print('❌ Error getting customer: $e');
      return {
        'success': false,
        'customer': null,
        'message': 'Error: $e',
      };
    }
  }

  // Get customer ID by phone number (helper method)
  static Future<String?> _getCustomerIdByPhone(String phone) async {
    try {
      final result = await getCustomerByPhone(phone);
      if (result['success'] && result['customer'] != null) {
        return result['customer']['customer_id'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting customer ID: $e');
      return null;
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
    String? schemeId, // Optional scheme ID for scheme-based transactions
  }) async {
    // Validate Firebase configuration
    final configCheck = _validateConfig();
    if (!configCheck['success']) {
      return configCheck;
    }

    try {
      // Get customer ID for this transaction
      final customerId = await _getCustomerIdByPhone(customerPhone);

      final transactionData = {
        'fields': {
          'transaction_id': {'stringValue': transactionId},
          'customer_id': {'stringValue': customerId ?? 'UNKNOWN'}, // Add customer ID
          'scheme_id': {'stringValue': schemeId ?? 'DIRECT_PURCHASE'}, // Add scheme ID
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

  // Save notification to Firebase
  static Future<Map<String, dynamic>> saveNotification({
    required String notificationId,
    required String userId,
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
    required String priority,
  }) async {
    try {
      final notificationData = {
        'fields': {
          'notificationId': {'stringValue': notificationId},
          'userId': {'stringValue': userId},
          'type': {'stringValue': type},
          'title': {'stringValue': title},
          'message': {'stringValue': message},
          'isRead': {'booleanValue': false},
          'createdAt': {'timestampValue': DateTime.now().toIso8601String()},
          'data': {'stringValue': jsonEncode(data)},
          'priority': {'stringValue': priority},
          'business_id': {'stringValue': FirebaseConfig.businessId},
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/notifications?documentId=$notificationId'),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Notification saved successfully to Firebase');
        return {
          'success': true,
          'message': 'Notification saved successfully',
        };
      } else {
        print('Failed to save notification: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to save notification: ${response.body}',
        };
      }
    } catch (e) {
      print('Error saving notification to Firebase: $e');
      return {
        'success': false,
        'message': 'Error saving notification: $e',
      };
    }
  }

  // Get transactions from Firebase
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Build query URL
      String queryUrl = '$baseUrl/transactions';

      // Add query parameters for filtering
      List<String> queryParams = [];

      if (limit > 0) {
        queryParams.add('pageSize=$limit');
      }

      if (queryParams.isNotEmpty) {
        queryUrl += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(queryUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        List<Map<String, dynamic>> transactions = [];

        for (final doc in documents) {
          final fields = doc['fields'] as Map<String, dynamic>;
          final transaction = {
            'transaction_id': fields['transaction_id']?['stringValue'] ?? '',
            'customer_phone': fields['customer_phone']?['stringValue'] ?? '',
            'customer_name': fields['customer_name']?['stringValue'] ?? '',
            'type': fields['type']?['stringValue'] ?? '',
            'amount': fields['amount']?['doubleValue'] ?? 0.0,
            'gold_grams': fields['gold_grams']?['doubleValue'] ?? 0.0,
            'gold_price_per_gram': fields['gold_price_per_gram']?['doubleValue'] ?? 0.0,
            'payment_method': fields['payment_method']?['stringValue'] ?? '',
            'status': fields['status']?['stringValue'] ?? '',
            'gateway_transaction_id': fields['gateway_transaction_id']?['stringValue'] ?? '',
            'device_info': fields['device_info']?['stringValue'] ?? '',
            'location': fields['location']?['stringValue'] ?? '',
            'timestamp': fields['timestamp']?['stringValue'] ?? '',
            'business_id': fields['business_id']?['stringValue'] ?? '',
          };

          // Apply client-side filtering if needed
          bool includeTransaction = true;

          if (customerPhone != null && !transaction['customer_phone'].toString().contains(customerPhone)) {
            includeTransaction = false;
          }

          if (status != null && transaction['status'] != status) {
            includeTransaction = false;
          }

          if (startDate != null || endDate != null) {
            try {
              final transactionDate = DateTime.parse(transaction['timestamp']);
              if (startDate != null && transactionDate.isBefore(startDate)) {
                includeTransaction = false;
              }
              if (endDate != null && transactionDate.isAfter(endDate)) {
                includeTransaction = false;
              }
            } catch (e) {
              // Skip if timestamp parsing fails
              includeTransaction = false;
            }
          }

          if (includeTransaction) {
            transactions.add(transaction);
          }
        }

        // Sort by timestamp (newest first)
        transactions.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['timestamp']);
            final dateB = DateTime.parse(b['timestamp']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        return {
          'success': true,
          'transactions': transactions,
          'total': transactions.length,
        };
      } else {
        print('Failed to get transactions: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to get transactions: ${response.body}',
          'transactions': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
      print('Error getting transactions from Firebase: $e');
      return {
        'success': false,
        'message': 'Error getting transactions: $e',
        'transactions': <Map<String, dynamic>>[],
      };
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
