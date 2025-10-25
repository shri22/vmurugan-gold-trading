import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart' hide AppSpacing, AppBorderRadius;
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../services/silver_price_service.dart';
import '../models/silver_price_model.dart';
import '../../../core/services/auto_logout_service.dart';
import '../../schemes/services/scheme_management_service.dart';
import '../../schemes/models/scheme_installment_model.dart';
import '../../portfolio/services/portfolio_service.dart';
import '../../portfolio/models/portfolio_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/customer_registration_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../payment/models/payment_response.dart';
import '../../payment/widgets/payment_options_dialog.dart';
import '../../../core/config/validation_config.dart';
import '../../schemes/services/scheme_payment_validation_service.dart';

class BuySilverScreen extends StatefulWidget {
  final double? prefilledAmount;
  final bool? isFromScheme;
  final String? schemeId;
  final String? schemeName;

  const BuySilverScreen({
    super.key,
    this.prefilledAmount,
    this.isFromScheme,
    this.schemeId,
    this.schemeName,
  });

  @override
  State<BuySilverScreen> createState() => _BuySilverScreenState();
}

class _BuySilverScreenState extends State<BuySilverScreen> {
  final SilverPriceService _priceService = SilverPriceService();
  final PortfolioService _portfolioService = PortfolioService();
  final SchemeManagementService _schemeService = SchemeManagementService();
  final AutoLogoutService _autoLogoutService = AutoLogoutService();

  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  SilverPriceModel? _currentPrice;
  double _selectedAmount = 0.0;
  String? _selectedSchemeId;
  List<dynamic> _availableSchemes = []; // Simplified for now
  bool _isLoading = false;

  // Payment error tracking
  String? _lastPaymentError;
  Map<String, dynamic>? _detailedErrorInfo;

  @override
  void initState() {
    super.initState();

    // Set prefilled amount if coming from scheme
    if (widget.prefilledAmount != null) {
      _selectedAmount = widget.prefilledAmount!;
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(0);
    }

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadSilverPrice();
    await _loadAvailableSchemes();
  }

