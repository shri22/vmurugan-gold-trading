import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import 'monthly_report_screen.dart';
import 'scheme_wise_report_screen.dart';
import 'flexi_report_screen.dart';
import 'consolidated_report_screen.dart';
import 'yearly_summary_screen.dart';
import 'portfolio_report_screen.dart';

/// Main Reports Screen with all report types
class ReportsScreen extends StatelessWidget {
  final String? customerPhone;

  const ReportsScreen({
    Key? key,
    this.customerPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: AppColors.primaryGreen,
        ),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGold.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            const Text(
              '📊 Reports & Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'View detailed reports and analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Report Cards
            _buildReportCard(
              context,
              icon: Icons.calendar_month,
              title: 'Monthly Report',
              description: 'View transactions and schemes by month',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonthlyReportScreen(customerPhone: customerPhone),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              icon: Icons.account_tree,
              title: 'Scheme-wise Report',
              description: 'Detailed report for each scheme',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SchemeWiseReportScreen(customerPhone: customerPhone),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              icon: Icons.all_inclusive,
              title: 'Flexi Report',
              description: 'Gold Flexi and Silver Flexi payments',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlexiReportScreen(customerPhone: customerPhone),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              icon: Icons.summarize,
              title: 'Consolidated Report',
              description: 'Complete overview of all investments',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsolidatedReportScreen(customerPhone: customerPhone),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              icon: Icons.calendar_today,
              title: 'Yearly Summary',
              description: 'Year-wise investment summary',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YearlySummaryScreen(customerPhone: customerPhone),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              icon: Icons.pie_chart,
              title: 'Portfolio Report',
              description: 'Detailed portfolio analysis',
              color: AppColors.primaryGreen,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PortfolioReportScreen(customerPhone: customerPhone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

