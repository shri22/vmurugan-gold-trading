import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/translation_service.dart' as TranslationService;
import '../../../core/services/mock_data_service.dart';
import '../../auth/screens/customer_registration_screen.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
import 'change_mpin_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> _userProfile = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentLanguage = 'en';
  String _currentLanguageDisplay = 'English';

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
    _loadLanguagePreference();
  }

  Future<void> _loadCustomerProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check both old and new authentication data
      final prefs = await SharedPreferences.getInstance();

      // First try new authentication data
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userPhone = prefs.getString('user_phone');
      final userDataString = prefs.getString('user_data');

      Map<String, dynamic>? userData;
      if (userDataString != null) {
        try {
          userData = jsonDecode(userDataString);
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      // If new auth data exists, use it
      if (isLoggedIn && userPhone != null && userData != null) {
        // Format the registration date
        String formattedJoinDate = 'Recently';
        if (userData['registration_date'] != null) {
          try {
            final regDate = DateTime.parse(userData['registration_date']);
            formattedJoinDate = '${regDate.day}/${regDate.month}/${regDate.year}';
          } catch (e) {
            formattedJoinDate = 'Recently';
          }
        }

        // Determine KYC status based on actual data
        String kycStatus = 'Pending';
        if (userData['address'] != null && userData['address'].toString().isNotEmpty &&
            userData['address'] != 'Not Available' &&
            userData['pan_card'] != null && userData['pan_card'].toString().isNotEmpty &&
            userData['pan_card'] != 'Not Available') {
          kycStatus = 'Verified';
        }

        // Use business_id as Customer ID if available, otherwise use customer_id or id
        String customerId = userData['business_id']?.toString() ??
                           userData['customer_id']?.toString() ??
                           userData['id']?.toString() ??
                           'CUST${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        setState(() {
          _userProfile = {
            'name': userData!['name'] ?? 'User',
            'phone': userPhone,
            'email': userData['email'] ?? 'Not Available',
            'customer_id': customerId,
            'address': userData['address'] ?? 'Not Available',
            'pan': userData['pan_card'] ?? 'Not Available',
            'joinDate': formattedJoinDate,
            'kycStatus': kycStatus,
          };
          _isLoading = false;
        });
        return;
      }

      // Fallback to old customer service data
      final customerInfo = await CustomerService.getCustomerInfo();

      if (customerInfo['phone'] != null && customerInfo['phone']!.isNotEmpty) {
        // Format the registration date
        String formattedJoinDate = 'Recently';
        if (customerInfo['registration_date'] != null && customerInfo['registration_date']!.isNotEmpty) {
          try {
            final regDate = DateTime.parse(customerInfo['registration_date']!);
            formattedJoinDate = '${regDate.day}/${regDate.month}/${regDate.year}';
          } catch (e) {
            formattedJoinDate = 'Recently';
          }
        }

        // Determine KYC status based on actual data
        String kycStatus = 'Pending';
        if (customerInfo['address'] != null && customerInfo['address'].toString().isNotEmpty &&
            customerInfo['address'] != 'Not Available' &&
            customerInfo['pan_card'] != null && customerInfo['pan_card'].toString().isNotEmpty &&
            customerInfo['pan_card'] != 'Not Available') {
          kycStatus = 'Verified';
        }

        // Use business_id as Customer ID if available
        String customerId = customerInfo['business_id']?.toString() ??
                           customerInfo['customer_id']?.toString() ??
                           'CUST${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        // Format the data for display
        setState(() {
          _userProfile = {
            'name': customerInfo['name'] ?? 'Not Available',
            'phone': customerInfo['phone'] ?? 'Not Available',
            'email': customerInfo['email'] ?? 'Not Available',
            'customer_id': customerId,
            'address': customerInfo['address'] ?? 'Not Available',
            'pan': customerInfo['pan_card'] ?? 'Not Available',
            'joinDate': formattedJoinDate,
            'kycStatus': kycStatus,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Please login to view profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: Colors.black,
        ),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomerProfile,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCustomerProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Profile Details
            _buildProfileDetails(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Account Actions
            _buildAccountActions(),
            
            const SizedBox(height: AppSpacing.xl),

            // Settings
            _buildSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGold,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primaryGold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Customer ID (prominent display)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold),
            ),
            child: Text(
              'ID: ${_userProfile['customer_id'] ?? 'Loading...'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            _userProfile['name'] ?? 'Loading...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Phone
          Text(
            _userProfile['phone'] ?? 'Loading...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // KYC Status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _currentLanguage == 'ta'
                    ? 'கேஒய்சி ${_userProfile['kycStatus'] == 'Verified' ? 'சரிபார்க்கப்பட்டது' : _userProfile['kycStatus']}'
                    : 'KYC ${_userProfile['kycStatus']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentLanguage == 'ta' ? 'தனிப்பட்ட தகவல்' : 'Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildDetailRow(Icons.email, _currentLanguage == 'ta' ? 'மின்னஞ்சல்' : 'Email', _userProfile['email'] ?? (_currentLanguage == 'ta' ? 'கிடைக்கவில்லை' : 'Not Available')),
          _buildDetailRow(Icons.location_on, _currentLanguage == 'ta' ? 'முகவரி' : 'Address', _userProfile['address'] ?? (_currentLanguage == 'ta' ? 'கிடைக்கவில்லை' : 'Not Available')),
          _buildDetailRow(Icons.credit_card, _currentLanguage == 'ta' ? 'பான் கார்டு' : 'PAN Card', _userProfile['pan'] ?? (_currentLanguage == 'ta' ? 'கிடைக்கவில்லை' : 'Not Available')),
          _buildDetailRow(Icons.calendar_today, _currentLanguage == 'ta' ? 'சேர்ந்த தேதி' : 'Member Since', _userProfile['joinDate'] ?? (_currentLanguage == 'ta' ? 'சமீபத்தில்' : 'Recently')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryGold,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildActionTile(
            Icons.security,
            'Change MPIN',
            'Update your security PIN',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangeMpinScreen(),
              ),
            ),
          ),
          
          _buildActionTile(
            Icons.notifications,
            'Notification Settings',
            'Manage your notifications',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationPreferencesScreen(),
              ),
            ),
          ),
          
          _buildActionTile(
            Icons.download,
            'Download Statements',
            'Get your transaction statements',
            _showDownloadStatements,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentLanguage == 'ta' ? 'அமைப்புகள்' : 'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildActionTile(
            Icons.language,
            _currentLanguage == 'ta' ? 'மொழி' : 'Language',
            _currentLanguageDisplay,
            _showLanguageSelector,
          ),
          
          _buildActionTile(
            Icons.help,
            _currentLanguage == 'ta' ? 'உதவி மற்றும் ஆதரவு' : 'Help & Support',
            _currentLanguage == 'ta' ? 'உதவி பெறுங்கள் மற்றும் ஆதரவைத் தொடர்பு கொள்ளுங்கள்' : 'Get help and contact support',
            _showHelpAndSupport,
          ),

          _buildActionTile(
            Icons.info,
            _currentLanguage == 'ta' ? 'பற்றி' : 'About',
            _currentLanguage == 'ta' ? 'வி முருகன் நகைகளைப் பற்றி அறிக' : 'Learn about V Murugan Jewellery',
            _showAboutDialog,
          ),

          _buildActionTile(
            Icons.logout,
            _currentLanguage == 'ta' ? 'வெளியேறு' : 'Logout',
            _currentLanguage == 'ta' ? 'உங்கள் கணக்கிலிருந்து வெளியேறுங்கள்' : 'Sign out of your account',
            _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.primaryGold,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerRegistrationScreen(),
      ),
    );
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final language = await TranslationService.LanguageService.getCurrentLanguage();
      final languageDisplay = await TranslationService.LanguageService.getCurrentLanguageDisplay();

      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _currentLanguageDisplay = languageDisplay;
        });
      }
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _currentLanguage == 'ta' ? 'மொழியைத் தேர்ந்தெடுக்கவும்' : 'Select Language',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primaryGold),
                title: const Text('English'),
                trailing: _currentLanguage == 'en'
                  ? const Icon(Icons.check, color: AppColors.primaryGold)
                  : null,
                onTap: () => _changeLanguage('en'),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primaryGold),
                title: const Text('தமிழ்'),
                trailing: _currentLanguage == 'ta'
                  ? const Icon(Icons.check, color: AppColors.primaryGold)
                  : null,
                onTap: () => _changeLanguage('ta'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _currentLanguage == 'ta' ? 'ரத்து செய்' : 'Cancel',
                style: const TextStyle(color: AppColors.primaryGold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      await TranslationService.LanguageService.setLanguage(languageCode);
      await _loadLanguagePreference();

      Navigator.of(context).pop(); // Close dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'ta'
              ? 'மொழி வெற்றிகரமாக மாற்றப்பட்டது'
              : 'Language changed successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh the screen to apply new language
      setState(() {});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing language: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showDownloadStatements() {
    showDialog(
      context: context,
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
                Icons.download,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Download Statements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Statement Options
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Available Statements',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Current Month Statement
                    _buildStatementOption(
                      'Current Month',
                      'All transactions for ${_getCurrentMonthName()}',
                      Icons.calendar_today,
                      () => _downloadStatement('current_month'),
                    ),

                    const SizedBox(height: 12),

                    // Last 3 Months Statement
                    _buildStatementOption(
                      'Last 3 Months',
                      'Transaction history for the last 3 months',
                      Icons.calendar_view_month,
                      () => _downloadStatement('last_3_months'),
                    ),

                    const SizedBox(height: 12),

                    // All Transactions Statement
                    _buildStatementOption(
                      'All Transactions',
                      'Complete transaction history',
                      Icons.history,
                      () => _downloadStatement('all_transactions'),
                    ),


                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Statement Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Statement Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Statements include all gold purchase transactions\n'
                      '• PDF format with detailed transaction information\n'
                      '• Includes customer details, amounts, and gold quantities\n'
                      '• Suitable for record keeping and tax purposes\n'
                      '• Downloaded files are saved to your device',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementOption(String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.green[700], size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: Colors.green[700], size: 20),
          ],
        ),
      ),
    );
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Future<void> _downloadStatement(String period) async {
    Navigator.pop(context); // Close the dialog

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Generating ${_getPeriodDisplayName(period)} statement...'),
          ],
        ),
      ),
    );

    try {
      // Calculate date range based on period
      final dateRange = _getDateRangeForPeriod(period);

      List<Map<String, dynamic>> transactions;

      // Use mock data for testing or fetch from API
      if (MockDataService.shouldUseMockData()) {
        print('📊 Profile: Using mock data for statement generation');

        // Generate mock transactions for the specified period
        transactions = MockDataService.generateMockTransactions(
          period: period,
          count: _getMockTransactionCount(period),
        );

        // Simulate API delay
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // Fetch transactions from API
        final result = await ApiService.getTransactions(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        );

        if (result['success']) {
          transactions = result['transactions'] as List<Map<String, dynamic>>;
        } else {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog('Failed to fetch transactions: ${result['message']}');
          return;
        }
      }

      Navigator.pop(context); // Close loading dialog

      if (transactions.isEmpty) {
        _showNoTransactionsDialog(period);
      } else {
        // Generate and download PDF
        await _generatePDFStatement(transactions, period);
        _showDownloadSuccessDialog(period);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Error generating statement: $e');
    }
  }

  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'current_month':
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month + 1, 0),
        };
      case 'last_3_months':
        return {
          'start': DateTime(now.year, now.month - 2, 1),
          'end': now,
        };
      case 'all_transactions':
        return {
          'start': null,
          'end': null,
        };
      default:
        return {
          'start': null,
          'end': null,
        };
    }
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case 'current_month':
        return 'Current Month';
      case 'last_3_months':
        return 'Last 3 Months';
      case 'all_transactions':
        return 'All Transactions';
      default:
        return 'Custom';
    }
  }

  Future<void> _generatePDFStatement(List<Map<String, dynamic>> transactions, String period) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Calculate totals
      double totalAmount = 0;
      double totalGold = 0;
      double totalSilver = 0;

      for (final txn in transactions) {
        if (txn['status'] == 'SUCCESS') {
          totalAmount += (txn['amount'] as num).toDouble();
          if (txn['gold_grams'] != null) {
            totalGold += (txn['gold_grams'] as num).toDouble();
          }
          if (txn['silver_grams'] != null) {
            totalSilver += (txn['silver_grams'] as num).toDouble();
          }
        }
      }

      // Add page to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'V MURUGAN JEWELLERY',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'TRANSACTION STATEMENT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(),
                  ],
                ),
              ),

              // Statement Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Period: ${_getPeriodDisplayName(period)}'),
                  pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}'),
                ],
              ),
              pw.SizedBox(height: 8),

              // Mock data notice (if using mock data)
              if (MockDataService.shouldUseMockData()) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange100,
                    border: pw.Border.all(color: PdfColors.orange),
                  ),
                  child: pw.Text(
                    '📊 DEMO DATA: This statement contains mock data for testing purposes.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
              ] else ...[
                pw.SizedBox(height: 16),
              ],

              // Transactions Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Transaction ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Gold (g)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Payment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...transactions.map((txn) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(txn['transaction_id'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          txn['timestamp']?.toString().split('T')[0] ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '₹${((txn['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${((txn['gold_grams'] as num?)?.toDouble() ?? 0).toStringAsFixed(3)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(txn['payment_method'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(txn['status'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  )),
                ],
              ),

              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SUMMARY', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Total Transactions: ${transactions.length}'),
                    pw.Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
                    pw.Text('Total Gold: ${totalGold.toStringAsFixed(3)}g'),
                    if (totalSilver > 0) pw.Text('Total Silver: ${totalSilver.toStringAsFixed(3)}g'),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to device Downloads folder
      Directory? directory;
      String fileName = 'VMurugan_Statement_${period}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      try {
        if (Platform.isAndroid) {
          // Try multiple Android download locations
          final downloadPaths = [
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Downloads',
            '/sdcard/Download',
            '/sdcard/Downloads',
          ];

          for (final path in downloadPaths) {
            directory = Directory(path);
            if (await directory.exists()) {
              print('✅ Found Downloads directory: $path');
              break;
            }
          }

          // If no Downloads folder found, use external storage
          if (directory == null || !await directory.exists()) {
            directory = await getExternalStorageDirectory();
            print('📁 Using external storage: ${directory?.path}');
          }
        } else {
          // For other platforms, use documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('❌ Error accessing storage: $e');
        // Fallback to documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access device storage');
      }

      final file = File('${directory.path}/$fileName');

      // Ensure directory exists
      await directory.create(recursive: true);

      // Write PDF file
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF saved successfully to: ${file.path}');
      print('📂 File size: ${await file.length()} bytes');

      // Verify file was created
      if (await file.exists()) {
        print('✅ File verification successful');
      } else {
        throw Exception('File was not created successfully');
      }
    } catch (e) {
      print('Error generating PDF: $e');
      // Fallback to clipboard
      await _generateTextStatement(transactions, period);
    }
  }

  Future<void> _generateTextStatement(List<Map<String, dynamic>> transactions, String period) async {
    final buffer = StringBuffer();
    buffer.writeln('V MURUGAN JEWELLERY');
    buffer.writeln('TRANSACTION STATEMENT');
    buffer.writeln('=' * 50);
    buffer.writeln('Period: ${_getPeriodDisplayName(period)}');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    double totalAmount = 0;
    double totalGold = 0;

    for (int i = 0; i < transactions.length; i++) {
      final txn = transactions[i];
      buffer.writeln('Transaction ${i + 1}:');
      buffer.writeln('  ID: ${txn['transaction_id']}');
      buffer.writeln('  Date: ${txn['timestamp']}');
      buffer.writeln('  Amount: ₹${((txn['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}');
      buffer.writeln('  Gold: ${((txn['gold_grams'] as num?)?.toDouble() ?? 0).toStringAsFixed(3)}g');
      buffer.writeln('  Price/gram: ₹${((txn['gold_price_per_gram'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}');
      buffer.writeln('  Payment: ${txn['payment_method']}');
      buffer.writeln('  Status: ${txn['status']}');
      buffer.writeln();

      if (txn['status'] == 'SUCCESS') {
        totalAmount += (txn['amount'] as num?)?.toDouble() ?? 0;
        totalGold += (txn['gold_grams'] as num?)?.toDouble() ?? 0;
      }
    }

    buffer.writeln('=' * 50);
    buffer.writeln('SUMMARY:');
    buffer.writeln('Total Transactions: ${transactions.length}');
    buffer.writeln('Total Amount: ₹${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('Total Gold: ${totalGold.toStringAsFixed(3)}g');
    buffer.writeln('=' * 50);

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }



  void _showNoTransactionsDialog(String period) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('No Transactions'),
          ],
        ),
        content: Text(
          'No transactions found for ${_getPeriodDisplayName(period).toLowerCase()}.\n\n'
          'Start investing in gold to generate statements!',
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

  void _showDownloadSuccessDialog(String period) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Statement Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your ${_getPeriodDisplayName(period).toLowerCase()} statement has been generated successfully!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                '✅ PDF statement has been generated and saved successfully!\n\n'
                '📂 Location: Downloads folder\n'
                '📱 Access: Open your file manager → Downloads → Look for "VMurugan_Statement_..." file\n'
                '📄 Format: PDF document ready for viewing',
                style: TextStyle(fontSize: 13),
              ),
            ),
            if (MockDataService.shouldUseMockData()) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Text(
                  '📊 Demo Mode: This statement contains mock data for testing purposes. In production, real transaction data will be used.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
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

  void _showHelpAndSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_center,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Store Information Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Store Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main Store
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Main Store',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No: 94 & 71, PRS Street,\nDharmapuri – 1.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Branch Store
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business, color: AppColors.primaryGold, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Branch',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Perumal Kovil Vaniga Valagam,\nArasambatti.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Numbers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildContactRow('+91 9677944711', Icons.phone),
                    _buildContactRow('+91 94449 92494', Icons.phone),
                    _buildContactRow('+91 94431 93476', Icons.phone),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.green[700], size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildContactRow('vmuruganjewellers@gmail.com', Icons.email),
                    const SizedBox(height: 6),
                    const Text(
                      'Email us at vmuruganjewellers@gmail.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Support Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Need Help?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• For gold purchase queries, call our support numbers\n'
                      '• For app-related issues, contact us via email\n'
                      '• Visit our stores for in-person assistance\n'
                      '• Our team is available during business hours',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String phoneNumber, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[600], size: 14),
          const SizedBox(width: 8),
          Text(
            phoneNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.diamond,
                color: AppColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'About V Murugan Jewellery',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company Story
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'The journey of V Murugan Jewellery began with a vision—one that was rooted in a deep appreciation for the art of jewellery making and a desire to bring unparalleled craftsmanship to the world. Our Jewellery has grown from a small, passionate endeavour into a respected name in the jewellery industry, known for its commitment to quality and timeless designs.\n\n'
                  'From the very beginning, our focus has been on creating jewellery that is as meaningful as it is beautiful. We believe that jewellery is not just an accessory but a reflection of one\'s personal story. Whether it\'s a symbol of love, a mark of achievement, or a cherished family heirloom, every piece of jewellery has a unique significance, and we take pride in being a part of those special moments.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Contact Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_phone, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Business', 'V Murugan Jewellery'),
                    _buildInfoRow('Email', 'vmuruganjewellers@gmail.com'),
                    _buildInfoRow('Phone', '+91 9677944711'),
                    _buildInfoRow('Website', 'www.vmuruganjewellery.co.in'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'ta' ? 'வெளியேறு' : 'Logout'),
        content: Text(_currentLanguage == 'ta' ? 'நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'ta' ? 'ரத்து செய்' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(context);

              // Perform logout
              await AuthService.logoutUser();

              // Clear all local data
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              print('✅ Logout completed - navigating to onboarding');

              // Navigate to onboarding
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: Text(_currentLanguage == 'ta' ? 'வெளியேறு' : 'Logout'),
          ),
        ],
      ),
    );
  }

  /// Get mock transaction count based on period for testing
  int _getMockTransactionCount(String period) {
    switch (period) {
      case 'current_month':
        return 8; // Moderate number for current month
      case 'last_3_months':
        return 20; // More transactions for 3 months
      case 'all_transactions':
        return 35; // Many transactions for all time
      default:
        return 12; // Default count for custom periods
    }
  }
}
