import 'package:flutter/material.dart';
import '../models/portfolio_model.dart';
import '../services/portfolio_service.dart';
import '../../gold/models/gold_price_model.dart';
import '../../gold/services/gold_price_service.dart';
import '../../silver/models/silver_price_model.dart';
import '../../silver/services/silver_price_service.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/theme/app_colors.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  final GoldPriceService _goldPriceService = GoldPriceService();
  final SilverPriceService _silverPriceService = SilverPriceService();

  Portfolio? _portfolio;
  List<Transaction> _transactions = [];
  List<Map<String, dynamic>> _activeSchemes = [];
  GoldPriceModel? _currentGoldPrice;
  SilverPriceModel? _currentSilverPrice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    setState(() => _isLoading = true);

    try {
      // Load portfolio, schemes, and current prices in parallel
      final results = await Future.wait([
        _portfolioService.getPortfolio(),
        _portfolioService.getTransactionHistory(limit: 10),
        _portfolioService.getActiveSchemes(),
        _goldPriceService.getCurrentPrice(),
        _silverPriceService.getCurrentPrice(),
      ]);

      _portfolio = results[0] as Portfolio;
      _transactions = results[1] as List<Transaction>;
      _activeSchemes = results[2] as List<Map<String, dynamic>>;
      _currentGoldPrice = results[3] as GoldPriceModel?;
      _currentSilverPrice = results[4] as SilverPriceModel?;

      print('📊 Portfolio loaded: ${_portfolio?.totalGoldGrams} g gold, ${_portfolio?.totalSilverGrams} g silver');
      print('📋 Active schemes: ${_activeSchemes.length}');

      // Update portfolio value with current prices
      if (_currentGoldPrice != null) {
        await _portfolioService.updatePortfolioValue(_currentGoldPrice!);
        _portfolio = await _portfolioService.getPortfolio();
      }

    } catch (e) {
      print('Error loading portfolio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: Colors.white,
        ),
        backgroundColor: AppColors.primaryGreen, // Dark Green
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPortfolioData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPortfolioData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPortfolioSummary(),
                    const SizedBox(height: 24),
                    if (_portfolio?.breakdown != null) ...[
                      _buildHoldingsBreakdown(),
                      const SizedBox(height: 24),
                    ],
                    if (_activeSchemes.isNotEmpty) ...[
                      _buildActiveSchemesSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildCustomerDetails(),
                    const SizedBox(height: 24),
                    _buildCurrentPrice(),
                    const SizedBox(height: 24),
                    _buildTransactionHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPortfolioSummary() {
    if (_portfolio == null) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700),
              const Color(0xFFFFD700).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer ID Display
            if (_portfolio!.customerId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge, size: 16, color: AppColors.getTextColor(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Customer ID: ${_portfolio!.customerId}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 28, color: AppColors.getTextColor(context)),
                const SizedBox(width: 12),
                Text(
                  'Portfolio Value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '₹${_portfolio!.currentValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _portfolio!.isProfit ? Icons.trending_up : Icons.trending_down,
                  color: _portfolio!.isProfit ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_portfolio!.profitLossDisplay} (${_portfolio!.profitLossPercentage.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _portfolio!.isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Gold Holdings',
                    '${NumberFormatter.formatToThreeDecimals(_portfolio!.totalGoldGrams)} g',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Silver Holdings',
                    '${NumberFormatter.formatToThreeDecimals(_portfolio!.totalSilverGrams)} g',
                    Icons.circle,
                    Colors.grey[400]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Invested',
                    '₹${_portfolio!.totalInvested.toStringAsFixed(2)}',
                    Icons.account_balance,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Current Value',
                    '₹${_portfolio!.currentValue.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? iconColor]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? AppColors.getSecondaryTextColor(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    if (_portfolio == null) return const SizedBox();

    // Check if we have any customer details to display
    final hasAddress = _portfolio!.customerAddress != null && _portfolio!.customerAddress!.isNotEmpty;
    final hasPanCard = _portfolio!.customerPanCard != null && _portfolio!.customerPanCard!.isNotEmpty;
    final hasNominee = _portfolio!.customerNomineeName != null && _portfolio!.customerNomineeName!.isNotEmpty;

    // If no details available, don't show the card
    if (!hasAddress && !hasPanCard && !hasNominee) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer ID (always show if available)
            if (_portfolio!.customerId != null && _portfolio!.customerId!.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.badge,
                label: 'Customer ID',
                value: _portfolio!.customerId!,
                iconColor: AppColors.primaryGold,
              ),
              const SizedBox(height: 12),
            ],

            // Address
            if (hasAddress) ...[
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Address',
                value: _portfolio!.customerAddress!,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 12),
            ],

            // PAN Card
            if (hasPanCard) ...[
              _buildDetailRow(
                icon: Icons.credit_card,
                label: 'PAN Card',
                value: _portfolio!.customerPanCard!,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 12),
            ],

            // Nominee Details
            if (hasNominee) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.family_restroom, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Nominee Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: _portfolio!.customerNomineeName!,
                iconColor: Colors.green,
              ),
              if (_portfolio!.customerNomineeRelationship != null &&
                  _portfolio!.customerNomineeRelationship!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.people,
                  label: 'Relationship',
                  value: _portfolio!.customerNomineeRelationship!,
                  iconColor: Colors.green,
                ),
              ],
              if (_portfolio!.customerNomineePhone != null &&
                  _portfolio!.customerNomineePhone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: _portfolio!.customerNomineePhone!,
                  iconColor: Colors.green,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.getSecondaryTextColor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPrice() {
    if (_currentGoldPrice == null && _currentSilverPrice == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Current Prices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gold Price Row
            if (_currentGoldPrice != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('22K Gold', style: TextStyle(color: Colors.grey)),
                      Text(
                        '₹${_currentGoldPrice!.pricePerGram.toStringAsFixed(2)}/g',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Silver Price Row
            if (_currentSilverPrice != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Silver', style: TextStyle(color: Colors.grey)),
                      Text(
                        '₹${_currentSilverPrice!.pricePerGram.toStringAsFixed(2)}/g',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start buying gold to see your transaction history',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isBuy = transaction.type == TransactionType.BUY;
    final statusColor = _getStatusColor(transaction.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBuy ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isBuy ? Icons.add : Icons.remove,
            color: isBuy ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.typeDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.goldGrams.toStringAsFixed(4)} grams'),
            Text(
              '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.statusDisplay,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.SUCCESS:
        return Colors.green;
      case TransactionStatus.PENDING:
        return Colors.orange;
      case TransactionStatus.FAILED:
        return Colors.red;
      case TransactionStatus.CANCELLED:
        return Colors.grey;
    }
  }

  Widget _buildHoldingsBreakdown() {
    if (_portfolio?.breakdown == null) return const SizedBox();

    final breakdown = _portfolio!.breakdown!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Holdings Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gold Breakdown
            if (breakdown.goldTotal > 0) ...[
              _buildMetalBreakdownHeader('Gold', breakdown.goldTotal, Icons.star, AppColors.primaryGold),
              const SizedBox(height: 12),
              if (breakdown.goldDirectPurchase > 0)
                _buildBreakdownItem('Direct Purchase', breakdown.goldDirectPurchase, Icons.shopping_cart, Colors.orange),
              if (breakdown.goldPlus > 0)
                _buildBreakdownItem('Gold Plus', breakdown.goldPlus, Icons.calendar_today, Colors.amber[700]!),
              if (breakdown.goldFlexi > 0)
                _buildBreakdownItem('Gold Flexi', breakdown.goldFlexi, Icons.all_inclusive, Colors.yellow[800]!),
              const SizedBox(height: 16),
            ],

            // Silver Breakdown
            if (breakdown.silverTotal > 0) ...[
              _buildMetalBreakdownHeader('Silver', breakdown.silverTotal, Icons.circle, Colors.grey[400]!),
              const SizedBox(height: 12),
              if (breakdown.silverDirectPurchase > 0)
                _buildBreakdownItem('Direct Purchase', breakdown.silverDirectPurchase, Icons.shopping_cart, Colors.blueGrey),
              if (breakdown.silverPlus > 0)
                _buildBreakdownItem('Silver Plus', breakdown.silverPlus, Icons.calendar_today, Colors.grey[600]!),
              if (breakdown.silverFlexi > 0)
                _buildBreakdownItem('Silver Flexi', breakdown.silverFlexi, Icons.all_inclusive, Colors.grey[700]!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetalBreakdownHeader(String metal, double total, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$metal Holdings: ${NumberFormatter.formatToThreeDecimals(total)} g',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double grams, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(context).withOpacity(0.8),
              ),
            ),
          ),
          Text(
            '${NumberFormatter.formatToThreeDecimals(grams)} g',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSchemesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Active Schemes (${_activeSchemes.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._activeSchemes.map((scheme) => _buildSchemeCard(scheme)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    final schemeType = scheme['scheme_type'] ?? '';
    final schemeId = scheme['scheme_id'] ?? '';
    final metalType = scheme['metal_type'] ?? '';
    final totalAccumulated = (scheme['total_metal_accumulated'] ?? 0.0).toDouble();
    final totalPaid = (scheme['total_amount_paid'] ?? 0.0).toDouble();
    final monthlyAmount = (scheme['monthly_amount'] ?? 0.0).toDouble();
    final paidMonths = scheme['paid_months'] ?? 0;
    final totalMonths = scheme['total_months'] ?? 0;
    final status = scheme['status'] ?? '';

    // Determine colors and icons based on scheme type
    Color schemeColor;
    IconData schemeIcon;
    String displayName;

    if (schemeType == 'GOLDPLUS') {
      schemeColor = Colors.amber[700]!;
      schemeIcon = Icons.calendar_today;
      displayName = 'Gold Plus';
    } else if (schemeType == 'GOLDFLEXI') {
      schemeColor = Colors.yellow[800]!;
      schemeIcon = Icons.all_inclusive;
      displayName = 'Gold Flexi';
    } else if (schemeType == 'SILVERPLUS') {
      schemeColor = Colors.grey[600]!;
      schemeIcon = Icons.calendar_today;
      displayName = 'Silver Plus';
    } else if (schemeType == 'SILVERFLEXI') {
      schemeColor = Colors.grey[700]!;
      schemeIcon = Icons.all_inclusive;
      displayName = 'Silver Flexi';
    } else {
      schemeColor = Colors.blue;
      schemeIcon = Icons.account_balance;
      displayName = schemeType;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: schemeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: schemeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(schemeIcon, color: schemeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'ACTIVE' ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            schemeId,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextColor(context).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSchemeStatItem(
                  '${metalType == 'GOLD' ? '⭐' : '⚪'} Accumulated',
                  '${NumberFormatter.formatToThreeDecimals(totalAccumulated)} g',
                ),
              ),
              Expanded(
                child: _buildSchemeStatItem(
                  '💰 Invested',
                  '₹${totalPaid.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          if (schemeType.contains('PLUS')) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSchemeStatItem(
                    '📅 Progress',
                    '$paidMonths/$totalMonths months',
                  ),
                ),
                Expanded(
                  child: _buildSchemeStatItem(
                    '💵 Monthly',
                    '₹${monthlyAmount.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalMonths > 0 ? paidMonths / totalMonths : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(schemeColor),
            ),
          ] else if (schemeType.contains('FLEXI')) ...[
            const SizedBox(height: 12),
            _buildSchemeStatItem(
              '🔄 Flexible Payments',
              'No monthly restrictions',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchemeStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextColor(context).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(context),
          ),
        ),
      ],
    );
  }
}
