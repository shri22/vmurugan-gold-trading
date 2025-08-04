import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/utils/responsive.dart' hide AppSpacing, AppBorderRadius;
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../services/silver_price_service.dart';
import '../models/silver_price_model.dart';
import '../../payment/services/upi_payment_service.dart';
import '../../payment/services/payment_verification_service.dart';
import '../../payment/models/payment_model.dart';
import '../../schemes/services/scheme_management_service.dart';
import '../../schemes/models/scheme_installment_model.dart';
import '../../portfolio/services/portfolio_service.dart';
import '../../portfolio/models/portfolio_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/customer_registration_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

class BuySilverScreen extends StatefulWidget {
  const BuySilverScreen({super.key});

  @override
  State<BuySilverScreen> createState() => _BuySilverScreenState();
}

class _BuySilverScreenState extends State<BuySilverScreen> {
  final SilverPriceService _priceService = SilverPriceService();
  final UpiPaymentService _paymentService = UpiPaymentService();
  final PaymentVerificationService _verificationService = PaymentVerificationService();
  final PortfolioService _portfolioService = PortfolioService();
  final SchemeManagementService _schemeService = SchemeManagementService();
  final TextEditingController _amountController = TextEditingController();

  SilverPriceModel? _currentPrice;
  double _selectedAmount = 2000.0;
  bool _isCustomAmount = false;

