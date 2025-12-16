import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/enums/metal_type.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/secure_http_client.dart';
import '../services/scheme_payment_validation_service.dart';
import '../models/enhanced_scheme_model.dart';
import 'filtered_scheme_selection_screen.dart';
import '../../gold/screens/buy_gold_screen.dart';
import '../../silver/screens/buy_silver_screen.dart';
import '../../gold/services/gold_scheme_service.dart';
import '../../gold/models/gold_scheme_model.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final MetalType metalType;
  final String? customerPhone;
  final String? customerName;

  const SchemeDetailsScreen({
    super.key,
    required this.metalType,
    this.customerPhone,
    this.customerName,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  List<SchemeDetailModel> _schemes = [];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  void _loadSchemes() {
    final metalName = widget.metalType == MetalType.gold ? 'Gold' : 'Silver';
    final baseColor = widget.metalType == MetalType.gold 
        ? AppColors.primaryGold 
        : AppColors.silver;

    _schemes = [
      SchemeDetailModel(
        id: '${widget.metalType.name}_plus',
        name: '${metalName}Plus',
        subtitle: '12 months fixed duration',
        duration: '12 months fixed',
        valueAddition: '97% value addition',
        gstInfo: '3% GST on redemption only',
        isPremium: true,
        color: baseColor,
        features: [
          '12 months fixed duration',
          '97% value addition',
          '3% GST on redemption only',
          'Premium tier benefits',
          'Digital certificate',
        ],
      ),
      SchemeDetailModel(
        id: '${widget.metalType.name}_flexi',
        name: '${metalName}Flexi',
        subtitle: 'Flexible duration',
        duration: 'Flexible duration',
        valueAddition: '97% value addition',
        gstInfo: '3% GST on redemption only',
        isPremium: false,
        color: baseColor,
        features: [
          'Flexible duration',
          '97% value addition',
          '3% GST on redemption only',
          'Easy withdrawal options',
          'Digital certificate',
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metalName = widget.metalType == MetalType.gold ? 'Gold' : 'Silver';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          '$metalName Investment Schemes',
          style: AppTypography.appBarTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header Card
            _buildHeaderCard(metalName),
            const SizedBox(height: AppSpacing.xl),
            
            // Scheme Cards
            ..._schemes.map((scheme) => _buildSchemeCard(scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String metalName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Star Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Title
          Text(
            '$metalName Investment Options',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          
          // Subtitle
          Text(
            'Choose from 2 ${metalName.toLowerCase()} investment schemes',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(SchemeDetailModel scheme) {
    // Define gradient based on metal type
    LinearGradient gradient;
    if (widget.metalType == MetalType.gold) {
      gradient = AppColors.goldGreenGradient;
    } else {
      gradient = AppColors.silverGreenGradient;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    scheme.isPremium ? 'PLUS' : 'FLEXI',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Scheme Name
            Text(
              scheme.name,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // Subtitle
            Text(
              scheme.subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Features
            _buildFeatureItem(Icons.schedule, scheme.duration),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureItem(Icons.trending_up, scheme.valueAddition),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureItem(Icons.receipt, scheme.gstInfo),
            const SizedBox(height: AppSpacing.xl),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showSchemeDetails(scheme),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                    child: Text(
                      'Know More',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: widget.metalType == MetalType.silver
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFC0C0C0), // Bright silver
                              Color(0xFF757575), // Silver-grey
                              Color(0xFF4A5D23), // Dark green-silver mix
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _viewScheme(scheme),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          child: Text(
                            'View Scheme',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              shadows: [
                                const Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _viewScheme(scheme),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scheme.color,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                        ),
                        child: Text(
                          'View Scheme',
                          style: AppTypography.titleSmall.copyWith(
                            color: scheme.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showSchemeDetails(SchemeDetailModel scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSchemeDetailsModal(scheme),
    );
  }

  Widget _buildSchemeDetailsModal(SchemeDetailModel scheme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${scheme.name} Details',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features & Benefits:',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...scheme.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: widget.metalType == MetalType.silver
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFC0C0C0), // Bright silver
                                    Color(0xFF757575), // Silver-grey
                                    Color(0xFF4A5D23), // Dark green-silver mix
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _viewScheme(scheme);
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                ),
                                child: Text(
                                  'View Scheme',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      const Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _viewScheme(scheme);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.color,
                                side: BorderSide(color: scheme.color, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                ),
                              ),
                              child: Text(
                                'View Scheme',
                                style: AppTypography.titleSmall.copyWith(
                                  color: scheme.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _joinScheme(scheme);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.color,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          child: Text(
                            'Join ${scheme.name}',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to normalize scheme types - removes ALL special characters
  String _normalizeSchemeType(String? value) {
    if (value == null) return '';
    return value
        .toString()
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  void _viewScheme(SchemeDetailModel scheme) async {
    try {
      // Get customer information
      final prefs = await SharedPreferences.getInstance();
      String? finalPhone = widget.customerPhone ?? prefs.getString('customer_phone');
      String finalName = widget.customerName ?? prefs.getString('customer_name') ?? 'Customer';

      if (finalPhone == null || finalPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer information not found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Determine scheme type
        String schemeType;
        if (widget.metalType == MetalType.gold) {
          schemeType = scheme.name.contains('Plus') ? 'GOLDPLUS' : 'GOLDFLEXI';
        } else {
          schemeType = scheme.name.contains('Plus') ? 'SILVERPLUS' : 'SILVERFLEXI';
        }

        final isPlus = schemeType.contains('PLUS');

        // Fetch fresh schemes to get latest payment status
        final userSchemes = await GoldSchemeService().fetchSchemesFromBackend();
        
        // Find active scheme of this type
        final normalizedTarget = _normalizeSchemeType(schemeType);
        final activeSchemes = userSchemes.where((s) {
          final backendType = _normalizeSchemeType(s.schemeType);
          return backendType.startsWith(normalizedTarget) && s.isActive == true;
        }).toList();

        Navigator.pop(context); // Hide loading

        // Check if user has active scheme
        if (activeSchemes.isNotEmpty) {
          final activeScheme = activeSchemes.first;
          final hasPaid = activeScheme.hasPaidThisMonth == true;
          
          // CRITICAL: Block if PLUS scheme and already paid this month
          if (isPlus && hasPaid) {
            print('⛔ BLOCKING: Scheme ${activeScheme.schemeName} already paid this month');
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Payment Already Made'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have already made your payment for this month.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📅 Monthly Payment Rule',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PLUS schemes allow only ONE payment per calendar month.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Please wait until next month to make your next payment.',
                      style: TextStyle(color: Colors.grey[700]),
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
            return; // STOP - Do not navigate
          }
          
          // Determine if first month
          final createdDate = activeScheme.createdAt;
          final now = DateTime.now();
          final isFirstMonth = createdDate.year == now.year && createdDate.month == now.month;
          
          // Get amount - null for first month (user can enter), monthlyAmount for subsequent months
          final amount = isFirstMonth ? null : activeScheme.monthlyAmount;
          
          print('✅ Navigating to payment screen:');
          print('   Scheme: ${activeScheme.schemeName}');
          print('   Is First Month: $isFirstMonth');
          print('   Amount: $amount');
          print('   Editable: $isFirstMonth');
          
          // Navigate DIRECTLY to buy screen (NO DIALOG)
          if (widget.metalType == MetalType.gold) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuyGoldScreen(
                  prefilledAmount: amount,
                  isFromScheme: true,
                  schemeId: activeScheme.schemeId,
                  schemeType: schemeType,
                  monthlyAmount: activeScheme.monthlyAmount,
                  schemeName: scheme.name,
                  isFirstMonth: isFirstMonth,
                  isAmountEditable: isFirstMonth,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuySilverScreen(
                  prefilledAmount: amount,
                  isFromScheme: true,
                  schemeId: activeScheme.schemeId,
                  schemeType: schemeType,
                  monthlyAmount: activeScheme.monthlyAmount,
                  schemeName: scheme.name,
                  isFirstMonth: isFirstMonth,
                  isAmountEditable: isFirstMonth,
                ),
              ),
            );
          }
        } else {
          // No active scheme found - user hasn't joined this scheme yet
          // Redirect to join flow instead of showing error
          print('ℹ️ No active scheme found for $schemeType - Redirecting to join flow');
          Navigator.pop(context); // Hide loading
          
          // Show dialog asking if they want to join
          final shouldJoin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Join ${scheme.name}?'),
              content: Text(
                'You don\'t have an active ${scheme.name} yet. Would you like to join this scheme?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Join Scheme'),
                ),
              ],
            ),
          );
          
          if (shouldJoin == true) {
            _joinScheme(scheme);
          }
          return;
        }
        
      } catch (e, stackTrace) {
        try {
          Navigator.pop(context); // Hide loading on error
        } catch (_) {}
        
        print('❌ Error in _viewScheme: $e');
        print('Stack trace: $stackTrace');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading scheme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error viewing scheme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error viewing scheme: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _joinScheme(SchemeDetailModel scheme) async {
    try {
      // ENHANCED DEBUGGING: Check all possible sources of customer data
      final prefs = await SharedPreferences.getInstance();
      print('🔍 DEBUGGING ALL SHARED PREFERENCES KEYS:');
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (key.contains('customer') || key.contains('user') || key.contains('phone') || key.contains('name')) {
          print('  $key: ${prefs.get(key)}');
        }
      }

      // Get customer information
      final customerInfo = await CustomerService.getCustomerInfo();
      print('👤 CustomerService.getCustomerInfo() result: $customerInfo');

      final customerPhone = customerInfo['phone'];
      final customerName = customerInfo['name'];

      // Also check alternative keys that might be used
      final altPhone = prefs.getString('user_phone') ?? prefs.getString('phone');
      final altName = prefs.getString('user_name') ?? prefs.getString('name');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      print('🔍 Alternative data sources:');
      print('  altPhone: $altPhone');
      print('  altName: $altName');
      print('  isLoggedIn: $isLoggedIn');

      // Use alternative data if primary is null
      final finalPhone = customerPhone ?? altPhone;
      final finalName = customerName ?? altName ?? 'Customer';

      if (finalPhone == null || finalPhone.isEmpty) {
        print('❌ No customer phone found in any source');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to join a scheme. Debug: phone=$finalPhone, logged_in=$isLoggedIn'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      print('✅ Using customer data: phone=$finalPhone, name=$finalName');

      // CRITICAL CHECK: Check if customer already has an ACTIVE scheme of this type
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Determine target scheme type
        String targetSchemeType;
        if (widget.metalType == MetalType.gold) {
          targetSchemeType = scheme.name.contains('Plus') ? 'GOLDPLUS' : 'GOLDFLEXI';
        } else {
          targetSchemeType = scheme.name.contains('Plus') ? 'SILVERPLUS' : 'SILVERFLEXI';
        }

        // Fetch user schemes
        final userSchemes = await GoldSchemeService().fetchSchemesFromBackend();
        
        // Hide loading
        Navigator.pop(context);

        // Check for active scheme of same type
        final activeSchemes = userSchemes.where(
           (s) => s.schemeType == targetSchemeType && s.isActive
        ).toList();

        if (activeSchemes.isNotEmpty) {
           final existingScheme = activeSchemes.first;
           print('⚠️ User already has active active scheme: ${existingScheme.schemeId}');
           
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Existing Plan Found'),
              content: Text('You already have an active ${scheme.name} plan.\n\nWould you like to view details or pay installment for your existing plan?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Redirect to view scheme
                    _viewScheme(scheme);
                  },
                  child: const Text('View Existing Plan'),
                ),
              ],
            ),
           );
           return;
        }

      } catch (e) {
        // If checking fails, log but allow proceeding (fail open is safer than blocking)
        // Or fail close? Fail close is safer to prevent duplicates.
        print('⚠️ Error checking existing schemes: $e');
        // We'll proceed but maybe show a warning?
        // Proceeding is standard behavior if offline.
      }

      // Show scheme enrollment dialog
      _showSchemeEnrollmentDialog(scheme, finalPhone!, finalName);
    } catch (e) {
      print('Error joining scheme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining scheme: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSchemeEnrollmentDialog(SchemeDetailModel scheme, String customerPhone, String customerName) {
    final monthlyAmountController = TextEditingController(text: '100');
    bool termsAccepted = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Join ${scheme.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: $customerName'),
                Text('Phone: $customerPhone'),
                const SizedBox(height: 16),
                const Text('Monthly Investment Amount:'),
                const SizedBox(height: 8),
                TextField(
                  controller: monthlyAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    hintText: 'Enter amount',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          termsAccepted = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text('I accept the terms and conditions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: termsAccepted ? () => _createScheme(
                scheme,
                customerPhone,
                customerName,
                double.tryParse(monthlyAmountController.text) ?? 100,
              ) : null,
              child: const Text('Join Scheme'),
            ),
          ],
        ),
      ),
    );
  }

  void _createScheme(SchemeDetailModel scheme, String customerPhone, String customerName, double monthlyAmount) async {
    try {
      Navigator.pop(context); // Close dialog

      // Determine scheme type based on metal type and scheme
      String schemeType;
      if (widget.metalType == MetalType.gold) {
        schemeType = scheme.name.contains('Plus') ? 'GOLDPLUS' : 'GOLDFLEXI';
      } else {
        schemeType = scheme.name.contains('Plus') ? 'SILVERPLUS' : 'SILVERFLEXI';
      }

      print('🔍 JOIN SCHEME: Scheme type: $schemeType, Monthly amount: $monthlyAmount');

      // Navigate to payment - scheme will be created AFTER payment success
      // For new schemes (JOIN), it's always the first month
      if (widget.metalType == MetalType.gold) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyGoldScreen(
              prefilledAmount: monthlyAmount,
              isFromScheme: true,
              schemeType: schemeType,
              monthlyAmount: monthlyAmount,
              schemeName: scheme.name,
              isFirstMonth: true, // Always first month for new schemes
              isAmountEditable: true, // Always editable for new schemes
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuySilverScreen(
              prefilledAmount: monthlyAmount,
              isFromScheme: true,
              schemeType: schemeType,
              monthlyAmount: monthlyAmount,
              schemeName: scheme.name,
              isFirstMonth: true, // Always first month for new schemes
              isAmountEditable: true, // Always editable for new schemes
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _callSchemeCreationAPI({
    required String customerPhone,
    required String customerName,
    required String schemeType,
    required double monthlyAmount,
  }) async {
    try {
      final requestBody = {
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'scheme_type': schemeType,
        'monthly_amount': monthlyAmount,
        'terms_accepted': true,
      };

      print('🔍 SCHEME CREATION API REQUEST:');
      print('🔍 URL: https://api.vmuruganjewellery.co.in:3001/api/schemes');
      print('🔍 Body: $requestBody');

      final response = await SecureHttpClient.post(
        'https://api.vmuruganjewellery.co.in:3001/api/schemes',
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('🔍 Scheme creation response status: ${response.statusCode}');
      print('🔍 Scheme creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🔍 Parsed response data: $data');

        // Extract scheme_id from nested structure
        if (data['success'] == true && data['scheme'] != null) {
          final schemeId = data['scheme']['scheme_id'];
          print('✅ Scheme created with ID: $schemeId');
          return {
            'success': true,
            'scheme_id': schemeId,
            'message': data['message'],
          };
        }

        return data;
      } else {
        print('❌ Server error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        // Try to parse error message from response
        String errorMessage = 'Server error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            errorMessage = errorData['errors'].toString();
          }
        } catch (e) {
          print('❌ Could not parse error response: $e');
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}

class SchemeDetailModel {
  final String id;
  final String name;
  final String subtitle;
  final String duration;
  final String valueAddition;
  final String gstInfo;
  final bool isPremium;
  final Color color;
  final List<String> features;

  const SchemeDetailModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.duration,
    required this.valueAddition,
    required this.gstInfo,
    required this.isPremium,
    required this.color,
    required this.features,
  });
}
