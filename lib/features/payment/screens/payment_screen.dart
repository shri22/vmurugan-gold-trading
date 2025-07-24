import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/upi_payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final double goldGrams;
  final double pricePerGram;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.goldGrams,
    required this.pricePerGram,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final UpiPaymentService _paymentService = UpiPaymentService();
  List<PaymentMethod> _availableMethods = [];
  PaymentMethod? _selectedMethod;
  bool _isLoading = false;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadAvailablePaymentMethods();
  }

  Future<void> _loadAvailablePaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      final methods = await _paymentService.getAvailablePaymentMethods();
      setState(() {
        _availableMethods = methods;
        _selectedMethod = methods.isNotEmpty ? methods.first : null;
      });
    } catch (e) {
      print('Error loading payment methods: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      final request = PaymentRequest(
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.amount,
        merchantName: UpiConfig.merchantName,
        merchantUpiId: UpiConfig.getUpiId(_selectedMethod!),
        description: 'Gold Purchase - ${widget.goldGrams.toStringAsFixed(3)}g',
        method: _selectedMethod!,
      );

      PaymentResponse response;
      
      switch (_selectedMethod!) {
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
          // TODO: Implement QR code payment
          response = PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'QR Code payment not implemented yet',
          );
          break;
      }

      _handlePaymentResponse(response);
    } catch (e) {
      _showErrorDialog('Payment failed: ${e.toString()}');
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  void _handlePaymentResponse(PaymentResponse response) {
    switch (response.status) {
      case PaymentStatus.success:
        _showSuccessDialog(response);
        break;
      case PaymentStatus.failed:
        _showErrorDialog(response.errorMessage ?? 'Payment failed');
        break;
      case PaymentStatus.cancelled:
        _showInfoDialog('Payment was cancelled');
        break;
      default:
        _showErrorDialog('Unknown payment status');
    }
  }

  void _showSuccessDialog(PaymentResponse response) {
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
            Text('Transaction ID: ${response.transactionId}'),
            if (response.gatewayTransactionId != null)
              Text('Gateway ID: ${response.gatewayTransactionId}'),
            const SizedBox(height: 16),
            Text('Gold Purchased: ${widget.goldGrams.toStringAsFixed(3)} grams'),
            Text('Amount Paid: ₹${widget.amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(response); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue, size: 32),
            SizedBox(width: 12),
            Text('Information'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  _buildPaymentMethods(),
                  const Spacer(),
                  _buildPayButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gold (22K)'),
              Text('${widget.goldGrams.toStringAsFixed(3)} grams'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price per gram'),
              Text('₹${widget.pricePerGram.toStringAsFixed(2)}'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._availableMethods.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedMethod == method ? const Color(0xFFFFD700) : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          method.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(method.displayName),
        trailing: Radio<PaymentMethod>(
          value: method,
          groupValue: _selectedMethod,
          onChanged: (value) => setState(() => _selectedMethod = value),
          activeColor: const Color(0xFFFFD700),
        ),
        onTap: () => setState(() => _selectedMethod = method),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedMethod != null && !_isProcessingPayment
            ? _processPayment
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Text(
                'Pay ₹${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
