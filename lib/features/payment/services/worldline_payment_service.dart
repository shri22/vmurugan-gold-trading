import 'dart:convert';
import 'dart:math';
import '../../../core/services/secure_http_client.dart';
import '../models/payment_response.dart';

class WorldlinePaymentService {
  static const String _baseUrl = 'https://api.worldline.com'; // Replace with actual Worldline API URL
  static const String _merchantId = 'YOUR_MERCHANT_ID'; // Replace with actual merchant ID
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key

  static final WorldlinePaymentService _instance = WorldlinePaymentService._internal();
  factory WorldlinePaymentService() => _instance;
  WorldlinePaymentService._internal();

  /// Initialize payment with Worldline
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String currency,
    required String orderId,
    required String customerId,
    required String customerEmail,
    required String customerPhone,
    required String description,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      final paymentData = {
        'merchant_id': _merchantId,
        'order_id': orderId,
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': currency,
        'customer_id': customerId,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'description': description,
        'return_url': returnUrl ?? 'https://your-app.com/payment/success',
        'cancel_url': cancelUrl ?? 'https://your-app.com/payment/cancel',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Generate checksum (implement according to Worldline documentation)
      paymentData['checksum'] = _generateChecksum(paymentData);

      final response = await SecureHttpClient.post(
        '$_baseUrl/payment/initiate',
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: paymentData,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error initiating Worldline payment: $e');
      rethrow;
    }
  }

