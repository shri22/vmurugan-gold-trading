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
// import '../../payment/screens/payment_screen.dart';
import '../../payment/services/upi_payment_service.dart';
import '../../payment/services/enhanced_payment_service.dart';
import '../../payment/services/payment_verification_service.dart';
import '../../payment/screens/enhanced_payment_screen.dart';
import '../../payment/models/payment_model.dart';
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

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  final GoldPriceService _priceService = GoldPriceService();
  final UpiPaymentService _paymentService = UpiPaymentService();
  final EnhancedPaymentService _enhancedPaymentService = EnhancedPaymentService();
  final PaymentVerificationService _verificationService = PaymentVerificationService();
  final PortfolioService _portfolioService = PortfolioService();
  final SchemeManagementService _schemeService = SchemeManagementService();
  final AutoLogoutService _autoLogoutService = AutoLogoutService();
  final TextEditingController _amountController = TextEditingController();
  
  GoldPriceModel? _currentPrice;
  double _selectedAmount = 0.0;
  String? _selectedSchemeId;

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
            onPressed: _showInfoDialog,
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

            // Test environment validation (Bank requirement)
            if (PaynimoConfig.isTestEnvironment) {
              if (amount < PaynimoConfig.minTestAmount) {
                return 'Test minimum amount is ₹${PaynimoConfig.minTestAmount}';
              }
              if (amount > PaynimoConfig.maxTestAmount) {
                return 'Test maximum amount is ₹${PaynimoConfig.maxTestAmount}';
              }
            } else {
              // Production validation
              if (amount < 100) {
                return 'Minimum amount is ₹100';
              }
              if (amount > 1000000) {
                return 'Maximum amount is ₹10,00,000';
              }
            }
            return null;
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
    final isValidAmount = PaynimoConfig.isTestEnvironment
        ? (_selectedAmount >= PaynimoConfig.minTestAmount && _selectedAmount <= PaynimoConfig.maxTestAmount)
        : (_selectedAmount >= 100 && _selectedAmount <= 1000000);
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
    // First check if MJDTA is available
    if (!_priceService.canPurchase) {
      _showMjdtaUnavailableDialog();
      return;
    }

    // Validate amount based on environment
    if (PaynimoConfig.isTestEnvironment) {
      if (_selectedAmount < PaynimoConfig.minTestAmount) {
        _showErrorDialog('Test minimum amount is ₹${PaynimoConfig.minTestAmount}');
        return;
      }
      if (_selectedAmount > PaynimoConfig.maxTestAmount) {
        _showErrorDialog('Test maximum amount is ₹${PaynimoConfig.maxTestAmount}');
        return;
      }
    } else {
      if (_selectedAmount < 100) {
        _showErrorDialog('Minimum investment amount is ₹100');
        return;
      }
      if (_selectedAmount > 1000000) {
        _showErrorDialog('Maximum investment amount is ₹10,00,000');
        return;
      }
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
      _showErrorDialog('Gold price not available. Please wait for price update or try again.');
      return;
    }

    final goldGrams = _selectedAmount / _currentPrice!.pricePerGram;

    // Show payment options dialog for demo
    _showPaymentOptionsDialog(goldGrams);
  }

  void _showPaymentOptionsDialog(double goldGrams) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Gold: ${goldGrams.toStringAsFixed(4)} grams (22K)'),
                  Text('Price: ₹${_currentPrice?.pricePerGram.toStringAsFixed(2) ?? 'N/A'}/gram'),
                  Text('Total: ₹${_selectedAmount.toStringAsFixed(2)}',
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Primary Payment Method - Paynimo Gateway
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showEnhancedPayment(goldGrams);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGold, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.credit_card, size: 32, color: AppColors.primaryGold),
                    const SizedBox(height: 8),
                    const Text(
                      'Paynimo Gateway',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      PaynimoConfig.isTestEnvironment ? 'Test Payment (₹1-10 only)' : 'Secure payment via Paynimo gateway',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Or choose UPI payment:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processRealPayment(PaymentMethod method, double goldGrams) async {
    Navigator.pop(context); // Close payment dialog

    try {
      // Set payment in progress to prevent auto logout
      _autoLogoutService.setPaymentInProgress(true);

      // Create payment request with method-specific UPI ID
      final request = PaymentRequest(
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: _selectedAmount,
        merchantName: UpiConfig.merchantName,
        merchantUpiId: UpiConfig.getUpiId(method),  // Get UPI ID based on payment method
        description: 'Gold Purchase - ${goldGrams.toStringAsFixed(3)}g',
        method: method,
      );

      // Show launching dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Launching ${method.displayName}...'),
              const SizedBox(height: 8),
              const Text('Complete payment in the app and return here',
                         style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      PaymentResponse response;

      // Launch the appropriate payment app
      switch (method) {
        case PaymentMethod.gpay:
          response = await _paymentService.payWithGPay(request);
          break;
        case PaymentMethod.phonepe:
          response = await _paymentService.payWithPhonePe(request);
          break;
        case PaymentMethod.upiIntent:
          response = await _paymentService.payWithUpiIntent(request);
          break;
        case PaymentMethod.qrCode:
          response = await _showQRCodePayment(request);
          break;
        default:
          response = PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'Payment method not supported',
          );
      }

      Navigator.pop(context); // Close launching dialog

      // Handle payment response based on status
      if (response.status == PaymentStatus.pending) {
        // Payment was initiated, now verify with user
        print('💳 Payment initiated, showing verification dialog...');

        final verificationResult = await _verificationService.showPaymentVerificationDialog(
          context: context,
          request: request,
          transactionId: response.transactionId,
        );

        // Handle verification result
        await _handleVerifiedPayment(verificationResult, method.displayName, goldGrams);

      } else if (response.status == PaymentStatus.success) {
        // Direct success (shouldn't happen with new flow, but handle it)
        await _handleVerifiedPayment(response, method.displayName, goldGrams);

      } else {
        // Payment failed or cancelled
        await NotificationTemplates.paymentFailed(
          transactionId: response.transactionId,
          amount: _selectedAmount,
          reason: response.errorMessage ?? 'Payment failed',
        );
        _showErrorDialog('Payment failed: ${response.errorMessage ?? 'Payment was not completed'}');

        // Payment process completed (failed), resume auto logout monitoring
        _autoLogoutService.setPaymentInProgress(false);
      }

    } catch (e) {
      Navigator.pop(context); // Close any open dialog
      _showErrorDialog('Payment error: ${e.toString()}');

      // Payment process completed (error), resume auto logout monitoring
      _autoLogoutService.setPaymentInProgress(false);
    }
  }

  Future<PaymentResponse> _showQRCodePayment(PaymentRequest request) async {
    // Show QR code payment dialog
    return await showDialog<PaymentResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan this QR code with any UPI app to pay:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code, size: 100, color: Colors.black54),
                  const SizedBox(height: 8),
                  Text('UPI ID: ${request.merchantUpiId}'),
                  Text('Amount: ₹${request.amount.toStringAsFixed(2)}'),
                  Text('Transaction: ${request.transactionId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment will be verified automatically after completion.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              PaymentResponse.cancelled(transactionId: request.transactionId),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              PaymentResponse.success(
                transactionId: request.transactionId,
                gatewayTransactionId: 'QR_${DateTime.now().millisecondsSinceEpoch}',
                additionalData: {
                  'method': 'qr_code',
                  'verified_at': DateTime.now().toIso8601String(),
                },
              ),
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    ) ?? PaymentResponse.cancelled(transactionId: request.transactionId);
  }

  Future<void> _showManualUpiPayment(double goldGrams) async {
    final amount = goldGrams * (_currentPrice?.pricePerGram ?? 0);
    final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primaryGold),
            const SizedBox(width: 8),
            const Text('Manual UPI Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay using any UPI app with these details:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentDetail('UPI ID:', 'sjlouismary@okicici'),
                  _buildPaymentDetail('Amount:', '₹${amount.toStringAsFixed(2)}'),
                  _buildPaymentDetail('Merchant:', 'V Murugan Gold Trading'),
                  _buildPaymentDetail('Transaction ID:', transactionId),
                  _buildPaymentDetail('Description:', 'Gold Purchase - ${goldGrams}g'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment will be verified automatically after completion.',
                      style: TextStyle(fontSize: 12),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAutomaticPaymentVerification(amount, goldGrams, transactionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAutomaticPaymentVerification(double amount, double goldGrams, String transactionId) async {
    // Show automatic verification dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Verifying payment automatically...'),
            const SizedBox(height: 8),
            Text('Transaction ID: $transactionId'),
          ],
        ),
      ),
    );

    // Simulate automatic payment verification
    await Future.delayed(const Duration(seconds: 3));

    // Close verification dialog
    Navigator.pop(context);

    // Automatically process the payment as successful
    final response = PaymentResponse.success(
      transactionId: transactionId,
      gatewayTransactionId: 'AUTO_${DateTime.now().millisecondsSinceEpoch}',
      additionalData: {
        'method': 'automatic_upi',
        'amount': amount,
        'gold_grams': goldGrams,
        'verified_at': DateTime.now().toIso8601String(),
      },
    );

    await _handleVerifiedPayment(response, 'UPI Payment', goldGrams);
  }

  Future<void> _handleVerifiedPayment(PaymentResponse response, String paymentMethod, double goldGrams) async {
    if (response.status == PaymentStatus.success) {
      print('🎉 Payment verified successful! Creating scheme...');

      // Get customer info for scheme creation
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      String? schemeId;
      if (customerId != null && customerId.isNotEmpty) {
        // Auto-create scheme for this purchase
        schemeId = await _getOrCreateAutoScheme(customerId, Map<String, String>.from(customerInfo));
        print('✅ Scheme created for verified payment: $schemeId');
      } else {
        print('⚠️ No customer ID found, skipping scheme creation');
      }

      // Save transaction to database (with scheme ID if available)
      await _saveTransaction(response, paymentMethod, goldGrams, schemeId: schemeId);

      // Create payment success notification
      await NotificationTemplates.paymentSuccess(
        transactionId: response.transactionId,
        amount: _selectedAmount,
        goldGrams: goldGrams,
        paymentMethod: paymentMethod,
      );

      _showRealSuccessDialog(paymentMethod, goldGrams, response, schemeId: schemeId);

    } else if (response.status == PaymentStatus.failed) {
      // Create payment failed notification
      await NotificationTemplates.paymentFailed(
        transactionId: response.transactionId,
        amount: _selectedAmount,
        reason: response.errorMessage ?? 'Payment verification failed',
      );
      _showErrorDialog('Payment failed: ${response.errorMessage ?? 'Payment verification failed'}');

    } else if (response.status == PaymentStatus.cancelled) {
      // Payment was cancelled by user
      _showErrorDialog('Payment was cancelled');

    } else {
      // Unknown status
      _showErrorDialog('Payment status unknown. Please check your bank statement and contact support if money was debited.');
    }

    // Payment process completed, resume auto logout monitoring
    _autoLogoutService.setPaymentInProgress(false);
  }

  Future<void> _saveTransaction(PaymentResponse response, String paymentMethod, double goldGrams, {String? schemeId}) async {
    try {
      // Save to local database
      await _portfolioService.saveTransaction(
        transactionId: response.transactionId,
        type: TransactionType.BUY,
        amount: _selectedAmount,
        metalGrams: goldGrams,
        metalPricePerGram: _currentPrice?.pricePerGram ?? 0,
        metalType: MetalType.gold,
        paymentMethod: paymentMethod,
        status: TransactionStatus.SUCCESS,
        gatewayTransactionId: response.gatewayTransactionId,
      );

      // Save to server with customer details
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: paymentMethod,
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      // Log analytics event
      await CustomerService.logEvent('gold_purchase_completed', {
        'transaction_id': response.transactionId,
        'amount': _selectedAmount,
        'gold_grams': goldGrams,
        'payment_method': paymentMethod,
        'gold_price_per_gram': _currentPrice?.pricePerGram ?? 0,
      });

      // Create payment success notification
      await NotificationTemplates.paymentSuccess(
        transactionId: response.transactionId,
        amount: _selectedAmount,
        goldGrams: goldGrams,
        paymentMethod: paymentMethod,
      );

      // Create gold purchase notification
      await NotificationTemplates.goldPurchased(
        goldGrams: goldGrams,
        pricePerGram: _currentPrice?.pricePerGram ?? 0,
        totalAmount: _selectedAmount,
      );

      print('Transaction saved successfully to both local and server');
    } catch (e) {
      print('Error saving transaction: $e');
      // Don't show error to user as payment was successful
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
            Text('Payment Failed'),
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

  void _showMjdtaUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Service Unavailable'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold purchases are currently unavailable because we cannot connect to MJDTA (Madras Jewellery and Diamond Traders Association) for live gold prices.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Please try again later when the MJDTA service is available.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'We only allow purchases with real-time MJDTA prices to ensure fair and accurate pricing.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _priceService.retryMjdtaConnection();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showRealSuccessDialog(String paymentMethod, double goldGrams, PaymentResponse response, {String? schemeId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Initiated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment via $paymentMethod has been initiated!',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gold to Purchase: ${goldGrams.toStringAsFixed(4)} grams'),
                  Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
                  Text('Transaction ID: ${response.transactionId}'),
                  if (response.gatewayTransactionId != null)
                    Text('UPI Ref: ${response.gatewayTransactionId}'),
                  if (schemeId != null)
                    Text('🆔 Scheme ID: $schemeId', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Please verify payment status in your bank app. Gold will be added to your portfolio once payment is confirmed.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Check Payment Status'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Go back to main screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    if (_currentPrice == null) {
      _showErrorDialog('Gold price not available. Please wait for price update or try again.');
      return;
    }

    final goldGrams = _selectedAmount / _currentPrice!.pricePerGram;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
            Text('Gold: ${goldGrams.toStringAsFixed(4)} grams'),
            Text('Price: ₹${_currentPrice?.pricePerGram.toStringAsFixed(2) ?? '0'}/gram'),
            const SizedBox(height: 16),
            const Text(
              'Note: This is a demo purchase. In production, this would integrate with a payment gateway.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Primary Payment Button (Paynimo Gateway)
          ElevatedButton(
            onPressed: () => _showEnhancedPayment(goldGrams),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: Text(PaynimoConfig.isTestEnvironment ? 'Test Payment (₹1-10)' : 'Pay with Paynimo'),
          ),
          // UPI Payment Options
          TextButton(
            onPressed: () => _showUpiPaymentOptions(goldGrams),
            child: const Text('UPI Options'),
          ),
        ],
      ),
    );
  }

  /// Show enhanced payment screen with Paynimo Gateway
  Future<void> _showEnhancedPayment(double goldGrams) async {
    Navigator.pop(context); // Close confirmation dialog

    try {
      final result = await Navigator.push<PaymentResponse>(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedPaymentScreen(
            amount: _selectedAmount,
            goldGrams: goldGrams,
            description: 'Gold Purchase - ${goldGrams.toStringAsFixed(3)}g',
            onPaymentComplete: (response) {
              _handleEnhancedPaymentResponse(response, goldGrams);
            },
          ),
        ),
      );

      if (result != null) {
        await _handleEnhancedPaymentResponse(result, goldGrams);
      }
    } catch (e) {
      print('❌ Enhanced payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show UPI payment options dialog
  Future<void> _showUpiPaymentOptions(double goldGrams) async {
    Navigator.pop(context); // Close confirmation dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI Payment Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose your preferred UPI payment method:'),
            const SizedBox(height: 20),
            _buildPaymentOption('🟢 Google Pay', 'Pay with GPay', () => _processRealPayment(PaymentMethod.gpay, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('🟣 PhonePe', 'Pay with PhonePe', () => _processRealPayment(PaymentMethod.phonepe, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('💳 UPI Apps', 'Pay with any UPI app', () => _processRealPayment(PaymentMethod.upiIntent, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('📱 QR Code', 'Scan QR to pay', () => _processRealPayment(PaymentMethod.qrCode, goldGrams)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Handle enhanced payment response
  Future<void> _handleEnhancedPaymentResponse(PaymentResponse response, double goldGrams) async {
    try {
      print('🎯 Enhanced payment response: ${response.status}');

      switch (response.status) {
        case PaymentStatus.success:
          await _processSuccessfulPayment(response, goldGrams);
          break;
        case PaymentStatus.pending:
          await _processPendingPayment(response, goldGrams);
          break;
        case PaymentStatus.failed:
          _showPaymentFailedDialog(response);
          break;
        case PaymentStatus.cancelled:
          _showPaymentCancelledDialog();
          break;
        case PaymentStatus.timeout:
          _showPaymentTimeoutDialog(response);
          break;
      }
    } catch (e) {
      print('❌ Error handling enhanced payment response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process successful payment
  Future<void> _processSuccessfulPayment(PaymentResponse response, double goldGrams) async {
    try {
      // Save transaction
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: response.additionalData?['method'] ?? 'Enhanced Payment',
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      // Update scheme if applicable
      if (_selectedSchemeId != null) {
        await _updateSchemePayment(
          _selectedSchemeId!,
          _selectedAmount,
          goldGrams,
          response.additionalData?['method'] ?? 'Enhanced Payment',
          response.transactionId,
        );
      }

      // Show success dialog
      if (mounted) {
        _showPaymentSuccessDialog(response, goldGrams);
      }

    } catch (e) {
      print('❌ Error processing successful payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process pending payment
  Future<void> _processPendingPayment(PaymentResponse response, double goldGrams) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pending, color: Colors.orange),
              SizedBox(width: 8),
              Text('Payment Pending'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your payment is being processed.'),
              const SizedBox(height: 8),
              Text('Transaction ID: ${response.transactionId}'),
              if (response.additionalData?['message'] != null) ...[
                const SizedBox(height: 8),
                Text(response.additionalData!['message']),
              ],
              const SizedBox(height: 16),
              const Text(
                'You will receive a notification once the payment is confirmed.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Check payment status
                final status = await _enhancedPaymentService.verifyPaymentStatus(
                  response.transactionId,
                  PaymentMethod.paynimoCard, // Default for verification
                );
                await _handleEnhancedPaymentResponse(status, goldGrams);
              },
              child: const Text('Check Status'),
            ),
          ],
        ),
      );
    }
  }

  /// Show payment success dialog
  void _showPaymentSuccessDialog(PaymentResponse response, double goldGrams) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your gold purchase has been completed successfully.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount Paid: ₹${_selectedAmount.toStringAsFixed(2)}'),
                  Text('Gold Purchased: ${goldGrams.toStringAsFixed(4)}g'),
                  Text('Transaction ID: ${response.transactionId}'),
                  if (response.gatewayTransactionId != null)
                    Text('Gateway ID: ${response.gatewayTransactionId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your gold has been added to your portfolio.',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Optionally navigate to portfolio
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Portfolio'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  /// Show payment failed dialog
  void _showPaymentFailedDialog(PaymentResponse response) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Payment Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your payment could not be processed.'),
              if (response.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text('Reason: ${response.errorMessage}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Please try again or contact support if the issue persists.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentDialog(); // Show payment dialog again
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  /// Show payment cancelled dialog
  void _showPaymentCancelledDialog() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Show payment timeout dialog
  void _showPaymentTimeoutDialog(PaymentResponse response) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange),
              SizedBox(width: 8),
              Text('Payment Timeout'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment verification timed out.'),
              const SizedBox(height: 8),
              Text('Transaction ID: ${response.transactionId}'),
              const SizedBox(height: 16),
              const Text(
                'Please check your bank account or payment app for transaction status.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Retry status check
                final status = await _enhancedPaymentService.verifyPaymentStatus(
                  response.transactionId,
                  PaymentMethod.paynimoCard,
                );
                final goldGrams = _selectedAmount / (_currentPrice?.pricePerGram ?? 1);
                await _handleEnhancedPaymentResponse(status, goldGrams);
              },
              child: const Text('Check Again'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _completePurchase(double goldGrams) async {
    print('🚀 _completePurchase called!');
    print('   Gold Grams: $goldGrams');
    print('   Selected Amount: $_selectedAmount');

    try {
      // Close the dialog first
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing purchase...'),
            ],
          ),
        ),
      );

      print('📝 Step 1: Getting customer info...');
      // Get customer info
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      print('   Customer Info: $customerInfo');
      print('   Customer ID: $customerId');

      if (customerId == null || customerId.isEmpty) {
        print('❌ No customer ID found!');
        Navigator.pop(context); // Close loading
        _showErrorDialog('Please login with a registered account to buy gold.');
        return;
      }

      print('📝 Step 2: Creating auto scheme...');
      // Auto-create or get existing scheme
      String? schemeId = await _getOrCreateAutoScheme(customerId, Map<String, String>.from(customerInfo));

      print('📝 Step 3: Checking scheme creation result...');
      print('   Scheme ID: $schemeId');

      if (schemeId == null) {
        print('❌ Scheme creation failed!');
        Navigator.pop(context); // Close loading
        _showErrorDialog('Failed to create scheme. Please try again.');
        return;
      }

      print('✅ Scheme created successfully: $schemeId');
      print('📝 Step 4: Generating transaction ID...');
      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      print('   Transaction ID: $transactionId');

      // Create transaction data with scheme ID
      final transactionData = {
        'transaction_id': transactionId,
        'customer_id': customerId,
        'scheme_id': schemeId,
        'amount': _selectedAmount,
        'gold_grams': goldGrams,
        'gold_price': _currentPrice?.pricePerGram ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
        'payment_method': 'Demo',
      };

      // Save transaction with customer data
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: 'Demo',
        status: 'completed',
        gatewayTransactionId: transactionId,
      );

      // Update scheme with payment
      await _updateSchemePayment(schemeId, _selectedAmount, goldGrams, 'Demo', transactionId);

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with scheme info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase Successful! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully purchased ${goldGrams.toStringAsFixed(4)} grams of gold for ₹${_selectedAmount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🆔 Scheme Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Scheme ID: $schemeId'),
                    Text('Transaction ID: $transactionId'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Go back to main screen
              },
              child: const Text('View Portfolio'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buy More'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase Failed'),
          content: Text('Failed to complete purchase: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Digital Gold'),
        content: const Text(
          '• 22K pure digital gold\n'
          '• Stored securely in digital vault\n'
          '• Real-time price updates\n'
          '• Minimum investment: ₹100\n'
          '• Maximum investment: ₹10,00,000\n'
          '• Instant purchase confirmation'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Auto-create scheme for first-time buyers or get existing scheme
  Future<String?> _getOrCreateAutoScheme(String customerId, Map<String, String> customerInfo) async {
    print('🎯 _getOrCreateAutoScheme called with:');
    print('   Customer ID: $customerId');
    print('   Customer Info: $customerInfo');
    print('   Selected Amount: $_selectedAmount');

    try {
      final customerPhone = customerInfo['phone'] ?? '';
      final customerName = customerInfo['name'] ?? '';

      // Check if customer already has an active gold scheme
      final existingScheme = await _schemeService.getCustomerSchemeByMetal(customerPhone, MetalType.gold);

      if (existingScheme != null) {
        print('✅ Found existing gold scheme: ${existingScheme.schemeId}');
        return existingScheme.schemeId;
      }

      print('📝 Creating new GOLDPLUS scheme...');
      // Create new GOLDPLUS scheme with 15 months duration
      final newScheme = await _schemeService.createScheme(
        customerPhone: customerPhone,
        customerName: customerName,
        monthlyAmount: _selectedAmount, // Use current purchase as monthly amount
        metalType: MetalType.gold,
        durationMonths: 15, // GOLDPLUS is 15 months
      );

      print('✅ Created new GOLDPLUS scheme: ${newScheme.schemeId}');
      return newScheme.schemeId;
    } catch (e) {
      print('❌ Error creating/getting gold scheme: $e');
      return null;
    }
  }

  // Update scheme with payment
  Future<void> _updateSchemePayment(String schemeId, double amount, double goldGrams, String paymentMethod, String transactionId) async {
    try {
      print('💰 Recording payment for scheme $schemeId: ₹$amount for ${goldGrams}g gold');

      // Get the current gold price per gram
      final goldPricePerGram = _currentPrice?.pricePerGram ?? 0.0;

      // Find the next pending installment for this scheme
      // For now, we'll create a dummy installment ID - in production this would be retrieved from database
      final installmentId = '${schemeId}_INST_01'; // This should be the actual next pending installment

      // Pay the installment
      await _schemeService.payInstallment(
        installmentId: installmentId,
        metalPricePerGram: goldPricePerGram,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      print('✅ Installment payment recorded successfully');
    } catch (e) {
      print('❌ Error updating scheme payment: $e');
    }
  }

}
