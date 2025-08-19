import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_model.dart';
import 'upi_payment_service.dart';
import 'omniware_payment_service.dart';
import '../../../core/config/server_config.dart';
import '../../../core/services/customer_service.dart';

/// Enhanced Payment Service that handles both UPI and Omniware payments
class EnhancedPaymentService {
  static final EnhancedPaymentService _instance = EnhancedPaymentService._internal();
  factory EnhancedPaymentService() => _instance;
  EnhancedPaymentService._internal();

  final UpiPaymentService _upiService = UpiPaymentService();
  final OmniwarePaymentService _omniwareService = OmniwarePaymentService();

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

      if (request.method.isOmniware) {
        return await _processOmniwarePayment(
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
  // OMNIWARE PAYMENT PROCESSING
  // =============================================================================

  /// Process Omniware gateway payments
  Future<PaymentResponse> _processOmniwarePayment({
    required PaymentRequest request,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      print('🏦 Processing Omniware payment: ${request.method.displayName}');

      // Get customer details if not provided
      if (customerName == null || customerEmail == null || customerPhone == null) {
        final customerInfo = await CustomerService.getCustomerInfo();
        customerName ??= customerInfo['name'] ?? 'Customer';
        customerEmail ??= customerInfo['email'] ?? 'customer@vmuruganjewellery.co.in';
        customerPhone ??= customerInfo['phone'] ?? '+919677944711';
      }

      // Check if method is available in current environment
      if (OmniwareConfig.isTestEnvironment && !request.method.isAvailableInTesting) {
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: '${request.method.displayName} is not available in testing environment. Only Net Banking is available.',
        );
      }

      // Initiate payment with Omniware
      final omniwareResponse = await _omniwareService.initiatePayment(
        transactionId: request.transactionId,
        amount: request.amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        description: request.description,
        paymentMethod: request.method.omniwareMethodString,
      );

      if (omniwareResponse.success && omniwareResponse.paymentUrl != null) {
        // Launch payment URL in browser
        final launched = await _launchPaymentUrl(omniwareResponse.paymentUrl!);
        
        if (launched) {
          // Wait for payment completion and check status
          return await _waitForOmniwarePayment(request.transactionId);
        } else {
          return PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'Could not open payment page. Please try again.',
          );
        }
      } else {
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: omniwareResponse.errorMessage ?? 'Payment initiation failed',
        );
      }

    } catch (e) {
      print('❌ Omniware payment error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'Omniware payment failed: $e',
      );
    }
  }

  /// Launch payment URL in browser
  Future<bool> _launchPaymentUrl(String paymentUrl) async {
    try {
      print('🌐 Launching payment URL: $paymentUrl');
      
      final uri = Uri.parse(paymentUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ Payment URL launched successfully');
        return true;
      } else {
        print('❌ Failed to launch payment URL');
        return false;
      }
    } catch (e) {
      print('❌ Error launching payment URL: $e');
      return false;
    }
  }

  /// Wait for Omniware payment completion
  Future<PaymentResponse> _waitForOmniwarePayment(String transactionId) async {
    print('⏳ Waiting for Omniware payment completion...');

    // Poll payment status for up to 10 minutes
    const maxAttempts = 60; // 60 attempts * 10 seconds = 10 minutes
    const pollInterval = Duration(seconds: 10);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔍 Checking payment status (attempt $attempt/$maxAttempts)...');

        final status = await _omniwareService.checkPaymentStatus(transactionId);
        
        if (status.isSuccess) {
          print('✅ Payment completed successfully!');
          return status.toPaymentResponse();
        } else if (status.isFailed || status.isCancelled) {
          print('❌ Payment failed or cancelled: ${status.status}');
          return status.toPaymentResponse();
        }

        // Payment still pending, wait before next check
        if (attempt < maxAttempts) {
          print('⏳ Payment still pending, waiting ${pollInterval.inSeconds} seconds...');
          await Future.delayed(pollInterval);
        }

      } catch (e) {
        print('❌ Error checking payment status: $e');
        // Continue polling unless it's the last attempt
        if (attempt == maxAttempts) {
          return PaymentResponse.failed(
            transactionId: transactionId,
            errorMessage: 'Payment status check failed: $e',
          );
        }
      }
    }

    // Timeout reached
    print('⏰ Payment status check timeout reached');
    return PaymentResponse.pending(
      transactionId: transactionId,
      additionalData: {
        'timeout': true,
        'message': 'Payment status check timeout. Please verify manually.',
      },
    );
  }

  // =============================================================================
  // PAYMENT STATUS VERIFICATION
  // =============================================================================

  /// Verify payment status for any payment method
  Future<PaymentResponse> verifyPaymentStatus(String transactionId, PaymentMethod method) async {
    try {
      print('🔍 Verifying payment status for transaction: $transactionId');

      if (method.isOmniware) {
        final status = await _omniwareService.checkPaymentStatus(transactionId);
        return status.toPaymentResponse();
      } else {
        // For UPI payments, use existing verification logic
        return PaymentResponse.pending(
          transactionId: transactionId,
          additionalData: {
            'verification_required': true,
            'method': method.displayName,
          },
        );
      }
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

    // Always add UPI methods
    methods.addAll([
      PaymentMethod.gpay,
      PaymentMethod.phonepe,
      PaymentMethod.upiIntent,
      PaymentMethod.qrCode,
    ]);

    // Add Omniware methods based on environment
    if (OmniwareConfig.isTestEnvironment) {
      methods.add(PaymentMethod.omniwareNetbanking);
    } else {
      methods.addAll([
        PaymentMethod.omniwareNetbanking,
        PaymentMethod.omniwareUpi,
        PaymentMethod.omniwareCard,
        PaymentMethod.omniwareWallet,
        PaymentMethod.omniwareEmi,
      ]);
    }

    return methods;
  }

  /// Check if Omniware is properly configured
  bool get isOmniwareConfigured => OmniwareConfig.isConfigured;

  /// Get payment method recommendations
  List<PaymentMethod> getRecommendedMethods() {
    final available = getAvailablePaymentMethods();
    
    // Prioritize based on reliability and user preference
    final recommended = <PaymentMethod>[];
    
    // Add Omniware methods first (more reliable for larger amounts)
    if (OmniwareConfig.isTestEnvironment) {
      recommended.add(PaymentMethod.omniwareNetbanking);
    } else {
      recommended.addAll([
        PaymentMethod.omniwareUpi,
        PaymentMethod.omniwareCard,
        PaymentMethod.omniwareNetbanking,
      ]);
    }
    
    // Add UPI methods
    recommended.addAll([
      PaymentMethod.gpay,
      PaymentMethod.phonepe,
      PaymentMethod.upiIntent,
    ]);

    return recommended.where((method) => available.contains(method)).toList();
  }
}