  /// Process UPI payment
  Future<PaymentResponse> processUpiPayment({
    required String orderId,
    required double amount,
    required String upiId,
    required String description,
  }) async {
    try {
      final paymentData = {
        'merchant_id': _merchantId,
        'order_id': orderId,
        'amount': (amount * 100).toInt(),
        'payment_method': 'UPI',
        'upi_id': upiId,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      paymentData['checksum'] = _generateChecksum(paymentData);

      final response = await SecureHttpClient.post(
        '$_baseUrl/payment/upi',
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: paymentData,
      );

      return _parsePaymentResponse(response.body, orderId, amount, 'UPI');
    } catch (e) {
      print('Error processing UPI payment: $e');
      return PaymentResponse.failed(
        transactionId: orderId,
        amount: amount,
        paymentMethod: 'UPI',
        errorMessage: 'UPI payment failed: $e',
        errorCode: 'UPI_ERROR',
      );
    }
  }

  /// Process card payment
  Future<PaymentResponse> processCardPayment({
    required String orderId,
    required double amount,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required String description,
  }) async {
    try {
      final paymentData = {
        'merchant_id': _merchantId,
        'order_id': orderId,
        'amount': (amount * 100).toInt(),
        'payment_method': 'CARD',
        'card_number': cardNumber,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'cvv': cvv,
        'card_holder_name': cardHolderName,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      paymentData['checksum'] = _generateChecksum(paymentData);

      final response = await SecureHttpClient.post(
        '$_baseUrl/payment/card',
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: paymentData,
      );

      return _parsePaymentResponse(response.body, orderId, amount, 'CARD');
    } catch (e) {
      print('Error processing card payment: $e');
      return PaymentResponse.failed(
        transactionId: orderId,
        amount: amount,
        paymentMethod: 'CARD',
        errorMessage: 'Card payment failed: $e',
        errorCode: 'CARD_ERROR',
      );
    }
  }

  /// Process net banking payment
  Future<PaymentResponse> processNetBankingPayment({
    required String orderId,
    required double amount,
    required String bankCode,
    required String description,
  }) async {
    try {
      final paymentData = {
        'merchant_id': _merchantId,
        'order_id': orderId,
        'amount': (amount * 100).toInt(),
        'payment_method': 'NET_BANKING',
        'bank_code': bankCode,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      paymentData['checksum'] = _generateChecksum(paymentData);

      final response = await SecureHttpClient.post(
        '$_baseUrl/payment/netbanking',
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: paymentData,
      );

      return _parsePaymentResponse(response.body, orderId, amount, 'NET_BANKING');
    } catch (e) {
      print('Error processing net banking payment: $e');
      return PaymentResponse.failed(
        transactionId: orderId,
        amount: amount,
        paymentMethod: 'NET_BANKING',
        errorMessage: 'Net banking payment failed: $e',
        errorCode: 'NETBANKING_ERROR',
      );
    }
  }

  /// Check payment status
  Future<PaymentResponse> checkPaymentStatus(String orderId) async {
    try {
      final response = await SecureHttpClient.get(
        '$_baseUrl/payment/status/$orderId',
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parseStatusResponse(responseData, orderId);
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking payment status: $e');
      return PaymentResponse.failed(
        transactionId: orderId,
        amount: 0.0,
        paymentMethod: 'UNKNOWN',
        errorMessage: 'Failed to check payment status: $e',
        errorCode: 'STATUS_CHECK_ERROR',
      );
    }
  }

  /// Generate checksum for Worldline API
  String _generateChecksum(Map<String, dynamic> data) {
    // Implement checksum generation according to Worldline documentation
    // This is a placeholder implementation
    final sortedKeys = data.keys.toList()..sort();
    final checksumString = sortedKeys
        .map((key) => '$key=${data[key]}')
        .join('&');
    
    // In real implementation, use proper hashing algorithm (SHA256, etc.)
    return _generateHash(checksumString + _apiKey);
  }

  /// Generate hash (placeholder implementation)
  String _generateHash(String input) {
    // This is a placeholder - implement proper hashing
    return input.hashCode.abs().toString();
  }

  /// Parse payment response from Worldline
  PaymentResponse _parsePaymentResponse(
    String responseBody,
    String orderId,
    double amount,
    String paymentMethod,
  ) {
    try {
      final responseData = jsonDecode(responseBody);
      
      final status = _parsePaymentStatus(responseData['status']);
      final gatewayTransactionId = responseData['transaction_id'];
      final errorMessage = responseData['error_message'];
      final errorCode = responseData['error_code'];

      if (status == PaymentStatus.success) {
        return PaymentResponse.success(
          transactionId: orderId,
          amount: amount,
          paymentMethod: paymentMethod,
          gatewayTransactionId: gatewayTransactionId,
          gatewayResponse: responseBody,
          additionalData: responseData,
        );
      } else {
        return PaymentResponse.failed(
          transactionId: orderId,
          amount: amount,
          paymentMethod: paymentMethod,
          errorMessage: errorMessage,
          errorCode: errorCode,
          gatewayResponse: responseBody,
          additionalData: responseData,
        );
      }
    } catch (e) {
      return PaymentResponse.failed(
        transactionId: orderId,
        amount: amount,
        paymentMethod: paymentMethod,
        errorMessage: 'Failed to parse payment response: $e',
        errorCode: 'PARSE_ERROR',
      );
    }
  }

  /// Parse status response from Worldline
  PaymentResponse _parseStatusResponse(
    Map<String, dynamic> responseData,
    String orderId,
  ) {
    final status = _parsePaymentStatus(responseData['status']);
    final amount = (responseData['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = responseData['payment_method'] ?? 'UNKNOWN';
    final gatewayTransactionId = responseData['transaction_id'];

    return PaymentResponse(
      transactionId: orderId,
      status: status,
      amount: amount / 100, // Convert from paise to rupees
      currency: responseData['currency'] ?? 'INR',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      gatewayTransactionId: gatewayTransactionId,
      gatewayResponse: jsonEncode(responseData),
      additionalData: responseData,
    );
  }

  /// Parse payment status from Worldline response
  PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return PaymentStatus.success;
      case 'FAILED':
      case 'FAILURE':
        return PaymentStatus.failed;
      case 'PENDING':
        return PaymentStatus.pending;
      case 'PROCESSING':
        return PaymentStatus.processing;
      case 'CANCELLED':
      case 'CANCELED':
        return PaymentStatus.cancelled;
      case 'TIMEOUT':
        return PaymentStatus.timeout;
      default:
        return PaymentStatus.unknown;
    }
  }

  /// Generate unique order ID
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'ORD_${timestamp}_$random';
  }
}