  Future<void> _loadSilverPrice() async {
    try {
      setState(() => _isLoading = true);
      final price = await _priceService.getCurrentPrice();
      setState(() {
        _currentPrice = price;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading silver price: $e');
    }
  }

  Future<void> _loadAvailableSchemes() async {
    try {
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];
      
      if (customerId != null && customerId.isNotEmpty) {
        // final schemes = await _schemeService.getActiveSchemes(customerId);
        setState(() {
          _availableSchemes = []; // Temporarily disabled
        });
      }
    } catch (e) {
      print('Error loading schemes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final silverQuantity = _currentPrice != null
        ? _selectedAmount / _currentPrice!.pricePerGram
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Silver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
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
            // Current Silver Price Card
            _buildSilverPriceCard(),

            const SizedBox(height: AppSpacing.xl),

            // Amount Selection Section
            _buildAmountSelectionSection(),

            const SizedBox(height: AppSpacing.xl),

            // Silver Quantity Preview
            _buildSilverQuantityPreview(silverQuantity),

            const SizedBox(height: AppSpacing.xl),

            // Investment Summary
            _buildInvestmentSummary(silverQuantity),

            const SizedBox(height: AppSpacing.xxl),

            // Buy Button
            _buildBuyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverPriceCard() {
    if (_currentPrice == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Price Unavailable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Silver price data is currently unavailable.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _currentPrice = null;
                  });
                  await _loadSilverPrice();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
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
                    'Current Silver Price',
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
              'Silver Rate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.silver,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currentPrice!.formattedPrice,
              style: AppTypography.titleLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'per gram',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.silver,
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
          widget.isFromScheme == true ? 'Monthly Investment Amount' : 'Enter Investment Amount',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Show scheme info if coming from scheme
        if (widget.isFromScheme == true && widget.schemeName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.silver.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.silver.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.silver),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheme Investment',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.silver,
                        ),
                      ),
                      Text(
                        widget.schemeName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Custom Amount Input
        CustomTextField(
          label: widget.isFromScheme == true ? 'Monthly Investment Amount (Fixed)' : 'Investment Amount',
          hint: widget.isFromScheme == true ? 'Amount set by scheme' : 'Enter amount in ₹',
          controller: _amountController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.currency_rupee,
          enabled: widget.isFromScheme != true, // Disable if from scheme
          onChanged: widget.isFromScheme == true ? null : (value) {
            final amount = double.tryParse(value) ?? 0.0;
            setState(() {
              _selectedAmount = amount;
            });
          },
          inputFormatters: widget.isFromScheme == true ? [] : [
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

  Widget _buildSilverQuantityPreview(double silverQuantity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.silverGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.silver.withValues(alpha: 0.3),
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
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You will get',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${silverQuantity.toStringAsFixed(4)} grams',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'of Digital Silver',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSummary(double silverQuantity) {
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
            _buildSummaryRow('Silver Price', _currentPrice?.formattedPrice ?? '₹0.00'),
            _buildSummaryRow('Silver Quantity', '${silverQuantity.toStringAsFixed(4)} grams'),
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
              color: isTotal ? AppColors.silver : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Investment Amount',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedAmount = double.tryParse(value) ?? 0.0;
            });
          },
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
        if (_selectedAmount > 0 && _currentPrice != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You will get: ${(_selectedAmount / _currentPrice!.pricePerGram).toStringAsFixed(3)} grams of silver',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSchemeSelection() {
    if (_availableSchemes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Scheme (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSchemeId,
          decoration: const InputDecoration(
            hintText: 'Choose a scheme',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No scheme (Direct purchase)'),
            ),
            // Temporarily disabled scheme dropdown
            // ..._availableSchemes.map((scheme) => DropdownMenuItem<String>(
            //   value: scheme.schemeId,
            //   child: Text('${scheme.schemeName} - ₹${scheme.installmentAmount}/month'),
            // )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSchemeId = value;
            });
          },
        ),
      ],
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
                    'Purchases unavailable - Silver service not connected',
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
          onPressed: (isValidAmount && canPurchase) ? _handleBuySilver : null,
          gradient: canPurchase ? AppColors.silverGreenGradient : LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade500],
          ),
          icon: canPurchase ? Icons.payment : Icons.warning,
          isFullWidth: true,
        ),
      ],
    );
  }

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
                    ],
                  ),
                ),
              ],
            ),
          ],
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuySilver() async {
    // First check if silver service is available and price is loaded
    if (!_priceService.canPurchase || _currentPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silver purchases are currently unavailable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _currentPrice == null
                    ? 'Price data is not available. Please wait for price to load or try refreshing.'
                    : 'MJDTA price service is unavailable. Please try again later.',
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () async {
              await _loadSilverPrice();
            },
          ),
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
          const SnackBar(content: Text('Registration required to buy silver')),
        );
        return;
      }
    }

    // If this is a scheme payment, validate scheme payment rules
    if (widget.isFromScheme == true && widget.schemeId != null) {
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'] ?? '';

      if (customerPhone.isNotEmpty) {
        final validationResult = await SchemePaymentValidationService.validateSchemePayment(
          schemeId: widget.schemeId!,
          customerPhone: customerPhone,
          amount: _selectedAmount,
        );

        if (!validationResult.canPay) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationResult.message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
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
          content: Text('Silver price not available. Please wait for price update or try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final silverGrams = _selectedAmount / _currentPrice!.pricePerGram;

    // Show payment options dialog
    _showPaymentOptionsDialog(silverGrams);
  }

  void _showPaymentOptionsDialog(double silverGrams) {
    showDialog(
      context: context,
      builder: (context) => PaymentOptionsDialog(
        amount: _selectedAmount,
        description: 'Silver Purchase - ${silverGrams.toStringAsFixed(4)}g',
        metalGrams: silverGrams,
        metalType: 'silver',
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

      // Save transaction to database only after successful payment
      _saveSuccessfulTransaction(response);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silver purchase successful! Transaction ID: ${response.transactionId}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Navigate back to portfolio or show success screen
      Navigator.pop(context);
    } else {
      // Capture detailed error information for display
      setState(() {
        _lastPaymentError = response.errorMessage;
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

  Future<void> _saveSuccessfulTransaction(PaymentResponse response) async {
    try {
      if (_currentPrice == null) {
        print('❌ Cannot save transaction: Silver price not available');
        return;
      }

      final silverGrams = _selectedAmount / _currentPrice!.pricePerGram;

      // Save transaction with customer data
      final success = await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: response.amount,
        goldGrams: silverGrams, // Using goldGrams field for silver grams (backward compatibility)
        goldPricePerGram: _currentPrice!.pricePerGram,
        paymentMethod: response.paymentMethod,
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      if (success) {
        print('✅ Silver transaction saved successfully: ${response.transactionId}');
      } else {
        print('❌ Failed to save silver transaction: ${response.transactionId}');
      }
    } catch (e) {
      print('❌ Error saving silver transaction: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
