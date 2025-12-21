import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
// Ensure AppColors is imported for gradients
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/customer_service.dart';
import '../../gold/models/gold_scheme_model.dart';
import '../../gold/services/gold_scheme_service.dart';
import '../../portfolio/services/portfolio_service.dart';
import '../../portfolio/models/portfolio_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final GoldSchemeService _schemeService = GoldSchemeService();
  final PortfolioService _portfolioService = PortfolioService();
  List<Transaction> _realTransactions = [];
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Completed', 'Pending', 'Failed'];
  String _selectedSchemeType = 'All';
  final List<String> _schemeTypeOptions = [
    'All',
    'Gold Plus',
    'Gold Flexi',
    'Silver Plus',
    'Silver Flexi',
  ];
  bool _isLoading = false;
  String? _customerId; // Store customer ID

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
    _loadTransactions();
  }

  Future<void> _loadCustomerData() async {
    try {
      final customerInfo = await CustomerService.getCustomerInfo();
      setState(() {
        _customerId = customerInfo['customer_id'];
      });
      print('📋 Customer ID loaded: $_customerId');
    } catch (e) {
      print('❌ Error loading customer ID: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_transactions');
      
      if (cachedData != null && cachedData.isNotEmpty) {
        // Load from cache immediately
        try {
          final List<dynamic> cachedList = jsonDecode(cachedData);
          final cachedTransactions = cachedList.map((txnMap) {
            return Transaction.fromMap(txnMap as Map<String, dynamic>);
          }).toList();
          
          setState(() {
            _realTransactions = cachedTransactions;
            _isLoading = false;
          });
        } catch (e) {
          print('Error loading cached transactions: $e');
          setState(() => _isLoading = true);
        }
      } else {
        // No cache, show loading
        setState(() => _isLoading = true);
      }

      // Always fetch fresh data in background
      final realTransactions = await _portfolioService.getTransactionHistory(limit: 100);

      setState(() {
        _realTransactions = realTransactions;
        _isLoading = false;
      });
      
      // Update cache
      if (realTransactions.isNotEmpty) {
        final transactionMaps = realTransactions.map((t) => t.toMap()).toList();
        await prefs.setString('cached_transactions', jsonEncode(transactionMaps));
      }
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<SchemePayment> get _filteredTransactions {
    // Convert real transactions to SchemePayment format for display
    var convertedTransactions = _realTransactions.map((transaction) {
      return SchemePayment(
        id: transaction.id?.toString() ?? transaction.transactionId,
        schemeId: transaction.schemeId ?? 'REGULAR',
        transactionId: transaction.transactionId,
        amount: transaction.amount,
        goldQuantity: transaction.metalGrams,
        goldPrice: transaction.metalPricePerGram,
        paymentDate: transaction.createdAt,
        status: _mapTransactionStatus(transaction.status),
        paymentMethod: transaction.paymentMethod.toString().split('.').last,
        metalType: transaction.metalType.name.toUpperCase(),
      );
    }).toList();

    // Filter by status
    if (_selectedFilter != 'All') {
      convertedTransactions = convertedTransactions.where((transaction) {
        final txnStatus = transaction.status.toLowerCase().trim();
        final filterStatus = _selectedFilter.toLowerCase().trim();
        return txnStatus == filterStatus;
      }).toList();
    }

    // Filter by scheme type
    if (_selectedSchemeType != 'All') {
      convertedTransactions = convertedTransactions.where((transaction) {
        final schemeId = transaction.schemeId ?? 'REGULAR';
        switch (_selectedSchemeType) {
          case 'Gold Plus':
            return schemeId.startsWith('GP_');
          case 'Gold Flexi':
            return schemeId.startsWith('GF_');
          case 'Silver Plus':
            return schemeId.startsWith('SP_');
          case 'Silver Flexi':
            return schemeId.startsWith('SF_');
          default:
            return true;
        }
      }).toList();
    }

    return convertedTransactions;
  }

  String _mapTransactionStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.SUCCESS:
        return 'Completed';
      case TransactionStatus.PENDING:
        return 'Pending';
      case TransactionStatus.FAILED:
        return 'Failed';
      case TransactionStatus.CANCELLED:
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primaryGreen, // Dark Green
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
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
          // Status Filter Chips
          _buildFilterChips(),

          // Scheme Type Filter Chips
          _buildSchemeTypeFilterChips(),

          // Transaction Summary
          _buildTransactionSummary(),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading transactions...'),
                      ],
                    ),
                  )
                : _filteredTransactions.isEmpty
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

  Widget _buildSchemeTypeFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _schemeTypeOptions.length,
        itemBuilder: (context, index) {
          final schemeType = _schemeTypeOptions[index];
          final isSelected = _selectedSchemeType == schemeType;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(schemeType),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSchemeType = schemeType;
                });
              },
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
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

    // Calculate Gold and Silver separately from all successful transactions
    final totalGold = _realTransactions
        .where((t) => t.metalType.name.toUpperCase() == 'GOLD' && t.status == TransactionStatus.SUCCESS)
        .fold(0.0, (sum, t) => sum + t.metalGrams);
    final totalSilver = _realTransactions
        .where((t) => t.metalType.name.toUpperCase() == 'SILVER' && t.status == TransactionStatus.SUCCESS)
        .fold(0.0, (sum, t) => sum + t.metalGrams);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGreenGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        children: [
          // First Row: Total Invested | Transactions
          Row(
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
                  'Transactions',
                  '${_filteredTransactions.length}',
                  Icons.receipt,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Horizontal divider
          Container(
            height: 1,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          // Second Row: Gold Purchased | Silver Purchased
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Gold Purchased',
                  '${totalGold.toStringAsFixed(4)}g',
                  Icons.star,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Silver Purchased',
                  '${totalSilver.toStringAsFixed(4)}g',
                  Icons.circle,
                ),
              ),
            ],
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
                      gradient: (transaction.metalType?.toUpperCase() ?? 'GOLD') == 'GOLD'
                          ? AppColors.goldGradient
                          : LinearGradient(
                              colors: [Colors.grey[400]!, Colors.grey[600]!],
                            ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Icon(
                      (transaction.metalType?.toUpperCase() ?? 'GOLD') == 'GOLD'
                          ? Icons.star
                          : Icons.circle,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                (transaction.metalType?.toUpperCase() ?? 'GOLD') == 'GOLD'
                                    ? 'Gold Purchase'
                                    : 'Silver Purchase',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (transaction.metalType?.toUpperCase() ?? 'GOLD') == 'GOLD'
                                    ? const Color(0xFFFFD700).withOpacity(0.2)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                transaction.metalType?.toUpperCase() ?? 'GOLD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (transaction.metalType?.toUpperCase() ?? 'GOLD') == 'GOLD'
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatDate(transaction.paymentDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        '${transaction.metalType?.toUpperCase() ?? 'GOLD'} Quantity',
                        transaction.formattedGoldQuantity,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        '${transaction.metalType?.toUpperCase() ?? 'GOLD'} Price',
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
                    if (_customerId != null) ...[
                      _buildDetailRow('Customer ID', _customerId!),
                      const Divider(height: 24),
                    ],
                    _buildDetailRow('Transaction ID', transaction.transactionId),
                    _buildDetailRow('Amount', transaction.formattedAmount),
                    _buildDetailRow(
                      '${transaction.metalType?.toUpperCase() ?? 'GOLD'} Quantity',
                      transaction.formattedGoldQuantity,
                    ),
                    _buildDetailRow(
                      '${transaction.metalType?.toUpperCase() ?? 'GOLD'} Price',
                      transaction.formattedGoldPrice,
                    ),
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
