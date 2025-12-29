import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/payment_response.dart';
import '../screens/omniware_payment_page_screen.dart'; // UPI Mode (Payment Page)

enum PaymentMethod {
  upi,
  netBanking,
  debitCard,
  creditCard,
  wallet,
}

class PaymentOptionsDialog extends StatefulWidget {
  final double amount;
  final String description;
  final Function(PaymentResponse) onPaymentComplete;
  final VoidCallback? onCancel;
  final double? metalGrams;
  final String? metalType;

  const PaymentOptionsDialog({
    super.key,
    required this.amount,
    required this.description,
    required this.onPaymentComplete,
    this.onCancel,
    this.metalGrams,
    this.metalType,
  });

  @override
  State<PaymentOptionsDialog> createState() => _PaymentOptionsDialogState();
}

class _PaymentOptionsDialogState extends State<PaymentOptionsDialog> {
  PaymentMethod? _selectedMethod = PaymentMethod.upi; // Auto-select UPI (only option)
  bool _isProcessing = false;

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption(
      method: PaymentMethod.upi,
      title: 'UPI',
      subtitle: 'Pay using UPI apps like GPay, PhonePe, Paytm',
      icon: Icons.account_balance_wallet,
      isRecommended: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              fit: FlexFit.loose,
              child: _buildPaymentMethods(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose Payment Method',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isProcessing ? null : () {
                  widget.onCancel?.call();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount to Pay:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a payment method:',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: 12),
          ..._paymentMethods.map((option) => _buildPaymentMethodTile(option)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethodOption option) {
    final isSelected = _selectedMethod == option.method;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _isProcessing ? null : () {
          setState(() {
            _selectedMethod = option.method;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : AppColors.lightGrey,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? AppColors.primaryGold.withOpacity(0.1)
                : AppColors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.title,
                          style: AppTypography.titleSmall.copyWith(
                            color: isSelected 
                                ? AppColors.primaryGold 
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (option.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Recommended',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: option.method,
                groupValue: _selectedMethod,
                onChanged: _isProcessing ? null : (value) {
                  setState(() {
                    _selectedMethod = value;
                  });
                },
                activeColor: AppColors.primaryGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _isProcessing ? 'Processing...' : 'Proceed to Pay',
              onPressed: _selectedMethod != null && !_isProcessing
                  ? _processPayment
                  : null,
              type: ButtonType.primary,
              isLoading: _isProcessing,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isProcessing ? null : () {
              widget.onCancel?.call();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Navigate to Omniware UPI Mode payment page (NEW METHOD)
      // This opens Omniware's payment gateway page in WebView
      // Advantages: Instant status, auto-return, webhooks work, better UX
      final result = await Navigator.push<PaymentResponse>(
        context,
        MaterialPageRoute(
          builder: (context) => OmniwarePaymentPageScreen(
            amount: widget.amount,
            description: widget.description,
            goldGrams: widget.metalGrams ?? 0.0,
            metalType: widget.metalType ?? 'gold', // Pass metal type to determine merchant (779285 for gold, 779295 for silver)
            onPaymentComplete: (PaymentResponse response) {
              // This will be called when payment is actually completed
              // Note: We don't call widget.onPaymentComplete here because
              // the payment screen will return the response via Navigator.pop
              print('💳 Payment completed in screen, response will be returned via Navigator');
            },
          ),
        ),
      );

      print('📥 Payment screen returned with result: ${result?.status}');

      // Handle the result from payment screen
      if (result != null) {
        // Payment screen returned a result (success, failed, or cancelled)
        print('✅ Payment result received: ${result.status}');
        widget.onPaymentComplete(result);
      } else {
        // User closed the screen without any result (rare case - back button pressed before payment started)
        print('⚠️ Payment screen closed without result - treating as cancelled');
        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
        final response = PaymentResponse.cancelled(
          transactionId: transactionId,
          amount: widget.amount,
          paymentMethod: _getPaymentMethodName(_selectedMethod!),
          additionalData: {
            'description': widget.description,
            'method': _selectedMethod!.name,
            'reason': 'User closed payment screen',
          },
        );

        widget.onPaymentComplete(response);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      final response = PaymentResponse.failed(
        transactionId: transactionId,
        amount: widget.amount,
        paymentMethod: _getPaymentMethodName(_selectedMethod!),
        errorMessage: 'Payment processing failed: $e',
        errorCode: 'PROCESSING_ERROR',
      );

      widget.onPaymentComplete(response);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
    }
  }
}

class PaymentMethodOption {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRecommended;

  const PaymentMethodOption({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isRecommended = false,
  });
}
