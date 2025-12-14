import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

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
  static Future<bool> saveTransactionWithCustomerData({
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

      // Ensure customer is registered
      if (customerInfo['phone'] == null || customerInfo['phone']!.isEmpty) {
        print('❌❌❌ CUSTOMER NOT REGISTERED - CANNOT SAVE TRANSACTION ❌❌❌');
        print('❌ Customer phone is null or empty: "${customerInfo['phone']}"');
        print('❌ Please ensure user is properly logged in and registered');
        return false;
      }

      // Additional validation
      if (customerInfo['name'] == null || customerInfo['name']!.isEmpty) {
        print('⚠️ WARNING: Customer name is null or empty, using fallback');
        customerInfo['name'] = 'VMurugan Customer';
      }

      print('✅ Customer registered with phone: ${customerInfo['phone']}');

      print('🔄 Calling ApiService.saveTransaction...');
      print('📤 Data being sent to ApiService:');
      print('  📞 Customer Phone: ${customerInfo['phone']}');
      print('  👤 Customer Name: ${customerInfo['name'] ?? 'Unknown'}');
      print('  📋 Additional Data: ${additionalData != null ? 'Present' : 'Not provided'}');

      final result = await ApiService.saveTransaction(
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

      print('📥 ApiService.saveTransaction returned: $result');

      if (result['success']) {
        print('✅✅✅ TRANSACTION SAVED TO SERVER SUCCESSFULLY! ✅✅✅');
        
        // Log analytics
        await ApiService.logAnalytics(
          event: 'transaction_completed',
          data: {
            'transaction_id': transactionId,
            'amount': amount,
            'gold_grams': goldGrams,
            'payment_method': paymentMethod,
            'customer_phone': customerInfo['phone'],
          },
        );
        
        return true;
      } else {
        print('Failed to save transaction to server: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Error saving transaction with customer data: $e');
      return false;
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
