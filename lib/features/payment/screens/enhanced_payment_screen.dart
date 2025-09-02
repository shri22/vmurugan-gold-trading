import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/enhanced_payment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/config/server_config.dart';

class EnhancedPaymentScreen extends StatefulWidget {
  final double amount;
  final double goldGrams;
  final String description;
  final Function(PaymentResponse) onPaymentComplete;

  const EnhancedPaymentScreen({
    super.key,
    required this.amount,
    required this.goldGrams,
    required this.description,
    required this.onPaymentComplete,
  });

  @override
  State<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends State<EnhancedPaymentScreen> {
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  PaymentMethod? _selectedMethod;
  bool _isProcessingPayment = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        backgroundColor: AppColors.primaryGold,
      ),
      body: Column(
        children: [
          // Payment Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.goldGreenGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppBorderRadius.lg),
                bottomRight: Radius.circular(AppBorderRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Gold: ${widget.goldGrams.toStringAsFixed(3)}g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Environment Info
          if (PaynimoConfig.isTestEnvironment)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Testing Environment: Test payments (₹1-10) available through Paynimo gateway',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Payment Methods
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Paynimo Methods Section
                if (_paymentService.isPaynimoConfigured) ...[
                  _buildSectionHeader('Secure Gateway Payments'),
                  ..._buildPaynimoMethods(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // UPI Methods Section
                _buildSectionHeader('UPI Payments'),
                ..._buildUpiMethods(),
              ],
            ),
          ),

          // Pay Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _selectedMethod != null && !_isProcessingPayment
                  ? _processPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
              child: _isProcessingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Processing Payment...'),
                      ],
                    )
                  : Text(
                      _selectedMethod != null
                          ? 'Pay ₹${widget.amount.toStringAsFixed(2)} via ${_selectedMethod!.displayName}'
                          : 'Select Payment Method',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  List<Widget> _buildPaynimoMethods() {
    final methods = _paymentService.getAvailablePaymentMethods()
        .where((method) => method.isPaynimoMethod)
        .toList();

    return methods.map((method) => _buildPaymentMethodTile(
      method: method,
      icon: _getPaynimoMethodIcon(method),
      subtitle: _getPaynimoMethodSubtitle(method),
      isRecommended: method == PaymentMethod.paynimoCard && PaynimoConfig.isTestEnvironment,
    )).toList();
  }

  List<Widget> _buildUpiMethods() {
    final methods = _paymentService.getAvailablePaymentMethods()
        .where((method) => !method.isPaynimoMethod)
        .toList();

    return methods.map((method) => _buildPaymentMethodTile(
      method: method,
      icon: _getUpiMethodIcon(method),
      subtitle: _getUpiMethodSubtitle(method),
    )).toList();
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethod method,
    required IconData icon,
    required String subtitle,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          side: BorderSide(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
          title: Row(
            children: [
              Text(
                method.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(subtitle),
          trailing: Radio<PaymentMethod>(
            value: method,
            groupValue: _selectedMethod,
            onChanged: (value) {
              setState(() {
                _selectedMethod = value;
              });
            },
            activeColor: AppColors.primaryGold,
          ),
          onTap: () {
            setState(() {
              _selectedMethod = method;
            });
          },
        ),
      ),
    );
  }

  IconData _getPaynimoMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.paynimoCard:
        return Icons.credit_card;
      case PaymentMethod.paynimoNetbanking:
        return Icons.account_balance;
      case PaymentMethod.paynimoUpi:
        return Icons.payment;
      case PaymentMethod.paynimoWallet:
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }



  String _getPaynimoMethodSubtitle(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.paynimoCard:
        return 'Credit/Debit card payment via Paynimo';
      case PaymentMethod.paynimoNetbanking:
        return 'Secure bank transfer via Paynimo';
      case PaymentMethod.paynimoUpi:
        return 'UPI payment via Paynimo gateway';
      case PaymentMethod.paynimoWallet:
        return 'Digital wallet via Paynimo';
      default:
        return 'Secure Paynimo gateway payment';
    }
  }



  IconData _getUpiMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.gpay:
        return Icons.payment;
      case PaymentMethod.phonepe:
        return Icons.phone_android;
      case PaymentMethod.upiIntent:
        return Icons.apps;
      case PaymentMethod.qrCode:
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  String _getUpiMethodSubtitle(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.gpay:
        return 'Pay using Google Pay app';
      case PaymentMethod.phonepe:
        return 'Pay using PhonePe app';
      case PaymentMethod.upiIntent:
        return 'Choose from all UPI apps';
      case PaymentMethod.qrCode:
        return 'Scan QR code to pay';
      default:
        return 'UPI payment';
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      final request = PaymentRequest(
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.amount,
        merchantName: 'VMurugan Gold Trading',
        merchantUpiId: 'vmuruganjew2127@fbl',
        description: widget.description,
        method: _selectedMethod!,
      );

      final response = await _paymentService.processPayment(request: request);
      
      widget.onPaymentComplete(response);
      
      if (mounted) {
        Navigator.pop(context, response);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }
}
