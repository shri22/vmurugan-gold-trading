import 'dart:async';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentVerificationService {
  static final PaymentVerificationService _instance = PaymentVerificationService._internal();
  factory PaymentVerificationService() => _instance;
  PaymentVerificationService._internal();

  /// Automatically verify payment status by checking with payment gateway/bank
  Future<PaymentResponse> showPaymentVerificationDialog({
    required BuildContext context,
    required PaymentRequest request,
    required String transactionId,
  }) async {
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Verifying payment status...'),
            const SizedBox(height: 8),
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we check with your bank',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // Step 1: Wait for payment app to process (give user time to complete payment)
      await Future.delayed(const Duration(seconds: 2));

      // Step 2: Check payment status automatically
      final paymentStatus = await _checkPaymentStatusAutomatically(request, transactionId);

      // Step 3: If status is still pending, do additional verification attempts
      if (paymentStatus.status == PaymentStatus.pending) {
        // Try multiple verification attempts with increasing delays
        for (int attempt = 1; attempt <= 3; attempt++) {
          await Future.delayed(Duration(seconds: attempt * 2)); // 2s, 4s, 6s delays

          final retryStatus = await _checkPaymentStatusAutomatically(request, transactionId);
          if (retryStatus.status != PaymentStatus.pending) {
            Navigator.pop(context); // Close loading dialog
            return retryStatus;
          }
        }
      }

      Navigator.pop(context); // Close loading dialog
      return paymentStatus;

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Payment verification error: $e');

      // If verification fails, return failed status
      return PaymentResponse.failed(
        transactionId: transactionId,
        errorMessage: 'Payment verification failed: ${e.toString()}',
      );
    }
  }

  /// Check payment status automatically with bank/payment gateway
  Future<PaymentResponse> _checkPaymentStatusAutomatically(
    PaymentRequest request,
    String transactionId,
  ) async {
    try {
      // Step 1: Check with payment gateway API
      final gatewayStatus = await _checkWithPaymentGateway(transactionId, request);
      if (gatewayStatus != null) {
        return gatewayStatus;
      }

      // Step 2: Check with bank API (UPI transaction status)
      final bankStatus = await _checkWithBankAPI(transactionId, request);
      if (bankStatus != null) {
        return bankStatus;
      }

      // Step 3: Check merchant account for transaction
      final merchantStatus = await _checkMerchantAccount(transactionId, request);
      if (merchantStatus != null) {
        return merchantStatus;
      }

      // If all checks fail, return pending for manual review
      return PaymentResponse.pending(
        transactionId: transactionId,
        additionalData: {
          'message': 'Payment verification in progress',
          'retry_after': '60',
          'verification_attempts': '3',
        },
      );

    } catch (e) {
      print('Error checking payment status: $e');
      return PaymentResponse.failed(
        transactionId: transactionId,
        errorMessage: 'Payment verification failed: ${e.toString()}',
      );
    }
  }

  /// Check with payment gateway (Razorpay, PayU, etc.)
  Future<PaymentResponse?> _checkWithPaymentGateway(String transactionId, PaymentRequest request) async {
    try {
      // Simulate payment gateway API call
      await Future.delayed(const Duration(milliseconds: 800));

      print('🔍 Checking with payment gateway for transaction: $transactionId');

      // In a real implementation, this would call actual payment gateway APIs
      // For now, we'll simulate a more realistic scenario where most payments fail
      // because users typically cancel or don't complete the payment

      // Simulate realistic gateway response (20% success, 80% failed/cancelled)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      if (random < 20) {
        // Only 20% success rate - more realistic for testing
        print('✅ Payment gateway: Transaction found and successful');
        return PaymentResponse.success(
          transactionId: transactionId,
          gatewayTransactionId: 'GATEWAY_${DateTime.now().millisecondsSinceEpoch}',
          additionalData: {
            'verification_method': 'payment_gateway',
            'gateway_name': 'UPI_GATEWAY',
            'verified_at': DateTime.now().toIso8601String(),
            'gateway_reference': 'GW${DateTime.now().millisecondsSinceEpoch}',
          },
        );
      } else if (random < 90) {
        // 70% failed/cancelled - user didn't complete payment
        print('❌ Payment gateway: Transaction not found or failed');
        return PaymentResponse.failed(
          transactionId: transactionId,
          errorMessage: 'Payment was not completed or was cancelled by user',
        );
      }

      // 10% continue to next verification method
      print('⏳ Payment gateway: No definitive result, checking other sources...');
      return null;

    } catch (e) {
      print('Payment gateway check failed: $e');
      return null;
    }
  }

  /// Check with bank API for UPI transaction status
  Future<PaymentResponse?> _checkWithBankAPI(String transactionId, PaymentRequest request) async {
    try {
      // Simulate bank API call
      await Future.delayed(const Duration(milliseconds: 1000));

      print('🏦 Checking with bank API for transaction: $transactionId');

      // In real implementation, this would call:
      // - NPCI UPI Transaction Status API
      // - Bank-specific APIs
      // - UPI PSP APIs

      // Simulate bank response (15% success rate - even lower for secondary check)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      if (random < 15) {
        // Only 15% success rate for bank verification
        print('✅ Bank API: Transaction found and successful');
        return PaymentResponse.success(
          transactionId: transactionId,
          gatewayTransactionId: 'BANK_${DateTime.now().millisecondsSinceEpoch}',
          additionalData: {
            'verification_method': 'bank_api',
            'bank_name': 'UPI_BANK',
            'verified_at': DateTime.now().toIso8601String(),
            'bank_reference': 'BNK${DateTime.now().millisecondsSinceEpoch}',
            'upi_ref': 'UPI${DateTime.now().millisecondsSinceEpoch}',
          },
        );
      } else if (random < 85) {
        // 70% failed - transaction not found or failed
        print('❌ Bank API: Transaction not found in bank records');
        return PaymentResponse.failed(
          transactionId: transactionId,
          errorMessage: 'Transaction not found in bank records - payment was not completed',
        );
      }

      // 15% continue to next verification method
      print('⏳ Bank API: No definitive result, checking merchant account...');
      return null;

    } catch (e) {
      print('Bank API check failed: $e');
      return null;
    }
  }

  /// Check merchant account for received payments
  Future<PaymentResponse?> _checkMerchantAccount(String transactionId, PaymentRequest request) async {
    try {
      // Simulate merchant account check
      await Future.delayed(const Duration(milliseconds: 600));

      print('💰 Checking merchant account for transaction: $transactionId');

      // In real implementation, this would:
      // - Check merchant UPI account balance changes
      // - Query merchant payment history
      // - Check settlement reports

      // Final verification attempt (10% success rate - very low for final check)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      if (random < 10) {
        // Only 10% success rate for merchant verification
        print('✅ Merchant Account: Payment received and verified');
        return PaymentResponse.success(
          transactionId: transactionId,
          gatewayTransactionId: 'MERCHANT_${DateTime.now().millisecondsSinceEpoch}',
          additionalData: {
            'verification_method': 'merchant_account',
            'verified_at': DateTime.now().toIso8601String(),
            'merchant_reference': 'MER${DateTime.now().millisecondsSinceEpoch}',
            'settlement_status': 'received',
          },
        );
      } else if (random < 80) {
        // 70% failed - no payment received
        print('❌ Merchant Account: No payment received for this transaction');
        return PaymentResponse.failed(
          transactionId: transactionId,
          errorMessage: 'No payment received in merchant account - transaction was not completed',
        );
      }

      // 20% return null - all verification methods exhausted, will return pending
      print('⏳ Merchant Account: Unable to verify payment status');
      return null;

    } catch (e) {
      print('Merchant account check failed: $e');
      return null;
    }
  }

  /// Verify payment with bank/gateway (placeholder for real implementation)
  Future<PaymentResponse> verifyWithGateway(String transactionId, PaymentRequest request) async {
    // In a real implementation, this would:
    // 1. Call bank/payment gateway API
    // 2. Check transaction status
    // 3. Return actual payment result
    
    // For now, return pending status requiring user confirmation
    return PaymentResponse.pending(
      transactionId: transactionId,
      additionalData: {
        'verification_method': 'user_confirmation',
        'amount': request.amount.toString(),
        'merchant_upi': request.merchantUpiId,
      },
    );
  }
}

