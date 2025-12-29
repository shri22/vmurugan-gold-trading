import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
// Ensure AppColors is imported for gradients
import '../../../core/utils/responsive.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../models/gold_scheme_model.dart';
import '../services/gold_scheme_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final GoldSchemeService _schemeService = GoldSchemeService();
  List<SchemePayment> _allTransactions = [];
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Completed', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _schemeService.initialize();
    final schemes = await _schemeService.getUserSchemes();
    
    // Collect all payments from all schemes
    final allPayments = <SchemePayment>[];
    for (final scheme in schemes) {
      allPayments.addAll(scheme.payments);
    }
    
    // Sort by date (newest first)
    allPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    
    if (mounted) {
      setState(() {
        _allTransactions = allPayments;
      });
    }
  }

  List<SchemePayment> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _allTransactions;
    }
    return _allTransactions.where((transaction) {
      return transaction.status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // Transaction Summary
          _buildTransactionSummary(),
          
          // Transaction List
          Expanded(
            child: _filteredTransactions.isEmpty 
                ? _buildEmptyState() 
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGold,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionSummary() {
    final totalAmount = _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    final totalGold = _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.goldQuantity);
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGreenGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Invested',
              '₹${totalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Gold Purchased',
              '${NumberFormatter.formatToThreeDecimals(totalGold)}g',
              Icons.diamond,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Transactions',
              '${_filteredTransactions.length}',
              Icons.receipt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(SchemePayment transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Icon(
                      _getTransactionIcon(transaction.status),
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gold Purchase',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatDate(transaction.paymentDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.formattedAmount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(transaction.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Transaction Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Gold Quantity',
                        transaction.formattedGoldQuantity,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Gold Price',
                        transaction.formattedGoldPrice,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Payment Method',
                        transaction.paymentMethod,
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

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
                Icons.receipt_long,
                size: 60,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Transactions Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your transaction history will appear here once you start investing in gold',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Start Investing',
              onPressed: () => Navigator.pop(context),
              type: ButtonType.primary,
              icon: Icons.diamond,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showTransactionDetails(SchemePayment transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                      'Transaction Details',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Transaction ID', transaction.transactionId),
                    _buildDetailRow('Amount', transaction.formattedAmount),
                    _buildDetailRow('Gold Quantity', transaction.formattedGoldQuantity),
                    _buildDetailRow('Gold Price', transaction.formattedGoldPrice),
                    _buildDetailRow('Payment Method', transaction.paymentMethod),
                    _buildDetailRow('Date', _formatDate(transaction.paymentDate)),
                    _buildDetailRow('Status', transaction.status.toUpperCase()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportTransactions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transactions'),
        content: const Text(
          'Transaction export feature will be implemented in the next update. '
          'You will be able to export your transaction history as PDF or CSV.',
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
