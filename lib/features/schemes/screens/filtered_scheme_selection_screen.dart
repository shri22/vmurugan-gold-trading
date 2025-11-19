import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/enums/metal_type.dart';
import '../models/enhanced_scheme_model.dart';

class FilteredSchemeSelectionScreen extends StatefulWidget {
  final MetalType metalType;
  final String? customerId;
  final String? customerPhone;
  final String? customerName;

  const FilteredSchemeSelectionScreen({
    super.key,
    required this.metalType,
    this.customerId,
    this.customerPhone,
    this.customerName,
  });

  @override
  State<FilteredSchemeSelectionScreen> createState() => _FilteredSchemeSelectionScreenState();
}

class _FilteredSchemeSelectionScreenState extends State<FilteredSchemeSelectionScreen> {
  List<EnhancedSchemeModel> _schemes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate loading schemes based on metal type
      await Future.delayed(const Duration(seconds: 1));
      
      _schemes = _generateSampleSchemes();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load schemes: $e';
        _isLoading = false;
      });
    }
  }

  List<EnhancedSchemeModel> _generateSampleSchemes() {
    final metalName = widget.metalType == MetalType.gold ? 'Gold' : 'Silver';
    final baseAmount = widget.metalType == MetalType.gold ? 3000.0 : 1500.0;
    
    return [
      EnhancedSchemeModel(
        id: '${widget.metalType.name}_scheme_1',
        name: '$metalName Plus 15 Months',
        description: 'Invest monthly and get bonus $metalName on completion',
        metalType: widget.metalType,
        durationMonths: 15,
        monthlyAmount: baseAmount,
        bonusPercentage: 10.0,
        minAge: 18,
        maxAge: 65,
        isActive: true,
        features: [
          'Monthly investment of ₹${baseAmount.toStringAsFixed(0)}',
          '10% bonus $metalName on completion',
          'Flexible payment dates',
          'Digital certificate',
          'Free storage',
        ],
        benefits: [
          'Systematic investment approach',
          'Bonus $metalName reward',
          'No storage charges',
          'Easy online management',
        ],
        terms: [
          'Minimum 15 monthly payments required',
          'Bonus applicable only on completion',
          'Early withdrawal charges may apply',
          'Subject to current $metalName prices',
        ],
      ),
      EnhancedSchemeModel(
        id: '${widget.metalType.name}_scheme_2',
        name: '$metalName Saver 12 Months',
        description: 'Short-term $metalName investment scheme',
        metalType: widget.metalType,
        durationMonths: 12,
        monthlyAmount: baseAmount * 0.8,
        bonusPercentage: 8.0,
        minAge: 18,
        maxAge: 70,
        isActive: true,
        features: [
          'Monthly investment of ₹${(baseAmount * 0.8).toStringAsFixed(0)}',
          '8% bonus $metalName on completion',
          'Shorter commitment period',
          'Digital certificate',
          'Free storage',
        ],
        benefits: [
          'Quick investment cycle',
          'Lower monthly commitment',
          'Bonus $metalName reward',
          'Flexible payment options',
        ],
        terms: [
          'Minimum 12 monthly payments required',
          'Bonus applicable only on completion',
          'Early withdrawal charges may apply',
          'Subject to current $metalName prices',
        ],
      ),
      EnhancedSchemeModel(
        id: '${widget.metalType.name}_scheme_3',
        name: '$metalName Premium 24 Months',
        description: 'Long-term premium $metalName investment',
        metalType: widget.metalType,
        durationMonths: 24,
        monthlyAmount: baseAmount * 1.5,
        bonusPercentage: 15.0,
        minAge: 21,
        maxAge: 60,
        isActive: true,
        features: [
          'Monthly investment of ₹${(baseAmount * 1.5).toStringAsFixed(0)}',
          '15% bonus $metalName on completion',
          'Premium investment tier',
          'Priority customer support',
          'Free storage and insurance',
        ],
        benefits: [
          'Higher bonus percentage',
          'Premium customer benefits',
          'Insurance coverage included',
          'Priority support',
        ],
        terms: [
          'Minimum 24 monthly payments required',
          'Higher monthly commitment',
          'Bonus applicable only on completion',
          'Premium tier benefits included',
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.metalType == MetalType.gold ? 'Gold' : 'Silver'} Schemes',
          style: AppTypography.appBarTitle,
        ),
        backgroundColor: widget.metalType == MetalType.gold 
            ? AppColors.primaryGold 
            : AppColors.silver,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Retry',
              onPressed: _loadSchemes,
              type: ButtonType.primary,
            ),
          ],
        ),
      );
    }

    if (_schemes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No schemes available',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later for new schemes',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schemes.length,
      itemBuilder: (context, index) {
        final scheme = _schemes[index];
        return _buildSchemeCard(scheme);
      },
    );
  }

  Widget _buildSchemeCard(EnhancedSchemeModel scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.metalType == MetalType.gold 
                        ? AppColors.primaryGold 
                        : AppColors.silver,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${scheme.bonusPercentage.toStringAsFixed(0)}% Bonus',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  widget.metalType == MetalType.gold 
                      ? Icons.diamond 
                      : Icons.circle,
                  color: widget.metalType == MetalType.gold 
                      ? AppColors.primaryGold 
                      : AppColors.silver,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title and Description
            Text(
              scheme.name,
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              scheme.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Key Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Duration',
                    '${scheme.durationMonths} Months',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Monthly',
                    '₹${scheme.monthlyAmount.toStringAsFixed(0)}',
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Features
            Text(
              'Key Features:',
              style: AppTypography.titleSmall,
            ),
            const SizedBox(height: 8),
            ...scheme.features.take(3).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Select This Scheme',
                onPressed: () => _selectScheme(scheme),
                type: ButtonType.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTypography.titleSmall,
            ),
          ],
        ),
      ],
    );
  }

  void _selectScheme(EnhancedSchemeModel scheme) {
    // Navigate to scheme enrollment or return selected scheme
    Navigator.pop(context, scheme);
  }
}