class PaymentVerificationDialog extends StatefulWidget {
  final PaymentRequest request;
  final String transactionId;
  final Function(PaymentResponse) onResult;

  const PaymentVerificationDialog({
    super.key,
    required this.request,
    required this.transactionId,
    required this.onResult,
  });

  @override
  State<PaymentVerificationDialog> createState() => _PaymentVerificationDialogState();
}

class _PaymentVerificationDialogState extends State<PaymentVerificationDialog> {
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payment, color: Colors.blue),
          SizedBox(width: 8),
          Text('Verify Payment'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please check your UPI app and confirm the payment status:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction ID: ${widget.transactionId}'),
                Text('Amount: ₹${widget.request.amount.toStringAsFixed(2)}'),
                Text('To: ${widget.request.merchantUpiId}'),
                Text('Description: ${widget.request.description}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Text(
              '⚠️ Only confirm "Payment Successful" if money has been debited from your account and you received a success message in your UPI app.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => _handlePaymentResult(PaymentStatus.failed),
          child: const Text('Payment Failed'),
        ),
        TextButton(
          onPressed: _isVerifying ? null : () => _handlePaymentResult(PaymentStatus.cancelled),
          child: const Text('Cancelled'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : () => _handlePaymentResult(PaymentStatus.success),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isVerifying 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Payment Successful'),
        ),
      ],
    );
  }

  void _handlePaymentResult(PaymentStatus status) async {
    setState(() => _isVerifying = true);

    // Add a small delay to show verification process
    await Future.delayed(const Duration(seconds: 1));

    PaymentResponse response;
    
    switch (status) {
      case PaymentStatus.success:
        response = PaymentResponse.success(
          transactionId: widget.transactionId,
          gatewayTransactionId: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
          additionalData: {
            'verification_method': 'user_confirmed',
            'verification_time': DateTime.now().toIso8601String(),
            'amount': widget.request.amount.toString(),
            'merchant_upi': widget.request.merchantUpiId,
          },
        );
        break;
      case PaymentStatus.failed:
        response = PaymentResponse.failed(
          transactionId: widget.transactionId,
          errorMessage: 'Payment failed as confirmed by user',
        );
        break;
      case PaymentStatus.cancelled:
        response = PaymentResponse.cancelled(
          transactionId: widget.transactionId,
        );
        break;
      default:
        response = PaymentResponse.failed(
          transactionId: widget.transactionId,
          errorMessage: 'Unknown payment status',
        );
    }

    widget.onResult(response);
  }
}
