import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'firebase_status_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  final TextEditingController _adminTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getDashboardData(
        adminToken: FirebaseConfig.adminToken,
      );

      if (result['success']) {
        setState(() {
          _dashboardData = result['data'];
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _authenticateAdmin() {
    // Simple token check for demo purposes
    if (_adminTokenController.text == 'VMURUGAN_ADMIN_2025') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin authenticated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid admin token'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: AppColors.primaryGold,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'VMUrugan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView(
                    children: [
                      _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                      _buildNavItem(1, Icons.people, 'Customers'),
                      _buildNavItem(2, Icons.receipt_long, 'Transactions'),
                      _buildNavItem(3, Icons.analytics, 'Analytics'),
                      _buildNavItem(4, Icons.settings, 'Settings'),
                    ],
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadDashboardData,
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryGold,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: _buildPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                const Text(
                  'VMUrugan Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter admin token: ${FirebaseConfig.adminToken}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FirebaseConfig.isConfigured ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FirebaseConfig.isConfigured ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FirebaseConfig.isConfigured ? Icons.check_circle : Icons.error,
                        color: FirebaseConfig.isConfigured ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FirebaseConfig.isConfigured ? 'Firebase Ready' : 'Firebase Not Configured',
                        style: TextStyle(
                          color: FirebaseConfig.isConfigured ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _adminTokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Admin Token',
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.indigo, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticateAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Access Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_dashboardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _dashboardData!['stats'] ?? {};
    final recentTransactions = _dashboardData!['recent_transactions'] ?? [];
    final customers = _dashboardData!['customers'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Overview
          const Text(
            'Business Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Revenue',
                '₹${stats['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.currency_rupee,
                Colors.green,
              ),
              _buildStatCard(
                'Total Customers',
                '${stats['total_customers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Gold Sold',
                '${stats['total_gold_sold']?.toStringAsFixed(3) ?? '0.000'}g',
                Icons.star,
                Colors.orange,
              ),
              _buildStatCard(
                'Transactions',
                '${stats['total_transactions'] ?? 0}',
                Icons.receipt,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent Transactions
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.add, color: Colors.green),
                  ),
                  title: Text('₹${transaction['amount']?.toStringAsFixed(2) ?? '0.00'}'),
                  subtitle: Text(
                    '${transaction['customer_name'] ?? 'Unknown'} • ${transaction['payment_method'] ?? 'Unknown'}',
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${transaction['gold_grams']?.toStringAsFixed(4) ?? '0.0000'}g',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        transaction['status'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: transaction['status'] == 'SUCCESS' 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Customer List
          const Text(
            'Customer Database',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      customer['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(customer['name'] ?? 'Unknown'),
                  subtitle: Text(customer['phone'] ?? 'No phone'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${customer['email'] ?? 'Not provided'}'),
                          Text('PAN: ${customer['pan_card'] ?? 'Not provided'}'),
                          Text('Total Invested: ₹${customer['total_invested']?.toStringAsFixed(2) ?? '0.00'}'),
                          Text('Gold Holdings: ${customer['total_gold']?.toStringAsFixed(4) ?? '0.0000'}g'),
                          Text('Transactions: ${customer['transaction_count'] ?? 0}'),
                          Text('Registered: ${customer['registration_date'] ?? 'Unknown'}'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard Overview';
      case 1: return 'Customer Management';
      case 2: return 'Transaction History';
      case 3: return 'Business Analytics';
      case 4: return 'System Settings';
      default: return 'Dashboard';
    }
  }

  Widget _buildPageContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
        ),
      );
    }

    switch (_selectedIndex) {
      case 0: return _buildDashboardOverview();
      case 1: return const AdminCustomersScreen();
      case 2: return const AdminTransactionsScreen();
      case 3: return const AdminAnalyticsScreen();
      case 4: return const FirebaseStatusScreen();
      default: return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Customers', '1,234', Icons.people, AppColors.success)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildStatCard('Total Transactions', '5,678', Icons.receipt, AppColors.info)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildStatCard('Total Revenue', '₹12,34,567', Icons.currency_rupee, AppColors.primaryGold)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildStatCard('Gold Sold', '45.67 kg', Icons.star, AppColors.warning)),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Firebase Status',
                  'Check database connection',
                  Icons.cloud,
                  () => setState(() => _selectedIndex = 4),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildQuickActionCard(
                  'View Customers',
                  'Manage customer accounts',
                  Icons.people,
                  () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildQuickActionCard(
                  'Transaction Reports',
                  'View all transactions',
                  Icons.receipt_long,
                  () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Recent Activity
          Container(
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
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildActivityItem('New customer registered', '2 minutes ago', Icons.person_add),
                _buildActivityItem('Gold purchase: ₹5,000', '5 minutes ago', Icons.shopping_cart),
                _buildActivityItem('Payment completed', '10 minutes ago', Icons.payment),
                _buildActivityItem('Customer KYC verified', '15 minutes ago', Icons.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryGold, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGold, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
