import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
// Ensure AppColors is imported for gradients
import '../../../core/utils/responsive.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../models/gold_price_model.dart';
import '../services/gold_price_service.dart';
import '../../notifications/services/notification_service.dart';

import '../../../core/config/server_config.dart';
import '../../../core/services/secure_http_client.dart';
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
import '../../schemes/services/scheme_payment_validation_service.dart';

class BuyGoldScreen extends StatefulWidget {
  final double? prefilledAmount;
  final bool? isFromScheme;
  final String? schemeId; // Will be null initially, created after payment
  final String? schemeType; // GOLDPLUS, GOLDFLEXI, etc.
  final double? monthlyAmount; // For PLUS schemes
  final String? schemeName;

  const BuyGoldScreen({
    super.key,
    this.prefilledAmount,
    this.isFromScheme,
    this.schemeId,
    this.schemeType,
    this.monthlyAmount,
    this.schemeName,
  });

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

    // Set prefilled amount if coming from scheme
    if (widget.prefilledAmount != null) {
      _selectedAmount = widget.prefilledAmount!;
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(0);
    } else {
      _amountController.text = _selectedAmount.toStringAsFixed(0);
    }
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
                'Gold price data is currently unavailable.\nPlease try again later.',
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
                  await _priceService.retryMjdtaConnection();
                  final price = await _priceService.getCurrentPrice();
                  setState(() {
                    _currentPrice = price;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
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
              style: AppTypography.titleLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'per gram',
              style: AppTypography.bodyMedium.copyWith(
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

        // Show scheme info if coming from scheme
        if (widget.isFromScheme == true && widget.schemeName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheme Investment',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
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
            '${NumberFormatter.formatToThreeDecimals(goldQuantity)} grams',
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
            _buildSummaryRow('Gold Quantity', '${NumberFormatter.formatToThreeDecimals(goldQuantity)} grams'),
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

    // First check if MJDTA is available and price is loaded
    if (!_priceService.canPurchase || _currentPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gold purchases are currently unavailable',
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
              await _priceService.retryMjdtaConnection();
              final price = await _priceService.getCurrentPrice();
              setState(() {
                _currentPrice = price;
              });
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
          const SnackBar(content: Text('Registration required to buy gold')),
        );
        return;
      }
    }

    // If this is a scheme payment, validate scheme payment rules
    if (widget.isFromScheme == true && widget.schemeId != null) {
      print('🔍 BUY GOLD: This is a scheme payment');
      print('🔍 BUY GOLD: Scheme ID: ${widget.schemeId}');
      print('🔍 BUY GOLD: Scheme Name: ${widget.schemeName}');
      print('🔍 BUY GOLD: Amount: $_selectedAmount');

      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'] ?? '';

      print('🔍 BUY GOLD: Customer phone: $customerPhone');

      if (customerPhone.isNotEmpty) {
        print('🔍 BUY GOLD: Starting validation...');

        final validationResult = await SchemePaymentValidationService.validateSchemePayment(
          schemeId: widget.schemeId!,
          customerPhone: customerPhone,
          amount: _selectedAmount,
        );

        print('🔍 BUY GOLD: Validation result: ${validationResult.toString()}');

        if (!validationResult.canPay) {
          print('❌ BUY GOLD: Validation failed: ${validationResult.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationResult.message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        print('✅ BUY GOLD: Validation passed, proceeding to payment');
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
        description: 'Gold Purchase - ${goldGrams.toStringAsFixed(4)}g',
        metalGrams: goldGrams,
        metalType: 'gold',
        onPaymentComplete: _handlePaymentComplete,
      ),
    );
  }

  void _handlePaymentComplete(PaymentResponse response) async {
    print('\n📥 ========== PAYMENT CALLBACK RECEIVED ========== 📥');
    print('Status: ${response.status}');
    print('Transaction ID: ${response.transactionId}');
    print('Amount: ₹${response.amount}');
    print('Payment Method: ${response.paymentMethod}');
    print('================================================\n');

    if (response.status == PaymentStatus.success) {
      // Clear any previous error information
      setState(() {
        _lastPaymentError = null;
        _detailedErrorInfo = null;
      });

      print('💾 Starting database save operation...');

      // Save transaction to database only after successful payment
      await _saveSuccessfulTransaction(response);

      print('✅ Database save completed');

      // If this is a scheme payment, create the scheme AFTER payment success
      if (widget.isFromScheme == true && widget.schemeType != null) {
        print('🎯 PAYMENT SUCCESS: Creating scheme after payment...');
        await _createSchemeAfterPayment(response);
      }

      // Get customer ID for success message
      String successMessage = 'Gold purchase successful! Transaction ID: ${response.transactionId}';
      try {
        final customerInfo = await CustomerService.getCustomerInfo();
        final customerId = customerInfo['customer_id'];
        if (customerId != null) {
          successMessage = 'Gold purchase successful!\nCustomer ID: $customerId\nTransaction ID: ${response.transactionId}';
        }
      } catch (e) {
        print('❌ Error getting customer ID: $e');
      }

      print('📱 Showing success message to user...');

      // Trigger success notification
      try {
        await NotificationTemplates.paymentSuccess(
          amount: response.amount,
          transactionId: response.transactionId,
        );
        print('✅ Success notification triggered');
      } catch (e) {
        print('⚠️ Failed to trigger success notification: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate back to portfolio or show success screen
        print('🔙 Navigating back to previous screen...');
        Navigator.pop(context);
      }

      print('✅ Payment flow completed successfully!\n');
    } else if (response.status == PaymentStatus.cancelled) {
      print('⚠️ Payment cancelled by user');

      // Clear any previous error information
      setState(() {
        _lastPaymentError = 'Payment was cancelled by user';
        _detailedErrorInfo = response.additionalData;
      });

      // Trigger cancelled notification
      try {
        await NotificationTemplates.paymentCancelled(
          amount: response.amount,
        );
        print('✅ Cancellation notification triggered');
      } catch (e) {
        print('⚠️ Failed to trigger cancellation notification: $e');
      }

      // Show cancellation message in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled by user'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Payment failed
      print('❌ Payment failed');

      // Capture detailed error information for display
      setState(() {
        _lastPaymentError = response.errorMessage;
        _detailedErrorInfo = response.additionalData;
      });

      // Trigger failure notification
      try {
        await NotificationTemplates.paymentFailed(
          amount: response.amount,
          reason: response.errorMessage ?? 'Unknown error',
        );
        print('✅ Failure notification triggered');
      } catch (e) {
        print('⚠️ Failed to trigger failure notification: $e');
      }

      // Show brief error message in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? 'Payment failed - see details below'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveSuccessfulTransaction(PaymentResponse response) async {
    try {
      print('\n💾 ========== SAVING TRANSACTION TO DATABASE ========== 💾');

      if (_currentPrice == null) {
        print('❌ Cannot save transaction: Gold price not available');
        return;
      }

      final goldGrams = _selectedAmount / _currentPrice!.pricePerGram;

      print('📊 Transaction Details:');
      print('   Transaction ID: ${response.transactionId}');
      print('   Type: BUY');
      print('   Amount: ₹${response.amount}');
      print('   Gold Grams: ${goldGrams.toStringAsFixed(4)}g');
      print('   Gold Price/Gram: ₹${_currentPrice!.pricePerGram}');
      print('   Payment Method: ${response.paymentMethod}');
      print('   Gateway Transaction ID: ${response.gatewayTransactionId ?? 'N/A'}');
      print('   Status: SUCCESS');

      // Save transaction with customer data
      print('📡 Calling CustomerService.saveTransactionWithCustomerData...');

      final success = await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: response.amount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice!.pricePerGram,
        paymentMethod: response.paymentMethod,
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      if (success) {
        print('✅ ========== TRANSACTION SAVED SUCCESSFULLY ========== ✅');
        print('   Transaction ID: ${response.transactionId}');
        print('   The transaction will now appear in:');
        print('   - Customer Portfolio (updated gold balance)');
        print('   - Transaction History');
        print('   - Admin Dashboard');
        print('   - All Reports');
        print('======================================================\n');
      } else {
        print('❌ ========== FAILED TO SAVE TRANSACTION ========== ❌');
        print('   Transaction ID: ${response.transactionId}');
        print('   Please check server logs for details');
        print('====================================================\n');
      }
    } catch (e) {
      print('❌ ========== ERROR SAVING TRANSACTION ========== ❌');
      print('   Error: $e');
      print('   Transaction ID: ${response.transactionId}');
      print('=================================================\n');
    }
  }

  Future<void> _createSchemeAfterPayment(PaymentResponse response) async {
    try {
      print('🎯 CREATE SCHEME AFTER PAYMENT: Starting...');
      print('🎯 Scheme Type: ${widget.schemeType}');
      print('🎯 Monthly Amount: ${widget.monthlyAmount}');
      print('🎯 Transaction ID: ${response.transactionId}');

      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'] ?? '';
      final customerName = customerInfo['name'] ?? '';

      if (customerPhone.isEmpty) {
        print('❌ CREATE SCHEME: Customer phone is empty');
        return;
      }

      final requestBody = {
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'scheme_type': widget.schemeType,
        'monthly_amount': widget.monthlyAmount ?? 0.0,
        'transaction_id': response.transactionId,
      };

      print('🔍 CREATE SCHEME: Request body: $requestBody');

      final apiResponse = await SecureHttpClient.post(
        'https://api.vmuruganjewellery.co.in:3001/api/schemes/create-after-payment',
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('🔍 CREATE SCHEME: Response status: ${apiResponse.statusCode}');
      print('🔍 CREATE SCHEME: Response body: ${apiResponse.body}');

      if (apiResponse.statusCode == 200) {
        final data = jsonDecode(apiResponse.body);
        if (data['success'] == true) {
          final schemeId = data['scheme_id'];
          final isNew = data['is_new'] ?? false;

          print('✅ CREATE SCHEME: Success! Scheme ID: $schemeId, Is New: $isNew');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNew
                ? 'Scheme created successfully! ID: $schemeId'
                : 'Using existing scheme: $schemeId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          print('❌ CREATE SCHEME: API returned success=false: ${data['message']}');
        }
      } else if (apiResponse.statusCode == 400) {
        // Handle monthly payment restriction error
        final data = jsonDecode(apiResponse.body);
        final errorCode = data['error_code'];

        if (errorCode == 'MONTHLY_PAYMENT_ALREADY_MADE') {
          final message = data['message'] ?? 'You have already paid for this month';
          print('⏰ MONTHLY PAYMENT RESTRICTION: $message');

          // Show user-friendly error dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Monthly Payment Limit'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PLUS schemes allow only one payment per calendar month.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }
        } else {
          print('❌ CREATE SCHEME: HTTP 400 error: ${data['message']}');
        }
      } else {
        print('❌ CREATE SCHEME: HTTP error ${apiResponse.statusCode}');
      }
    } catch (e) {
      print('❌ CREATE SCHEME: Exception: $e');
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
