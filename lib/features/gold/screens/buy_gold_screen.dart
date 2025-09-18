import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
// Ensure AppColors is imported for gradients
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../models/gold_price_model.dart';
import '../services/gold_price_service.dart';
import '../../notifications/services/notification_service.dart';

import '../../../core/config/server_config.dart';
import '../../schemes/services/scheme_management_service.dart';
import '../../schemes/models/scheme_installment_model.dart';
import '../../portfolio/services/portfolio_service.dart';
import '../../portfolio/models/portfolio_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/auto_logout_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/customer_registration_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../payment/models/payment_response.dart';
import '../../payment/screens/enhanced_payment_screen.dart';

import '../../payment/widgets/payment_options_dialog.dart';
import '../../../core/config/validation_config.dart';

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  final GoldPriceService _priceService = GoldPriceService();

  final PortfolioService _portfolioService = PortfolioService();
  final SchemeManagementService _schemeService = SchemeManagementService();
  final AutoLogoutService _autoLogoutService = AutoLogoutService();

  final TextEditingController _amountController = TextEditingController();
  
  GoldPriceModel? _currentPrice;
  double _selectedAmount = 0.0;
  String? _selectedSchemeId;

  // Payment error tracking
  String? _lastPaymentError;
  Map<String, dynamic>? _detailedErrorInfo;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _amountController.text = _selectedAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _priceService.initialize();
    
    // Listen to price updates
    _priceService.priceStream.listen((price) {
      if (mounted) {
        setState(() {
          _currentPrice = price;
        });
      }
    });
    
    // Load initial price
    _loadInitialPrice();
  }

  void _loadInitialPrice() async {
    final price = await _priceService.getCurrentPrice();
    setState(() {
      _currentPrice = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final goldQuantity = _currentPrice != null 
        ? _selectedAmount / _currentPrice!.pricePerGram 
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Gold'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Info dialog functionality removed during cleanup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Info dialog functionality will be restored in future updates'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Gold Price Card
            _buildGoldPriceCard(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Amount Selection Section
            _buildAmountSelectionSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Gold Quantity Preview
            _buildGoldQuantityPreview(goldQuantity),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Investment Summary
            _buildInvestmentSummary(goldQuantity),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Buy Button
            _buildBuyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldPriceCard() {
    if (_currentPrice == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Gold Price (22K)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _currentPrice!.isPositive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : _currentPrice!.isNegative
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentPrice!.isPositive
                              ? Icons.trending_up
                              : _currentPrice!.isNegative
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 16,
                          color: _currentPrice!.isPositive
                              ? AppColors.success
                              : _currentPrice!.isNegative
                                  ? AppColors.error
                                  : AppColors.grey,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            _currentPrice!.formattedChange,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _currentPrice!.isPositive
                                  ? AppColors.success
                                  : _currentPrice!.isNegative
                                      ? AppColors.error
                                      : AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gold Rate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currentPrice!.formattedPrice,
              style: AppTypography.amountDisplay,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'per gram',
              style: AppTypography.rateInfo.copyWith(
                color: AppColors.primaryGreen, // Ensure dark green for visibility
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Investment Amount',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Custom Amount Input
        CustomTextField(
          label: 'Investment Amount',
          hint: 'Enter amount in ₹',
          controller: _amountController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.currency_rupee,
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            setState(() {
              _selectedAmount = amount;
            });
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7), // Max 10 lakh
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid amount';
            }

            // Use dynamic validation based on sandbox mode
            return ValidationConfig.validatePaymentAmount(amount);
          },
        ),
      ],
    );
  }

  Widget _buildGoldQuantityPreview(double goldQuantity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.diamond,
            size: 48,
            color: AppColors.primaryGreen, // Changed from white to dark green
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You will get',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryGreen, // Changed from white to dark green
              fontWeight: FontWeight.w600, // Added weight for better visibility
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${goldQuantity.toStringAsFixed(4)} grams',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primaryGreen, // Changed from white to dark green
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'of 22K Digital Gold',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.primaryGreen, // Changed from white to dark green
              fontWeight: FontWeight.w600, // Added weight for better visibility
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSummary(double goldQuantity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investment Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('Investment Amount', '₹${_selectedAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Gold Price', _currentPrice?.formattedPrice ?? '₹0.00'),
            _buildSummaryRow('Gold Quantity', '${goldQuantity.toStringAsFixed(4)} grams'),
            const Divider(height: AppSpacing.lg),
            _buildSummaryRow(
              'Total Payable', 
              '₹${_selectedAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primaryGold : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    final isValidAmount = ValidationConfig.validatePaymentAmount(_selectedAmount) == null;
    final canPurchase = _priceService.canPurchase;

    return Column(
      children: [
        if (!canPurchase) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Purchases unavailable - MJDTA service not connected',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Payment Error Display Section
        if (_lastPaymentError != null) ...[
          const SizedBox(height: 16),
          _buildPaymentErrorDisplay(),
          const SizedBox(height: 16),
        ],

        GradientButton(
          text: canPurchase ? 'Proceed to Payment' : 'Service Unavailable',
          onPressed: (isValidAmount && canPurchase) ? _handleBuyGold : null,
          gradient: canPurchase ? AppColors.goldGreenGradient : LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade500],
          ),
          icon: canPurchase ? Icons.payment : Icons.warning,
          isFullWidth: true,
        ),
      ],
    );
  }

  Future<void> _handleBuyGold() async {
    // Clear any previous payment errors when starting new payment
    setState(() {
      _lastPaymentError = null;
      _detailedErrorInfo = null;
    });

    // First check if MJDTA is available
    if (!_priceService.canPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gold purchases are currently unavailable. Please try again later.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate amount using dynamic validation
    final amountError = ValidationConfig.validatePaymentAmount(_selectedAmount);
    if (amountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(amountError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if customer is registered
    final isRegistered = await CustomerService.isCustomerRegistered();
    if (!isRegistered) {
      final registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerRegistrationScreen(),
        ),
      );

      if (registered != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration required to buy gold')),
        );
        return;
      }
    }

    // Navigate to payment screen
    _navigateToPayment();
  }

  Future<void> _navigateToPayment() async {
    // Check if price is available
    if (_currentPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gold price not available. Please wait for price update or try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final goldGrams = _selectedAmount / _currentPrice!.pricePerGram;

    // Show payment options dialog for demo
    _showPaymentOptionsDialog(goldGrams);
  }

  void _showPaymentOptionsDialog(double goldGrams) {
    showDialog(
      context: context,
      builder: (context) => PaymentOptionsDialog(
        amount: _selectedAmount,
        metalGrams: goldGrams,
        metalType: 'gold',
        onPaymentComplete: _handlePaymentComplete,
      ),
    );
  }

  void _handlePaymentComplete(PaymentResponse response) {
    if (response.status == PaymentStatus.success) {
      // Clear any previous error information
      setState(() {
        _lastPaymentError = null;
        _detailedErrorInfo = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gold purchase successful! Transaction ID: ${response.transactionId}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Navigate back to portfolio or show success screen
      Navigator.pop(context);
    } else {
      // Capture detailed error information for display
      setState(() {
        _lastPaymentError = response.message;
        _detailedErrorInfo = response.additionalData;
      });

      // Show brief error message in snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed - see details below'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Removed orphaned code fragments that were causing compilation errors
  // All payment functionality is now handled by the new PaymentOptionsDialog

  // Removed old payment detail widget that had compilation errors
  // Payment details are now handled by the new PaymentOptionsDialog

  // Removed old payment verification function that had compilation errors
  // Payment verification is now handled by the new PaymentOptionsDialog

  // Removed old payment verification handler that had compilation errors
  // Payment verification is now handled by the new PaymentOptionsDialog

  // Removed old transaction saving function that had compilation errors
  // Transaction saving is now handled by the new PaymentOptionsDialog

  // Removed old error dialog function that had compilation errors
  // Error handling is now done by the new PaymentOptionsDialog

  // Removed old MJDTA dialog function that had compilation errors
  // Service availability is now handled by the new PaymentOptionsDialog

  // Removed old success dialog function that had compilation errors
  // Success handling is now done by the new PaymentOptionsDialog

  // Removed old payment dialog function that had compilation errors
  // Payment dialog is now handled by the new PaymentOptionsDialog

  // Removed old payment function that had compilation errors
  // Payment is now handled by the new PaymentOptionsDialog

  // Removed old UPI payment function that had compilation errors
  // Payment is now handled by the new PaymentOptionsDialog

  // Removed old payment response handler that had compilation errors
  // Payment is now handled by the new PaymentOptionsDialog

  // Removed old payment processing functions that had compilation errors
  // Payment processing is now handled by the new PaymentOptionsDialog

  // Removed old info dialog function that had compilation errors
  // Info dialog functionality can be added back when needed

  // Removed old scheme management functions that had compilation errors
  // Scheme management is now handled by the updated scheme service

  /// Build detailed payment error display widget
  Widget _buildPaymentErrorDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Header
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment Failed - Detailed Error Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              // Clear Error Button
              IconButton(
                onPressed: () {
                  setState(() {
                    _lastPaymentError = null;
                    _detailedErrorInfo = null;
                  });
                },
                icon: Icon(Icons.close, color: Colors.red.shade700),
                tooltip: 'Clear Error',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Basic Error Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _lastPaymentError ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade800,
              ),
            ),
          ),

          // Detailed Error Information
          if (_detailedErrorInfo != null) ...[
            const SizedBox(height: 12),

            // Technical Details Section
            ExpansionTile(
              title: Text(
                'Technical Details (for debugging)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildErrorDetailRow('Timestamp', _detailedErrorInfo!['timestamp']),
                      _buildErrorDetailRow('Session ID', _detailedErrorInfo!['sessionId']),
                      _buildErrorDetailRow('Payment Method', _detailedErrorInfo!['paymentMethod']),

                      if (_detailedErrorInfo!['statusCode'] != null)
                        _buildErrorDetailRow('Status Code', _detailedErrorInfo!['statusCode']),

                      if (_detailedErrorInfo!['statusMessage'] != null)
                        _buildErrorDetailRow('Status Message', _detailedErrorInfo!['statusMessage']),

                      if (_detailedErrorInfo!['errorCode'] != null)
                        _buildErrorDetailRow('Error Code', _detailedErrorInfo!['errorCode']),

                      if (_detailedErrorInfo!['detailedErrorInfo'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Worldline Response Details:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatErrorInfo(_detailedErrorInfo!['detailedErrorInfo']),
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Steps:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Check if the amount is between ₹1-₹10 for test environment\n'
                  '• Verify your internet connection\n'
                  '• Try the payment again\n'
                  '• Contact support if the issue persists',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatErrorInfo(Map<String, dynamic>? errorInfo) {
    if (errorInfo == null) return 'No detailed error information available';

    final buffer = StringBuffer();
    errorInfo.forEach((key, value) {
      if (key != 'fullResponse') { // Exclude full response to avoid too much data
        buffer.writeln('$key: $value');
      }
    });
    return buffer.toString();
  }

}
