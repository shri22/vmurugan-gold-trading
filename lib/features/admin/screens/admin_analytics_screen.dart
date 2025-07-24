import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: [
              const Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: ['Today', 'This Week', 'This Month', 'This Year']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Key Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Revenue', '₹12,34,567', '+15.2%', AppColors.success, Icons.trending_up)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildMetricCard('Gold Sold', '45.67 kg', '+8.5%', AppColors.primaryGold, Icons.star)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildMetricCard('New Customers', '234', '+22.1%', AppColors.info, Icons.person_add)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildMetricCard('Avg. Transaction', '₹4,567', '+5.3%', AppColors.warning, Icons.currency_rupee)),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Chart
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  'Revenue Trend',
                  _buildRevenueChart(),
                ),
              ),
              
              const SizedBox(width: AppSpacing.lg),
              
              // Transaction Types
              Expanded(
                flex: 1,
                child: _buildChartCard(
                  'Transaction Types',
                  _buildTransactionTypesChart(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Customer Analytics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Growth
              Expanded(
                child: _buildChartCard(
                  'Customer Growth',
                  _buildCustomerGrowthChart(),
                ),
              ),
              
              const SizedBox(width: AppSpacing.lg),
              
              // Top Customers
              Expanded(
                child: _buildTopCustomersCard(),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Performance Metrics
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          chart,
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: AppColors.primaryGold),
            SizedBox(height: 16),
            Text('Revenue Chart'),
            Text('Chart integration coming soon', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypesChart() {
    return Container(
      height: 200,
      child: Column(
        children: [
          _buildPieChartItem('Buy Orders', '75%', AppColors.success),
          _buildPieChartItem('Sell Orders', '20%', AppColors.info),
          _buildPieChartItem('Cancelled', '5%', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildPieChartItem(String label, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            percentage,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerGrowthChart() {
    return Container(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: AppColors.info),
            SizedBox(height: 16),
            Text('Customer Growth Chart'),
            Text('Chart integration coming soon', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTopCustomerItem('Rajesh Kumar', '₹50,000', '1'),
          _buildTopCustomerItem('Priya Sharma', '₹35,000', '2'),
          _buildTopCustomerItem('Amit Patel', '₹28,000', '3'),
          _buildTopCustomerItem('Sunita Devi', '₹22,000', '4'),
          _buildTopCustomerItem('Vikram Singh', '₹18,000', '5'),
        ],
      ),
    );
  }

  Widget _buildTopCustomerItem(String name, String amount, String rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _buildPerformanceItem('Conversion Rate', '12.5%', AppColors.success)),
              Expanded(child: _buildPerformanceItem('Avg. Order Value', '₹4,567', AppColors.info)),
              Expanded(child: _buildPerformanceItem('Customer Retention', '85%', AppColors.primaryGold)),
              Expanded(child: _buildPerformanceItem('Payment Success', '98.2%', AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
