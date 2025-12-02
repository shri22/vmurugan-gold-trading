// DEPRECATED: This file is kept for backward compatibility
// All payment processing has been migrated to Omniware Payment Gateway
// Use OmniwarePaymentPageScreen instead (UPI Mode with Payment Page)

import 'package:flutter/material.dart';
import '../models/payment_response.dart';
import 'omniware_payment_page_screen.dart';

// Redirect wrapper for backward compatibility
class EnhancedPaymentScreen extends StatelessWidget {
  final double amount;
  final double goldGrams;
  final String description;
  final String? metalType;
  final Function(PaymentResponse) onPaymentComplete;

  const EnhancedPaymentScreen({
    super.key,
    required this.amount,
    required this.goldGrams,
    required this.description,
    this.metalType = 'gold', // Default to gold
    required this.onPaymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to Omniware Payment Page Screen (UPI Mode)
    return OmniwarePaymentPageScreen(
      amount: amount,
      goldGrams: goldGrams,
      description: description,
      metalType: metalType ?? 'gold', // Default to gold if not specified
      onPaymentComplete: onPaymentComplete,
    );
  }
}
