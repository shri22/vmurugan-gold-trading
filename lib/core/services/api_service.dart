import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'custom_server_service.dart';

class ApiService {
  // CONFIGURATION: Switch between Firebase and Custom Server
  static const bool useFirebase = true; // Set to false to use custom server

  // Firebase will be used by default, custom server when ready
  static const String mode = useFirebase ? 'Firebase' : 'Custom Server';

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
  }) async {
    print('ApiService: Routing to $mode for transaction save');

    if (useFirebase) {
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
      );
    } else {
      return await CustomServerService.saveTransaction(
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

    if (useFirebase) {
      return await FirebaseService.saveCustomer(
        phone: phone,
        name: name,
        email: email,
        address: address,
        panCard: panCard,
        deviceId: deviceId,
      );
    } else {
      return await CustomServerService.saveCustomer(
        phone: phone,
        name: name,
        email: email,
        address: address,
        panCard: panCard,
        deviceId: deviceId,
      );
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
