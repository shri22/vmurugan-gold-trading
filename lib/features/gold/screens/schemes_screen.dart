import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/gold_scheme_model.dart';
import '../services/gold_scheme_service.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final GoldSchemeService _schemeService = GoldSchemeService();
  List<GoldSchemeModel> _allSchemes = [];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  void _loadSchemes() {
    _schemeService.initialize();
    setState(() {
      _allSchemes = _schemeService.getUserSchemes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Schemes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateSchemeDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadSchemes();
        },
        child: _allSchemes.isEmpty ? _buildEmptyState() : _buildSchemesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSchemeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.savings,
                size: 60,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Gold Schemes Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start your gold investment journey by creating your first scheme',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              text: 'Create Your First Scheme',
              onPressed: _showCreateSchemeDialog,
              gradient: AppColors.goldGreenGradient,
              icon: Icons.add,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemesList() {
    return ListView.builder(
      padding: Responsive.getPadding(context),
      itemCount: _allSchemes.length,
      itemBuilder: (context, index) {
        final scheme = _allSchemes[index];
        return _buildSchemeCard(scheme);
      },
    );
  }

  Widget _buildSchemeCard(GoldSchemeModel scheme) {
    final performance = _schemeService.calculateSchemePerformance(scheme.id);
    final currentValue = performance?['currentValue'] ?? 0.0;
    final totalGain = performance?['totalGain'] ?? 0.0;
    final gainPercentage = performance?['gainPercentage'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showSchemeDetails(scheme),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme.schemeName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${scheme.formattedMonthlyAmount}/month',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(scheme.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Text(
                      scheme.status.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(scheme.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${scheme.completedMonths}/${scheme.totalMonths} months',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: scheme.progressPercentage / 100,
                    backgroundColor: AppColors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${scheme.progressPercentage.toStringAsFixed(1)}% complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'Invested',
                      scheme.formattedTotalInvested,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Gold Holdings',
                      scheme.formattedGoldAccumulated,
                      Icons.diamond,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Current Value',
                      '₹${currentValue.toStringAsFixed(2)}',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Performance
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: totalGain >= 0 
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      totalGain >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: totalGain >= 0 ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${totalGain >= 0 ? '+' : ''}₹${totalGain.toStringAsFixed(2)} (${gainPercentage.toStringAsFixed(2)}%)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: totalGain >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryGold,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(SchemeStatus status) {
    switch (status) {
      case SchemeStatus.active:
        return AppColors.success;
      case SchemeStatus.completed:
        return AppColors.primaryGold;
      case SchemeStatus.paused:
        return AppColors.warning;
      case SchemeStatus.cancelled:
        return AppColors.error;
    }
  }

  void _showSchemeDetails(GoldSchemeModel scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSchemeDetailsSheet(scheme),
    );
  }

  Widget _buildSchemeDetailsSheet(GoldSchemeModel scheme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey,
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
                    scheme.schemeName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                    'Payment History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...scheme.payments.map((payment) => _buildPaymentTile(payment)),
                  if (scheme.payments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text('No payments yet'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(SchemePayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.payment,
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Text(payment.formattedAmount),
        subtitle: Text(
          '${payment.formattedGoldQuantity} at ${payment.formattedGoldPrice}',
        ),
        trailing: Text(
          '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  void _showCreateSchemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Scheme'),
        content: const Text(
          'Scheme creation feature will be implemented in the next update. '
          'For now, you can view the sample 11-month scheme.',
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
}
