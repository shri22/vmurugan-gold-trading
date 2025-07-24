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

  // Get stored customer info
  static Future<Map<String, String?>> getCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone': prefs.getString(_customerPhoneKey),
      'name': prefs.getString(_customerNameKey),
      'email': prefs.getString(_customerEmailKey),
    };
  }

  // Save customer info locally and to server
  static Future<bool> registerCustomer({
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
        print('Customer registered successfully');
        return true;
      } else {
        print('Failed to register customer on server: ${result['message']}');
        // Still return true as local storage succeeded
        return true;
      }
    } catch (e) {
      print('Error registering customer: $e');
      return false;
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
  }) async {
    try {
      final customerInfo = await getCustomerInfo();
      final deviceInfo = await getDeviceInfo();
      final location = await getLocation();

      // Ensure customer is registered
      if (customerInfo['phone'] == null) {
        print('Customer not registered - cannot save transaction');
        return false;
      }

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
      );

      if (result['success']) {
        print('Transaction saved to server successfully');
        
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
}
