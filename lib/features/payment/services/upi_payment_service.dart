import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_model.dart';

class UpiPaymentService {
  static final UpiPaymentService _instance = UpiPaymentService._internal();
  factory UpiPaymentService() => _instance;
  UpiPaymentService._internal();

  /// Initiate payment with GPay
  Future<PaymentResponse> payWithGPay(PaymentRequest request) async {
    try {
      // Try Google Pay specific URL first
      final gpayUrl = _buildGPayUrl(request);
      print('UpiPaymentService: Trying GPay specific URL: $gpayUrl');

      bool launched = false;

      try {
        launched = await launchUrl(
          Uri.parse(gpayUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('UpiPaymentService: GPay specific URL failed: $e');
        launched = false;
      }

      // If GPay specific URL failed, try standard UPI scheme
      if (!launched) {
        final alternativeUrl = _buildGPayAlternativeUrl(request);
        print('UpiPaymentService: Trying alternative UPI URL: $alternativeUrl');

        try {
          launched = await launchUrl(
            Uri.parse(alternativeUrl),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print('UpiPaymentService: Alternative UPI URL failed: $e');
          launched = false;
        }
      }

      if (launched) {
        // Wait for user to complete payment and return to app
        return await _waitForPaymentResult(request.transactionId);
      } else {
        // Both URLs failed, show helpful message and try UPI Intent
        print('UpiPaymentService: Google Pay could not be launched');
        print('UpiPaymentService: This might be because:');
        print('  1. Google Pay is not installed');
        print('  2. No payment account is set up in Google Pay');
        print('  3. Google Pay needs to be updated');
        print('UpiPaymentService: Trying UPI Intent as fallback...');
        return await payWithUpiIntent(request);
      }
    } catch (e) {
      print('UpiPaymentService: GPay error: $e');
      // Try UPI Intent as final fallback
      return await payWithUpiIntent(request);
    }
  }

  /// Initiate payment with PhonePe
  Future<PaymentResponse> payWithPhonePe(PaymentRequest request) async {
    try {
      final upiUrl = _buildPhonePeUrl(request);
      print('UpiPaymentService: Launching PhonePe with URL: $upiUrl');
      
      if (await _canLaunchApp(PaymentMethod.phonepe)) {
        final launched = await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          // Wait for user to complete payment and return to app
          return await _waitForPaymentResult(request.transactionId);
        } else {
          return PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'Failed to launch PhonePe',
          );
        }
      } else {
        // PhonePe not available, provide helpful message
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: 'PhonePe is not available. Please try UPI Apps or install PhonePe from Play Store.',
        );
      }
    } catch (e) {
      print('UpiPaymentService: PhonePe error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'PhonePe payment failed: ${e.toString()}',
      );
    }
  }

  /// Initiate payment with UPI Intent (shows all UPI apps)
  Future<PaymentResponse> payWithUpiIntent(PaymentRequest request) async {
    try {
      final upiUrl = _buildUpiIntentUrl(request);
      print('UpiPaymentService: Launching UPI Intent with URL: $upiUrl');
      
      final launched = await launchUrl(
        Uri.parse(upiUrl),
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        // Wait for user to complete payment and return to app
        return await _waitForPaymentResult(request.transactionId);
      } else {
        // If UPI Intent fails, return pending status for manual verification
        print('UpiPaymentService: UPI Intent launch failed, returning pending for manual verification');
        return PaymentResponse.pending(
          transactionId: request.transactionId,
          additionalData: {
            'message': 'Payment app could not be launched. Please complete payment manually and verify.',
            'upi_id': request.merchantUpiId,
            'amount': request.amount,
          },
        );
      }
    } catch (e) {
      print('UpiPaymentService: UPI Intent error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'UPI payment failed: ${e.toString()}',
      );
    }
  }

  /// Check if specific UPI app is installed
  Future<bool> _canLaunchApp(PaymentMethod method) async {
    // On web, we can't check if apps are installed, so return true
    if (kIsWeb) {
      return true;
    }

    try {
      // For mobile platforms, assume UPI apps are available
      // Most Android devices have at least one UPI app installed
      // We'll handle the actual launch failure gracefully
      switch (method) {
        case PaymentMethod.gpay:
        case PaymentMethod.phonepe:
        case PaymentMethod.upiIntent:
          return true; // Assume available, handle launch failure later
        default:
          return true;
      }
    } catch (e) {
      print('UpiPaymentService: App check error: $e');
      return true; // Assume available if check fails
    }
  }

