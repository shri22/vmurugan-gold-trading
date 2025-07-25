import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';

class SchemeCreationScreen extends StatefulWidget {
  const SchemeCreationScreen({super.key});

  @override
  State<SchemeCreationScreen> createState() => _SchemeCreationScreenState();
}

class _SchemeCreationScreenState extends State<SchemeCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyAmountController = TextEditingController();
  final _durationController = TextEditingController();
  
  String _selectedSchemeType = 'MONTHLY_SAVINGS';
  bool _isLoading = false;

  final List<Map<String, String>> _schemeTypes = [
    {'value': 'MONTHLY_SAVINGS', 'label': 'Monthly Gold Savings'},
    {'value': 'FESTIVAL_SPECIAL', 'label': 'Festival Special Scheme'},
    {'value': 'WEDDING_PLAN', 'label': 'Wedding Gold Plan'},
    {'value': 'CHILD_FUTURE', 'label': 'Child Future Plan'},
  ];

  @override
  void dispose() {
    _monthlyAmountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _createScheme() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get customer information
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];
      
      if (customerId == null) {
        _showErrorDialog('Customer ID not found. Please register first.');
        return;
      }

      // Generate scheme ID
      final schemeId = await ApiService.generateSchemeId(customerId);
      
      // Save scheme
      final result = await ApiService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? '',
        customerName: customerInfo['name'] ?? '',
        monthlyAmount: double.parse(_monthlyAmountController.text),
        durationMonths: int.parse(_durationController.text),
        schemeType: _selectedSchemeType,
        status: 'ACTIVE',
      );

      if (result['success']) {
        _showSuccessDialog(schemeId, result);
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to create scheme');
      }
    } catch (e) {
      _showErrorDialog('Error creating scheme: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String schemeId, Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Scheme Created!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your gold investment scheme has been created successfully!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Scheme ID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schemeId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copySchemeId(schemeId),
                          icon: Icon(
                            Icons.copy,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          tooltip: 'Copy Scheme ID',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save this Scheme ID for future reference and monthly payments.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scheme Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('💰 Monthly Amount: ₹${_monthlyAmountController.text}'),
                  Text('📅 Duration: ${_durationController.text} months'),
                  Text('🎯 Total Target: ₹${(double.parse(_monthlyAmountController.text) * int.parse(_durationController.text)).toStringAsFixed(0)}'),
                  Text('📋 Type: ${_schemeTypes.firstWhere((type) => type['value'] == _selectedSchemeType)['label']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _copySchemeId(String schemeId) {
    Clipboard.setData(ClipboardData(text: schemeId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheme ID $schemeId copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Scheme'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings, color: AppColors.primaryGold),
                        const SizedBox(width: 8),
                        const Text(
                          'Gold Investment Scheme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a systematic gold investment plan with monthly contributions.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Scheme Type
              const Text(
                'Scheme Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedSchemeType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _schemeTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSchemeType = value!;
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Monthly Amount
              const Text(
                'Monthly Amount (₹)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _monthlyAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  hintText: 'Enter monthly amount',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter monthly amount';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount < 500) {
                    return 'Minimum amount is ₹500';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Duration
              const Text(
                'Duration (Months)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_month),
                  hintText: 'Enter duration in months',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  final months = int.tryParse(value);
                  if (months == null || months < 6 || months > 60) {
                    return 'Duration must be between 6-60 months';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createScheme,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Create Scheme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
