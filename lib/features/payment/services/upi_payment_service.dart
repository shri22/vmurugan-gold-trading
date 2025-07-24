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
      final upiUrl = _buildGPayUrl(request);
      print('UpiPaymentService: Launching GPay with URL: $upiUrl');
      
      if (await _canLaunchApp(PaymentMethod.gpay)) {
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
            errorMessage: 'Failed to launch Google Pay',
          );
        }
      } else {
        // GPay not installed, redirect to Play Store
        await _redirectToPlayStore(PaymentMethod.gpay);
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: 'Google Pay not installed',
        );
      }
    } catch (e) {
      print('UpiPaymentService: GPay error: $e');
      return PaymentResponse.failed(
        transactionId: request.transactionId,
        errorMessage: 'GPay payment failed: ${e.toString()}',
      );
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
        // PhonePe not installed, redirect to Play Store
        await _redirectToPlayStore(PaymentMethod.phonepe);
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: 'PhonePe not installed',
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
        return PaymentResponse.failed(
          transactionId: request.transactionId,
          errorMessage: 'No UPI apps available',
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
    // On web, we can't check if apps are installed, so return true for demo
    if (kIsWeb) {
      return true;
    }

    try {
      final packageName = method.packageName;
      if (packageName.isEmpty) return true;

      // Check if app is installed using package name (Android only)
      const platform = MethodChannel('app_checker');
      final isInstalled = await platform.invokeMethod('isAppInstalled', packageName);
      return isInstalled ?? false;
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
    // Show a dialog asking user to confirm payment completion
    // In production, you would implement proper deep link callbacks

    print('UpiPaymentService: Payment app launched. Waiting for user to return...');

    // For now, we'll simulate the user completing payment
    // In production, implement proper payment status checking
    await Future.delayed(const Duration(seconds: 2));

    // Return success for demo - in production, verify payment status
    return PaymentResponse.success(
      transactionId: transactionId,
      gatewayTransactionId: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
      additionalData: {
        'paymentMethod': 'UPI',
        'timestamp': DateTime.now().toIso8601String(),
        'note': 'Real payment initiated - verify status manually',
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