  // Predefined amount options
  final List<double> _predefinedAmounts = [500, 1000, 2000, 5000, 10000];

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
    final silverQuantity = _currentPrice != null
        ? _selectedAmount / _currentPrice!.pricePerGram
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Silver'),
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
                    'Current Silver Price',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  '₹${_currentPrice!.pricePerGram.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'per gram',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Last updated: ${_formatTime(_currentPrice!.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Investment Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Predefined amounts
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _predefinedAmounts.map((amount) {
                final isSelected = !_isCustomAmount && _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                      _isCustomAmount = false;
                      _amountController.text = amount.toStringAsFixed(0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey[300] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      border: Border.all(
                        color: isSelected ? Colors.grey[600]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Custom amount input
            Text(
              'Or enter custom amount:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _amountController,
              label: 'Amount (₹)',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                setState(() {
                  _selectedAmount = amount;
                  _isCustomAmount = amount > 0 && !_predefinedAmounts.contains(amount);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverQuantityPreview(double silverQuantity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You will get',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${silverQuantity.toStringAsFixed(3)} grams',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'of Silver',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
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
            const SizedBox(height: AppSpacing.lg),
            _buildSummaryRow('Investment Amount', '₹${_selectedAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Silver Rate', '₹${_currentPrice?.pricePerGram.toStringAsFixed(2) ?? '0.00'}/gram'),
            _buildSummaryRow('Silver Quantity', '${silverQuantity.toStringAsFixed(3)} grams'),
            const Divider(height: AppSpacing.lg),
            _buildSummaryRow(
              'Total Amount',
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.grey[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Buy Silver',
        onPressed: _handleBuySilver,
        type: ButtonType.primary,
        icon: Icons.shopping_cart,
      ),
    );
  }
  Future<void> _handleBuySilver() async {
    // First check if MJDTA is available
    if (!_priceService.canPurchase) {
      _showMjdtaUnavailableDialog();
      return;
    }

    if (_selectedAmount < 100) {
      _showErrorDialog('Minimum investment amount is ₹100');
      return;
    }

    if (_selectedAmount > 1000000) {
      _showErrorDialog('Maximum investment amount is ₹10,00,000');
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

    // Navigate to payment screen
    _navigateToPayment();
  }

  Future<void> _navigateToPayment() async {
    final silverGrams = _selectedAmount / (_currentPrice?.pricePerGram ?? 1);

    // Show payment options dialog for demo
    _showPaymentOptionsDialog(silverGrams);
  }

  void _showPaymentOptionsDialog(double silverGrams) {
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
                children: [
                  Text(
                    'Silver Purchase Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
                  Text('Silver: ${silverGrams.toStringAsFixed(3)} grams'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentOption('🟢 Google Pay', 'Pay with GPay', () => _processRealPayment(PaymentMethod.gpay, silverGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('🟣 PhonePe', 'Pay with PhonePe', () => _processRealPayment(PaymentMethod.phonepe, silverGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('💳 UPI Apps', 'Pay with any UPI app', () => _processRealPayment(PaymentMethod.upiIntent, silverGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('📱 QR Code', 'Scan QR to pay', () => _processRealPayment(PaymentMethod.qrCode, silverGrams)),
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

  Future<void> _processRealPayment(PaymentMethod method, double silverGrams) async {
    Navigator.pop(context); // Close payment dialog

    try {
      // Create payment request with method-specific UPI ID
      final request = PaymentRequest(
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: _selectedAmount,
        merchantName: UpiConfig.merchantName,
        merchantUpiId: UpiConfig.getUpiId(method),  // Get UPI ID based on payment method
        description: 'Silver Purchase - ${silverGrams.toStringAsFixed(3)}g',
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
              const Text(
                'Please complete the payment in the app that opens',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
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
        await _handleVerifiedPayment(verificationResult, method.displayName, silverGrams);

      } else if (response.status == PaymentStatus.success) {
        // Direct success (shouldn't happen with new flow, but handle it)
        await _handleVerifiedPayment(response, method.displayName, silverGrams);

      } else {
        // Payment failed or cancelled
        await NotificationTemplates.paymentFailed(
          transactionId: response.transactionId,
          amount: _selectedAmount,
          reason: response.errorMessage ?? 'Payment was not completed',
        );
        _showErrorDialog('Payment failed: ${response.errorMessage ?? 'Payment was not completed'}');
      }

    } catch (e) {
      Navigator.pop(context); // Close any open dialog
      _showErrorDialog('Payment error: ${e.toString()}');
    }
  }

  Future<void> _handleVerifiedPayment(PaymentResponse response, String paymentMethod, double silverGrams) async {
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
      await _saveTransaction(response, paymentMethod, silverGrams, schemeId: schemeId);
      _showRealSuccessDialog(paymentMethod, silverGrams, response, schemeId: schemeId);

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
  }

  Future<void> _saveTransaction(PaymentResponse response, String paymentMethod, double silverGrams, {String? schemeId}) async {
    try {
      // Save to local database
      await _portfolioService.saveTransaction(
        transactionId: response.transactionId,
        type: TransactionType.BUY,
        amount: _selectedAmount,
        metalGrams: silverGrams,
        metalPricePerGram: _currentPrice?.pricePerGram ?? 0,
        metalType: MetalType.silver,
        paymentMethod: paymentMethod,
        status: TransactionStatus.SUCCESS,
        gatewayTransactionId: response.gatewayTransactionId,
      );

      // Save to server with customer details (updated for metal type)
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: silverGrams, // Using goldGrams field for metal grams (backward compatibility)
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0, // Using goldPricePerGram for metal price
        paymentMethod: paymentMethod,
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      // Log analytics event
      await CustomerService.logEvent('silver_purchase_completed', {
        'transaction_id': response.transactionId,
        'amount': _selectedAmount,
        'silver_grams': silverGrams,
        'payment_method': paymentMethod,
        'silver_price_per_gram': _currentPrice?.pricePerGram ?? 0,
      });

      // Create success notification (using goldGrams as 0 for silver)
      await NotificationTemplates.paymentSuccess(
        transactionId: response.transactionId,
        amount: _selectedAmount,
        goldGrams: 0, // This is silver purchase, so goldGrams is 0
        paymentMethod: paymentMethod,
      );

      print('✅ Transaction saved successfully');
    } catch (e) {
      print('❌ Error saving transaction: $e');
      // Don't throw error here as payment was successful
    }
  }
  void _showRealSuccessDialog(String paymentMethod, double silverGrams, PaymentResponse response, {String? schemeId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Payment Successful!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎉 Your silver purchase was successful!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction ID: ${response.transactionId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
                  Text('Silver: ${silverGrams.toStringAsFixed(3)} grams'),
                  Text('Payment Method: $paymentMethod'),
                  if (schemeId != null) Text('Scheme ID: $schemeId'),
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
                '⚠️ Please verify payment status in your bank app. Silver will be added to your portfolio once payment is confirmed.',
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
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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
        title: const Text('Service Unavailable'),
        content: const Text(
          'Silver trading is temporarily unavailable. Please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Silver Investment'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digital Silver Investment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Invest in pure silver digitally'),
              Text('• Real-time market prices'),
              Text('• Secure storage and insurance'),
              Text('• Easy buying and selling'),
              Text('• No making charges'),
              SizedBox(height: 12),
              Text(
                'Investment Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Minimum investment: ₹100'),
              Text('• Maximum investment: ₹10,00,000'),
              Text('• Live MJDTA prices'),
              Text('• Instant portfolio updates'),
            ],
          ),
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<String?> _getOrCreateAutoScheme(String customerId, Map<String, String> customerInfo) async {
    print('🎯 _getOrCreateAutoScheme called for SILVER with:');
    print('   Customer ID: $customerId');
    print('   Customer Info: $customerInfo');
    print('   Selected Amount: $_selectedAmount');

    try {
      final customerPhone = customerInfo['phone'] ?? '';
      final customerName = customerInfo['name'] ?? '';

      // Check if customer already has an active silver scheme
      final existingScheme = await _schemeService.getCustomerSchemeByMetal(customerPhone, MetalType.silver);

      if (existingScheme != null) {
        print('✅ Found existing silver scheme: ${existingScheme.schemeId}');
        return existingScheme.schemeId;
      }

      print('📝 Creating new SILVERPLUS scheme...');
      // Create new SILVERPLUS scheme with 15 months duration
      final newScheme = await _schemeService.createScheme(
        customerPhone: customerPhone,
        customerName: customerName,
        monthlyAmount: _selectedAmount, // Use current purchase as monthly amount
        metalType: MetalType.silver,
        durationMonths: 15, // SILVERPLUS is 15 months
      );

      print('✅ Created new SILVERPLUS scheme: ${newScheme.schemeId}');
      return newScheme.schemeId;
    } catch (e) {
      print('❌ Error creating/getting silver scheme: $e');
      return null;
    }
  }

  // Update scheme with payment
  Future<void> _updateSchemePayment(String schemeId, double amount, double silverGrams, String paymentMethod, String transactionId) async {
    try {
      print('💰 Recording payment for scheme $schemeId: ₹$amount for ${silverGrams}g silver');

      // Get the current silver price per gram
      final silverPricePerGram = _currentPrice?.pricePerGram ?? 0.0;

      // Find the next pending installment for this scheme
      // For now, we'll create a dummy installment ID - in production this would be retrieved from database
      final installmentId = '${schemeId}_INST_01'; // This should be the actual next pending installment

      // Pay the installment
      await _schemeService.payInstallment(
        installmentId: installmentId,
        metalPricePerGram: silverPricePerGram,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      print('✅ Installment payment recorded successfully');
    } catch (e) {
      print('❌ Error updating scheme payment: $e');
    }
  }

}
