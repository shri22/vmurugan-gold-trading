import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/payment_model.dart';
import '../../../core/config/server_config.dart';

/// Omniware Payment Gateway Service
/// Handles payment processing through Omniware gateway
class OmniwarePaymentService {
  static final OmniwarePaymentService _instance = OmniwarePaymentService._internal();
  factory OmniwarePaymentService() => _instance;
  OmniwarePaymentService._internal();

  // =============================================================================
  // PAYMENT INITIATION
  // =============================================================================

  /// Initiate payment through Omniware gateway
  Future<OmniwarePaymentResponse> initiatePayment({
    required String transactionId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
    String paymentMethod = 'netbanking', // Default to netbanking for testing
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      print('🚀 OmniwarePaymentService: Initiating payment...');
      print('   Transaction ID: $transactionId');
      print('   Amount: ₹$amount');
      print('   Customer: $customerName ($customerEmail)');
      print('   Method: $paymentMethod');

      // Validate configuration
      if (!OmniwareConfig.isConfigured) {
        throw Exception('Omniware configuration is incomplete');
      }

      // Validate payment method for current environment
      if (!OmniwareConfig.availablePaymentMethods.contains(paymentMethod)) {
        throw Exception('Payment method $paymentMethod not available in ${OmniwareConfig.isTestEnvironment ? 'testing' : 'live'} environment');
      }

      // Prepare payment request
      final paymentRequest = _buildPaymentRequest(
        transactionId: transactionId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        description: description,
        paymentMethod: paymentMethod,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );

      // Generate hash for security
      final hash = _generateHash(paymentRequest);
      paymentRequest['hash'] = hash;

      print('🔐 Generated payment hash: ${hash.substring(0, 20)}...');

      // Make API call to Omniware
      final response = await _makePaymentRequest(paymentRequest);

      if (response.success) {
        print('✅ Payment initiated successfully');
        print('   Payment URL: ${response.paymentUrl}');
        return response;
      } else {
        print('❌ Payment initiation failed: ${response.errorMessage}');
        throw Exception(response.errorMessage ?? 'Payment initiation failed');
      }

    } catch (e) {
      print('❌ OmniwarePaymentService: Payment initiation error: $e');
      return OmniwarePaymentResponse(
        success: false,
        transactionId: transactionId,
        errorMessage: e.toString(),
      );
    }
  }

  // =============================================================================
  // PAYMENT STATUS VERIFICATION
  // =============================================================================

  /// Check payment status
  Future<OmniwarePaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      print('🔍 OmniwarePaymentService: Checking payment status for $transactionId');

      final statusRequest = {
        'merchant_id': OmniwareConfig.merchantId,
        'transaction_id': transactionId,
        'api_key': OmniwareConfig.apiKey,
      };

      // Generate hash for status request
      final hash = _generateStatusHash(statusRequest);
      statusRequest['hash'] = hash;

      final response = await http.post(
        Uri.parse(OmniwareConfig.statusEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(statusRequest),
      );

      print('📡 Status API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parseStatusResponse(responseData, transactionId);
      } else {
        print('❌ Status check failed with code: ${response.statusCode}');
        return OmniwarePaymentStatus(
          transactionId: transactionId,
          status: 'FAILED',
          message: 'Status check failed',
        );
      }

    } catch (e) {
      print('❌ OmniwarePaymentService: Status check error: $e');
      return OmniwarePaymentStatus(
        transactionId: transactionId,
        status: 'ERROR',
        message: e.toString(),
      );
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Build payment request payload
  Map<String, dynamic> _buildPaymentRequest({
    required String transactionId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
    required String paymentMethod,
    String? returnUrl,
    String? cancelUrl,
  }) {
    // Convert amount to paisa (multiply by 100)
    final amountInPaisa = (amount * 100).toInt();

    return {
      'merchant_id': OmniwareConfig.merchantId,
      'transaction_id': transactionId,
      'amount': amountInPaisa.toString(),
      'currency': 'INR',
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'description': description,
      'payment_method': paymentMethod,
      'return_url': returnUrl ?? 'https://vmuruganjewellery.co.in/payment/success',
      'cancel_url': cancelUrl ?? 'https://vmuruganjewellery.co.in/payment/cancel',
      'api_key': OmniwareConfig.apiKey,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }

  /// Generate secure hash for payment request
  String _generateHash(Map<String, dynamic> request) {
    // Create hash string according to Omniware documentation
    final hashString = '${request['merchant_id']}'
        '|${request['transaction_id']}'
        '|${request['amount']}'
        '|${request['currency']}'
        '|${request['customer_email']}'
        '|${OmniwareConfig.salt}';

    final bytes = utf8.encode(hashString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate hash for status request
  String _generateStatusHash(Map<String, dynamic> request) {
    final hashString = '${request['merchant_id']}'
        '|${request['transaction_id']}'
        '|${OmniwareConfig.salt}';

    final bytes = utf8.encode(hashString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Make HTTP request to Omniware payment API
  Future<OmniwarePaymentResponse> _makePaymentRequest(Map<String, dynamic> request) async {
    try {
      final response = await http.post(
        Uri.parse(OmniwareConfig.paymentEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request),
      );

      print('📡 Payment API Response: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parsePaymentResponse(responseData, request['transaction_id']);
      } else {
        return OmniwarePaymentResponse(
          success: false,
          transactionId: request['transaction_id'],
          errorMessage: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }

    } catch (e) {
      return OmniwarePaymentResponse(
        success: false,
        transactionId: request['transaction_id'],
        errorMessage: 'Network error: $e',
      );
    }
  }

  /// Parse payment response from Omniware
  OmniwarePaymentResponse _parsePaymentResponse(Map<String, dynamic> response, String transactionId) {
    try {
      // Parse according to Omniware API response format
      final success = response['status'] == 'success' || response['success'] == true;
      
      if (success) {
        return OmniwarePaymentResponse(
          success: true,
          transactionId: transactionId,
          paymentUrl: response['payment_url'] ?? response['redirect_url'],
          gatewayTransactionId: response['gateway_transaction_id'] ?? response['reference_id'],
          message: response['message'] ?? 'Payment initiated successfully',
        );
      } else {
        return OmniwarePaymentResponse(
          success: false,
          transactionId: transactionId,
          errorMessage: response['message'] ?? response['error'] ?? 'Payment initiation failed',
        );
      }
    } catch (e) {
      return OmniwarePaymentResponse(
        success: false,
        transactionId: transactionId,
        errorMessage: 'Failed to parse response: $e',
      );
    }
  }

  /// Parse status response from Omniware
  OmniwarePaymentStatus _parseStatusResponse(Map<String, dynamic> response, String transactionId) {
    try {
      return OmniwarePaymentStatus(
        transactionId: transactionId,
        status: response['status'] ?? 'UNKNOWN',
        gatewayTransactionId: response['gateway_transaction_id'] ?? response['reference_id'],
        amount: response['amount']?.toString(),
        message: response['message'] ?? '',
        timestamp: response['timestamp'],
      );
    } catch (e) {
      return OmniwarePaymentStatus(
        transactionId: transactionId,
        status: 'ERROR',
        message: 'Failed to parse status response: $e',
      );
    }
  }
}
