import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CustomerService {
  static const String _customerPhoneKey = 'customer_phone';
  static const String _customerNameKey = 'customer_name';
  static const String _customerEmailKey = 'customer_email';
  static const String _customerRegisteredKey = 'customer_registered';

  // Get device information for tracking (simplified for now)
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    // Simplified device info - will be enhanced when device_info_plus is re-enabled
    Map<String, dynamic> deviceData = {
      'platform': Platform.operatingSystem,
      'device_id': 'temp_device_${DateTime.now().millisecondsSinceEpoch}',
      'model': 'Unknown',
      'brand': 'Unknown',
      'version': 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Device info collected: $deviceData');
    return deviceData;
  }

  // Get location for transaction tracking (simplified for now)
  static Future<Map<String, dynamic>?> getLocation() async {
    // Simplified location - will be enhanced when geolocator is re-enabled
    try {
      return {
        'latitude': 0.0,
        'longitude': 0.0,
        'accuracy': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'note': 'Location tracking temporarily disabled',
      };
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Check if customer is registered
  static Future<bool> isCustomerRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customerRegisteredKey) ?? false;
  }

  // Save login session
  static Future<void> saveLoginSession(String phone) async {
    print('💾 Saving login session for phone: $phone');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get customer info from server
      print('🔍 Fetching customer data from Firebase...');
      final result = await ApiService.getCustomerByPhone(phone);

      print('📊 Customer fetch result: $result');

      if (result['success'] && result['customer'] != null) {
        final customer = result['customer'];

        print('👤 Customer data found:');
        print('   Customer ID: ${customer['customer_id']}');
        print('   Name: ${customer['name']}');
        print('   Email: ${customer['email']}');
        print('   Phone: ${customer['phone']}');
        print('   Address: ${customer['address']}');
        print('   PAN Card: ${customer['pan_card']}');

        // Save customer info locally (including address and PAN)
        await prefs.setString(_customerPhoneKey, customer['phone'] ?? '');
        await prefs.setString(_customerNameKey, customer['name'] ?? '');
        await prefs.setString(_customerEmailKey, customer['email'] ?? '');
        await prefs.setString('customer_id', customer['customer_id'] ?? '');
        await prefs.setString('customer_address', customer['address'] ?? '');
        await prefs.setString('customer_pan_card', customer['pan_card'] ?? '');
        await prefs.setString('customer_registration_date', customer['registration_date'] ?? '');
        await prefs.setBool(_customerRegisteredKey, true);

        print('✅ Login session saved for customer: ${customer['customer_id']}');
        print('💾 Local storage updated with correct customer data');
      } else {
        print('❌ Failed to fetch customer data: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving login session: $e');
    }
  }

  // Get stored customer info
  static Future<Map<String, String?>> getCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final customerInfo = {
      'phone': prefs.getString(_customerPhoneKey),
      'name': prefs.getString(_customerNameKey),
      'email': prefs.getString(_customerEmailKey),
      'customer_id': prefs.getString('customer_id'),
      'address': prefs.getString('customer_address'),
      'pan_card': prefs.getString('customer_pan_card'),
      'registration_date': prefs.getString('customer_registration_date'),
    };

    print('📱 Retrieved customer info from local storage:');
    print('   Phone: ${customerInfo['phone']}');
    print('   Name: ${customerInfo['name']}');
    print('   Email: ${customerInfo['email']}');
    print('   Customer ID: ${customerInfo['customer_id']}');
    print('   Address: ${customerInfo['address']}');
    print('   PAN Card: ${customerInfo['pan_card']}');
    print('   Registration Date: ${customerInfo['registration_date']}');

    return customerInfo;
  }

  // Save customer info locally and to server
  static Future<Map<String, dynamic>> registerCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceInfo = await getDeviceInfo();

      // Save locally
      await prefs.setString(_customerPhoneKey, phone);
      await prefs.setString(_customerNameKey, name);
      await prefs.setString(_customerEmailKey, email);
      await prefs.setBool(_customerRegisteredKey, true);

      // Save to server
      print('📞 CustomerService: Calling ApiService to save customer...');
      final result = await ApiService.saveCustomerInfo(
        phone: phone,
        name: name,
        email: email,
        address: address,
        panCard: panCard,
        deviceId: deviceInfo['device_id'] ?? 'unknown',
      );
      print('📞 CustomerService: ApiService result - ${result['success']} - ${result['message']}');

      if (result['success']) {
        // Save customer ID locally if provided
        if (result['customer_id'] != null) {
          await prefs.setString('customer_id', result['customer_id']);
        }

        print('Customer registered successfully with ID: ${result['customer_id']}');
        return {
          'success': true,
          'customer_id': result['customer_id'],
          'message': 'Registration successful',
        };
      } else {
        print('Failed to register customer on server: ${result['message']}');
        // Still return success as local storage succeeded
        return {
          'success': true,
          'customer_id': null,
          'message': 'Registration completed locally',
        };
      }
    } catch (e) {
      print('Error registering customer: $e');
      return {
        'success': false,
        'customer_id': null,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Save transaction with customer details
  static Future<Map<String, dynamic>> saveTransactionWithCustomerData({
    required String transactionId,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required String status,
    required String gatewayTransactionId,
    Map<String, dynamic>? additionalData,
    String? schemeType,
    String? schemeId,
    double? silverGrams,
    double? silverPricePerGram,
  }) async {
    print('');
    print('🔄🔄🔄 CustomerService.saveTransactionWithCustomerData CALLED 🔄🔄🔄');
    print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    print('📊 Input Parameters:');
    print('  🆔 Transaction ID: "$transactionId"');
    print('  📊 Status: "$status"');
    print('  💰 Amount: ₹$amount');
    print('  🥇 Gold Grams: $goldGrams');
    print('  🥈 Silver Grams: ${silverGrams ?? 0.0}');
    print('  💳 Payment Method: "$paymentMethod"');
    print('  🏦 Gateway Transaction ID: "$gatewayTransactionId"');
    print('  📋 Additional Data Present: ${additionalData != null}');
    print('  🎯 Scheme Type: ${schemeType ?? "N/A"}');
    print('  🎯 Scheme ID: ${schemeId ?? "N/A"}');

    try {
      print('🔄 Getting customer info...');
      final customerInfo = await getCustomerInfo();
      print('👤 Customer Info: $customerInfo');

      // ENHANCED DEBUGGING: Check SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      print('🔍 DEBUGGING SharedPreferences:');
      print('  📞 customer_phone: ${prefs.getString('customer_phone')}');
      print('  👤 customer_name: ${prefs.getString('customer_name')}');
      print('  📧 customer_email: ${prefs.getString('customer_email')}');
      print('  🆔 customer_id: ${prefs.getString('customer_id')}');
      print('  ✅ customer_registered: ${prefs.getBool('customer_registered')}');

      print('🔄 Getting device info...');
      final deviceInfo = await getDeviceInfo();
      print('📱 Device Info: $deviceInfo');

      print('🔄 Getting location...');
      final location = await getLocation();
      print('📍 Location: $location');

      // Ensure customer has phone number (try multiple sources)
      if (customerInfo['phone'] == null || customerInfo['phone']!.isEmpty) {
        print('⚠️ Customer phone not in registration data, using login phone...');
        print('🔍 Checking all SharedPreferences keys:');
        print('   user_phone: ${prefs.getString('user_phone')}');
        print('   customer_phone: ${prefs.getString('customer_phone')}');
        print('   is_logged_in: ${prefs.getBool('is_logged_in')}');
        print('   All keys: ${prefs.getKeys()}');
        
        final userPhone = prefs.getString('user_phone');
        if (userPhone != null && userPhone.isNotEmpty) {
          customerInfo['phone'] = userPhone;
          if (customerInfo['name'] == null || customerInfo['name']!.isEmpty) {
            customerInfo['name'] = 'Customer $userPhone';
          }
          print('✅ Using phone from login state: $userPhone');
        } else {
          print('❌❌❌ CRITICAL: No phone number found anywhere! ❌❌❌');
          print('❌ Cannot save transaction without customer phone');
          print('❌ User must be logged in to make payments');
          
          final allKeys = prefs.getKeys().join(', ');
          return {
            'success': false, 
            'message': 'User not logged in. Keys in storage: $allKeys'
          };
        }
      }

      // Additional validation
      if (customerInfo['name'] == null || customerInfo['name']!.isEmpty) {
        print('⚠️ WARNING: Customer name is null or empty, using fallback');
        customerInfo['name'] = 'VMurugan Customer';
      }

      // CRITICAL: Check if we have a valid token (but proceed anyway)
      print('🔐 Verifying authentication token...');
      final currentToken = await AuthService.getBackendToken();
      
      if (currentToken == null || currentToken.isEmpty) {
        print('⚠️ No JWT token found - will use admin token for authentication');
        print('⚠️ This is normal after returning from payment gateway');
      } else {
        print('✅ Valid JWT token found (length: ${currentToken.length})');
      }

      print('✅ Customer registered with phone: ${customerInfo['phone']}');

      final result;
      
      // If it's a scheme payment, route to specialized endpoint for server-side processing and progress updates
      if (schemeId != null && schemeId.isNotEmpty && status == 'SUCCESS') {
        print('🎯 CustomerService: Routing to specialized scheme endpoint ($schemeType)');
        
        if (schemeType == 'GOLDPLUS' || schemeType == 'SILVERPLUS') {
          result = await ApiService.investInScheme(
            schemeId: schemeId,
            amount: amount,
            transactionId: transactionId,
            gatewayTransactionId: gatewayTransactionId,
            deviceInfo: deviceInfo.toString(),
            location: location?.toString() ?? 'Location not available',
          );
        } else if (schemeType == 'GOLDFLEXI' || schemeType == 'SILVERFLEXI') {
          result = await ApiService.makeFlexiPayment(
            schemeId: schemeId,
            amount: amount,
            transactionId: transactionId,
            gatewayTransactionId: gatewayTransactionId,
            paymentMethod: paymentMethod,
            deviceInfo: deviceInfo.toString(),
            location: location?.toString() ?? 'Location not available',
          );
        } else {
          // Fallback to regular save if scheme type unknown but ID exists
          result = await ApiService.saveTransaction(
            transactionId: transactionId,
            customerPhone: customerInfo['phone']!,
            customerName: customerInfo['name'] ?? 'Unknown',
            type: type,
            amount: amount,
            goldGrams: goldGrams,
            goldPricePerGram: goldPricePerGram,
            paymentMethod: paymentMethod,
            status: status,
            gatewayTransactionId: gatewayTransactionId,
            deviceInfo: deviceInfo.toString(),
            location: location?.toString() ?? 'Location not available',
            additionalData: additionalData,
            schemeType: schemeType,
            schemeId: schemeId,
            silverGrams: silverGrams,
            silverPricePerGram: silverPricePerGram,
          );
        }
      } else {
        // Regular transaction (not a scheme payment or failed payment)
        result = await ApiService.saveTransaction(
          transactionId: transactionId,
          customerPhone: customerInfo['phone']!,
          customerName: customerInfo['name'] ?? 'Unknown',
          type: type,
          amount: amount,
          goldGrams: goldGrams,
          goldPricePerGram: goldPricePerGram,
          paymentMethod: paymentMethod,
          status: status,
          gatewayTransactionId: gatewayTransactionId,
          deviceInfo: deviceInfo.toString(),
          location: location?.toString() ?? 'Location not available',
          additionalData: additionalData,
          schemeType: schemeType,
          schemeId: schemeId,
          silverGrams: silverGrams,
          silverPricePerGram: silverPricePerGram,
        );
      }

      print('📥 ApiService.saveTransaction returned: $result');

      if (result['success']) {
        print('✅✅✅ TRANSACTION SAVED TO SERVER SUCCESSFULLY! ✅✅✅');
        
        // Log analytics - DISABLED: endpoint not implemented
        // await ApiService.logAnalytics(
        //   event: 'transaction_completed',
        //   data: {
        //     'transaction_id': transactionId,
        //     'amount': amount,
        //     'gold_grams': goldGrams,
        //     'payment_method': paymentMethod,
        //     'customer_phone': customerInfo['phone'],
        //   },
        // );
        
        return result;
      } else {
        print('📡 Global routing completed. Success: ${result['success']}');
      
        return result;
      }
    } catch (e) {
      print('❌ Error in CustomerService.saveTransactionWithCustomerData: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update transaction status on server
  static Future<bool> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? failureReason,
  }) async {
    try {
      final result = await ApiService.updateTransactionStatus(
        transactionId: transactionId,
        status: status,
        failureReason: failureReason,
      );

      return result['success'] ?? false;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // Log app events for business analytics
  static Future<void> logEvent(String event, Map<String, dynamic> data) async {
    try {
      final customerInfo = await getCustomerInfo();
      final deviceInfo = await getDeviceInfo();

      await ApiService.logAnalytics(
        event: event,
        data: {
          ...data,
          'customer_phone': customerInfo['phone'],
          'device_id': deviceInfo['device_id'],
          'platform': deviceInfo['platform'],
        },
      );
    } catch (e) {
      print('Error logging event: $e');
    }
  }

  // Clear login session
  static Future<void> clearLoginSession() async {
    print('🗑️ Clearing login session...');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all customer data
      await prefs.remove(_customerPhoneKey);
      await prefs.remove(_customerNameKey);
      await prefs.remove(_customerEmailKey);
      await prefs.remove('customer_id');
      await prefs.remove('customer_address');
      await prefs.remove('customer_pan_card');
      await prefs.setBool(_customerRegisteredKey, false);

      print('✅ Login session cleared successfully');
    } catch (e) {
      print('❌ Error clearing login session: $e');
    }
  }
}