  /// Redirect to Play Store to install UPI app
  Future<void> _redirectToPlayStore(PaymentMethod method) async {
    String playStoreUrl;
    switch (method) {
      case PaymentMethod.gpay:
        playStoreUrl = UpiConfig.gpayPlayStore;
        break;
      case PaymentMethod.phonepe:
        playStoreUrl = UpiConfig.phonepePlayStore;
        break;
      default:
        return;
    }
    
    await launchUrl(Uri.parse(playStoreUrl));
  }

  /// Build GPay specific UPI URL
  String _buildGPayUrl(PaymentRequest request) {
    final params = {
      'pa': UpiConfig.gpayUpiId,  // Use GPay specific UPI ID
      'pn': request.merchantName,
      'am': request.amount.toStringAsFixed(2),
      'cu': request.currency,
      'tn': request.description,
      'tr': request.transactionId,
      'mc': UpiConfig.merchantCode,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${UpiConfig.gpayScheme}?$queryString';
  }

  /// Build alternative GPay URL using standard UPI scheme
  String _buildGPayAlternativeUrl(PaymentRequest request) {
    final params = {
      'pa': UpiConfig.gpayUpiId,
      'pn': request.merchantName,
      'am': request.amount.toStringAsFixed(2),
      'cu': request.currency,
      'tn': request.description,
      'tr': request.transactionId,
      'mc': UpiConfig.merchantCode,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${UpiConfig.upiScheme}?$queryString';
  }

  /// Build PhonePe specific UPI URL
  String _buildPhonePeUrl(PaymentRequest request) {
    final params = {
      'pa': UpiConfig.phonepeUpiId,  // Use PhonePe specific UPI ID
      'pn': request.merchantName,
      'am': request.amount.toStringAsFixed(2),
      'cu': request.currency,
      'tn': request.description,
      'tr': request.transactionId,
      'mc': UpiConfig.merchantCode,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${UpiConfig.phonepeScheme}?$queryString';
  }

  /// Build generic UPI Intent URL
  String _buildUpiIntentUrl(PaymentRequest request) {
    final params = {
      'pa': UpiConfig.defaultUpiId,  // Use default UPI ID for generic UPI
      'pn': request.merchantName,
      'am': request.amount.toStringAsFixed(2),
      'cu': request.currency,
      'tn': request.description,
      'tr': request.transactionId,
      'mc': UpiConfig.merchantCode,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${UpiConfig.upiScheme}?$queryString';
  }

  /// Wait for payment result - User will return to app after payment
  Future<PaymentResponse> _waitForPaymentResult(String transactionId) async {
    print('UpiPaymentService: Payment app launched. Waiting for user to return...');

    // Wait for user to return from UPI app
    await Future.delayed(const Duration(seconds: 3));

    // Return pending status - actual verification will be done by the calling screen
    return PaymentResponse.pending(
      transactionId: transactionId,
      additionalData: {
        'paymentMethod': 'UPI',
        'timestamp': DateTime.now().toIso8601String(),
        'note': 'Payment initiated - verification required',
      },
    );
  }

  /// Verify payment status with user confirmation
  Future<PaymentResponse> verifyPaymentStatus(String transactionId, PaymentRequest request) async {
    // This method will be called by the UI to verify payment status
    // In a real implementation, this would:
    // 1. Check with payment gateway/bank API
    // 2. Verify transaction status
    // 3. Return actual payment result

    // For now, we'll implement user-based verification
    return PaymentResponse.pending(
      transactionId: transactionId,
      additionalData: {
        'verification_required': 'true',
        'amount': request.amount.toString(),
        'merchant_upi': request.merchantUpiId,
        'description': request.description,
      },
    );
  }

  /// Get list of available payment methods
  Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    final availableMethods = <PaymentMethod>[];

    if (await _canLaunchApp(PaymentMethod.gpay)) {
      availableMethods.add(PaymentMethod.gpay);
    }

    if (await _canLaunchApp(PaymentMethod.phonepe)) {
      availableMethods.add(PaymentMethod.phonepe);
    }

    // UPI Intent is available on mobile platforms
    if (!kIsWeb) {
      availableMethods.add(PaymentMethod.upiIntent);
    }

    // QR Code is always available
    availableMethods.add(PaymentMethod.qrCode);

    return availableMethods;
  }
}
