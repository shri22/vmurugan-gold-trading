import 'dart:async';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentVerificationService {
  static final PaymentVerificationService _instance = PaymentVerificationService._internal();
  factory PaymentVerificationService() => _instance;
  PaymentVerificationService._internal();

  /// Show payment verification dialog to user
  Future<PaymentResponse> showPaymentVerificationDialog({
    required BuildContext context,
    required PaymentRequest request,
    required String transactionId,
  }) async {
    final completer = Completer<PaymentResponse>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentVerificationDialog(
        request: request,
        transactionId: transactionId,
        onResult: (result) {
          Navigator.pop(context);
          completer.complete(result);
        },
      ),
    );

    return completer.future;
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
