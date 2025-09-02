import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_model.dart';
import 'upi_payment_service.dart';
import 'paynimo_payment_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/config/server_config.dart';

/// Enhanced Payment Service that handles UPI and Paynimo payments
class EnhancedPaymentService {
  static final EnhancedPaymentService _instance = EnhancedPaymentService._internal();
  factory EnhancedPaymentService() => _instance;
  EnhancedPaymentService._internal();

  final UpiPaymentService _upiService = UpiPaymentService();
  final PaynimoPaymentService _paynimoService = PaynimoPaymentService();

  // =============================================================================
  // MAIN PAYMENT PROCESSING
  // =============================================================================

  /// Process payment based on method type
  Future<PaymentResponse> processPayment({
    required PaymentRequest request,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      print('🚀 EnhancedPaymentService: Processing payment...');
      print('   Method: ${request.method.displayName}');
      print('   Amount: ₹${request.amount}');
      print('   Transaction ID: ${request.transactionId}');

      if (request.method.isPaynimoMethod) {
        // For test environment, allow small amounts
        if (PaynimoConfig.isTestEnvironment && !PaynimoConfig.isValidTestAmount(request.amount)) {
          return PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'Test amount must be between ₹${PaynimoConfig.minTestAmount} and ₹${PaynimoConfig.maxTestAmount}',
          );
        }

        return await _processPaynimoPayment(
          request: request,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
        );
      } else {
        return await _processUpiPayment(request);
      }
    } catch (e) {
      print('❌ EnhancedPaymentService: Payment processing error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'Payment processing failed: $e',
      );
    }
  }

  // =============================================================================
  // UPI PAYMENT PROCESSING
  // =============================================================================

  /// Process UPI payments (existing functionality)
  Future<PaymentResponse> _processUpiPayment(PaymentRequest request) async {
    print('📱 Processing UPI payment: ${request.method.displayName}');

    switch (request.method) {
      case PaymentMethod.gpay:
        return await _upiService.payWithGPay(request);
      case PaymentMethod.phonepe:
        return await _upiService.payWithPhonePe(request);
      case PaymentMethod.upiIntent:
        return await _upiService.payWithUpiIntent(request);
      case PaymentMethod.qrCode:
        return await _processQRCodePayment(request);
      default:
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: 'UPI payment method not supported: ${request.method}',
        );
    }
  }

  /// Process QR Code payment
  Future<PaymentResponse> _processQRCodePayment(PaymentRequest request) async {
    // This would show QR code for payment
    // For now, return pending status
    return PaymentResponse.pending(
      transactionId: request.transactionId,
      additionalData: {
        'method': 'qr_code',
        'upi_id': request.merchantUpiId,
        'amount': request.amount,
        'description': request.description,
      },
    );
  }

  // =============================================================================
  // PAYNIMO PAYMENT PROCESSING
  // =============================================================================

  /// Process Paynimo gateway payments
  Future<PaymentResponse> _processPaynimoPayment({
    required PaymentRequest request,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      print('💳 Processing Paynimo payment: ${request.method.displayName}');

      // Get customer details
      customerName ??= 'VMurugan Customer';
      customerEmail ??= 'customer@vmuruganjewellery.co.in';
      customerPhone ??= '9999999999';

      // Try to get actual customer details if phone is available
      if (customerPhone != '9999999999') {
        try {
          // TODO: Implement customer service integration
          print('📞 Customer phone: $customerPhone');
          // For now, use default values
        } catch (e) {
          print('⚠️ Could not fetch customer details: $e');
        }
      }

      // Initiate payment with Paynimo
      final paynimoResponse = await _paynimoService.initiatePayment(
        transactionId: request.transactionId,
        amount: request.amount,
        customerName: customerName ?? 'VMurugan Customer',
        customerEmail: customerEmail ?? 'customer@vmuruganjewellery.co.in',
        customerPhone: customerPhone,
        description: request.description,
        paymentMethod: _getPaynimoMethodString(request.method),
      );

      if (paynimoResponse.success) {
        return PaymentResponse.success(
          transactionId: request.transactionId,
          gatewayTransactionId: paynimoResponse.gatewayTransactionId ?? '',
          additionalData: {
            'paynimo_payment_id': paynimoResponse.paymentId,
            'paynimo_payment_url': paynimoResponse.paymentUrl,
            'payment_method': request.method.displayName,
            'gateway': 'Paynimo',
            'amount': request.amount,
            'customer_name': customerName,
            'customer_email': customerEmail,
            'customer_phone': customerPhone,
          },
        );
      } else {
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: paynimoResponse.errorMessage ?? 'Paynimo payment initiation failed',
          additionalData: {
            'gateway': 'Paynimo',
            'payment_method': request.method.displayName,
          },
        );
      }

    } catch (e) {
      print('❌ Paynimo payment processing error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'Paynimo payment processing failed: $e',
        additionalData: {
          'gateway': 'Paynimo',
          'payment_method': request.method.displayName,
        },
      );
    }
  }



  // =============================================================================
  // PAYMENT STATUS VERIFICATION
  // =============================================================================

  /// Verify payment status for any payment method
  Future<PaymentResponse> verifyPaymentStatus(String transactionId, PaymentMethod method) async {
    try {
      print('🔍 Verifying payment status for transaction: $transactionId');

      // For UPI and Paynimo payments, use existing verification logic
      return PaymentResponse.pending(
        transactionId: transactionId,
        additionalData: {
          'verification_required': true,
          'method': method.displayName,
        },
      );
    } catch (e) {
      print('❌ Payment verification error: $e');
      return PaymentResponse.failed(
        transactionId: transactionId,
        errorMessage: 'Payment verification failed: $e',
      );
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Get available payment methods based on environment
  List<PaymentMethod> getAvailablePaymentMethods() {
    final methods = <PaymentMethod>[];

    // Add Paynimo methods if configured (primary gateway)
    if (isPaynimoConfigured) {
      methods.addAll([
        PaymentMethod.paynimoCard,
        PaymentMethod.paynimoNetbanking,
        PaymentMethod.paynimoUpi,
        PaymentMethod.paynimoWallet,
      ]);
    }

    // Always add UPI methods
    methods.addAll([
      PaymentMethod.gpay,
      PaymentMethod.phonepe,
      PaymentMethod.upiIntent,
      PaymentMethod.qrCode,
    ]);



    return methods;
  }

  /// Check if Paynimo is properly configured
  bool get isPaynimoConfigured => true; // Always configured for Paynimo

  /// Get payment method recommendations
  List<PaymentMethod> getRecommendedMethods() {
    final available = getAvailablePaymentMethods();

    // Prioritize based on reliability and user preference
    final recommended = <PaymentMethod>[];

    // Add Paynimo methods first (more reliable for larger amounts)
    recommended.addAll([
      PaymentMethod.paynimoCard,
      PaymentMethod.paynimoNetbanking,
      PaymentMethod.paynimoUpi,
      PaymentMethod.paynimoWallet,
    ]);

    // Add UPI methods
    recommended.addAll([
      PaymentMethod.gpay,
      PaymentMethod.phonepe,
      PaymentMethod.upiIntent,
    ]);

    return recommended.where((method) => available.contains(method)).toList();
  }

  /// Get Paynimo method string
  String _getPaynimoMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.paynimoCard:
        return 'CARD';
      case PaymentMethod.paynimoNetbanking:
        return 'NET_BANKING';
      case PaymentMethod.paynimoUpi:
        return 'UPI';
      case PaymentMethod.paynimoWallet:
        return 'WALLET';
      default:
        return 'CARD'; // Default fallback
    }
  }
}
