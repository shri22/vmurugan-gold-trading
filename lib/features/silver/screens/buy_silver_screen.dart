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

class BuySilverScreen extends StatefulWidget {
  const BuySilverScreen({super.key});

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

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buy Silver'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceCard(),
                    const SizedBox(height: 24),
                    _buildAmountInput(),
                    const SizedBox(height: 24),
                    _buildSchemeSelection(),
                    const SizedBox(height: 32),
                    _buildBuyButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPriceCard() {
    if (_currentPrice == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Loading silver price...'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Silver Price',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_currentPrice!.pricePerGram.toStringAsFixed(2)}/gram',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_currentPrice!.lastUpdated != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last updated: ${_formatDateTime(_currentPrice!.lastUpdated!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
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
                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Silver purchases are temporarily unavailable. Please try again later.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        GradientButton(
          text: canPurchase ? 'Proceed to Payment' : 'Service Unavailable',
          onPressed: (isValidAmount && canPurchase) ? _handleBuySilver : null,
          gradient: canPurchase ? AppColors.goldGreenGradient : LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade500],
          ),
          icon: canPurchase ? Icons.payment : Icons.warning,
          isFullWidth: true,
        ),
      ],
    );
  }

  Future<void> _handleBuySilver() async {
    // First check if silver service is available
    if (!_priceService.canPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silver purchases are currently unavailable. Please try again later.'),
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
          const SnackBar(content: Text('Registration required to buy silver')),
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
        metalGrams: silverGrams,
        metalType: 'silver',
        onPaymentComplete: _handlePaymentComplete,
      ),
    );
  }



  void _handlePaymentComplete(PaymentResponse response) {
    if (response.status == PaymentStatus.success) {
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
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
