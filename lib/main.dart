import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/responsive.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/phone_entry_screen.dart';
import 'features/portfolio/screens/portfolio_screen.dart';
import 'features/gold/screens/schemes_screen.dart';
import 'features/gold/screens/transaction_history_screen.dart';
import 'features/gold/screens/buy_gold_screen.dart';
import 'features/gold/services/gold_price_service.dart';
import 'features/gold/models/gold_price_model.dart';
import 'features/silver/services/silver_price_service.dart';
import 'features/silver/models/silver_price_model.dart';
import 'features/silver/screens/buy_silver_screen.dart';
import 'features/schemes/services/scheme_management_service.dart';
import 'features/schemes/models/scheme_installment_model.dart';
import 'core/widgets/vmurugan_logo.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/models/notification_model.dart';
import 'core/services/customer_service.dart';

import 'features/auth/screens/enhanced_app_wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/quick_mpin_login_screen.dart';
import 'core/services/auth_service.dart';
import 'core/config/firebase_init.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for free SMS OTP functionality
  await FirebaseInit.initialize();

  runApp(const DigiGoldApp());
}

class DigiGoldApp extends StatelessWidget {
  const DigiGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMUrugan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

/// App initializer that checks login status and routes accordingly
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Small delay to show splash
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Get comprehensive authentication state
      final savedPhone = await AuthService.getSavedPhoneNumber();
      final isLoggedIn = await AuthService.isLoggedIn();

      if (mounted) {
        // Smart login flow based on user state
        if (isLoggedIn && savedPhone != null) {
          // Case 2: Subsequent Logins - User is logged in with saved phone
          // Go directly to home page
          print('✅ Smart Login: Returning user - going to home');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (savedPhone != null && !isLoggedIn) {
          // Case 3: Registered User on New Device - Has phone but not logged in
          // Go to quick MPIN login (no OTP needed)
          print('✅ Smart Login: Registered user on new device - MPIN login');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuickMpinLoginScreen()),
          );
        } else {
          // Case 1: First Time Install - No saved phone
          // Go directly to phone entry screen
          print('✅ Smart Login: First time user - phone entry');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking initial route: $e');
      if (mounted) {
        // On error, go to phone entry
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VMuruganLogo(
              size: 80,
              primaryColor: AppColors.primaryGreen,
              textColor: AppColors.black,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoldPriceService _priceService = GoldPriceService();
  final SilverPriceService _silverPriceService = SilverPriceService();
  final NotificationService _notificationService = NotificationService();
  final SchemeManagementService _schemeService = SchemeManagementService();
  GoldPriceModel? _currentPrice;
  SilverPriceModel? _currentSilverPrice;
  double investmentAmount = 2000.0;
  int _unreadNotificationCount = 0;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _schemeStatus;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app services and load user data
  Future<void> _initializeApp() async {
    try {
      // Load current user data
      final currentUser = await AuthService.getCurrentLoggedInUser();
      setState(() {
        _currentUser = currentUser;
      });

      // Initialize services
      _initializeServices();

      // Load scheme status
      await _loadSchemeStatus();
    } catch (e) {
      print('❌ Error initializing app: $e');
    }
  }

  void _initializeServices() {
    _priceService.initialize();
    _silverPriceService.initialize();
    _notificationService.initialize();

    // Listen to price updates
    _priceService.priceStream.listen((price) {
      if (mounted) {
        setState(() {
          _currentPrice = price;
        });
      }
    });

    // Listen to silver price updates
    _silverPriceService.priceStream.listen((price) {
      if (mounted) {
        setState(() {
          _currentSilverPrice = price;
        });
      }
    });

    // Listen to notification count updates
    _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });

    // Load initial prices
    _loadInitialPrice();
    _loadInitialSilverPrice();
  }

  void _loadInitialPrice() async {
    final price = await _priceService.getCurrentPrice();
    setState(() {
      _currentPrice = price;
    });
  }

  void _loadInitialSilverPrice() async {
    final price = await _silverPriceService.getCurrentPrice();
    setState(() {
      _currentSilverPrice = price;
    });
  }

  Future<void> _loadSchemeStatus() async {
    try {
      if (_currentUser != null && _currentUser!['phone'] != null) {
        final status = await _schemeService.getSchemeStatusForMainScreen(_currentUser!['phone']);
        setState(() {
          _schemeStatus = status;
        });
      }
    } catch (e) {
      print('❌ Error loading scheme status: $e');
    }
  }

  void _showPriceSourceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gold Price Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Source: ${_priceService.priceSource}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Status: ${_priceService.isMjdtaAvailable ? "🟢 MJDTA Live Data" : "🔴 MJDTA Unavailable"}'),
            const SizedBox(height: 8),
            if (!_priceService.isMjdtaAvailable) ...[
              const Text('• MJDTA service is currently unavailable'),
              const Text('• Gold purchases are disabled'),
              const Text('• No price data available'),
              const SizedBox(height: 8),
              const Text(
                '⚠️ We only allow purchases with real-time MJDTA prices',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
              ),
            ] else ...[
              const Text('• Source: MJDTA Chennai (22K)'),
              const Text('• Official South India benchmark'),
              const Text('• Update times: 9:30 AM & 3:30 PM IST'),
              const Text('• Update frequency: Every 2 minutes'),
              const Text('• Purchases enabled with live prices'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Official MJDTA source:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• thejewellersassociation.org'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!_priceService.isMjdtaAvailable)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _priceService.retryMjdtaConnection();
              },
              child: const Text('Retry MJDTA'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldPrice = _currentPrice?.pricePerGram;
    final goldQuantity = goldPrice != null ? investmentAmount / goldPrice : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 32,
          fontSize: 18,
          textColor: Colors.black,
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              // Notification badge
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'help') {
                _showHelpDialog(context);
              } else if (value == 'about') {
                _showAboutDialog(context);
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About VMurugan'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.goldGreenGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VMuruganLogo(
                        size: 50,
                        primaryColor: AppColors.primaryGreen, // Dark Green
                        textColor: AppColors.primaryGold, // Pure Gold
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Welcome to VMurugan',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Start your digital gold investment journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),



            // Gold and Silver Price Cards
            Row(
              children: [
                // Gold Rate Card
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle, color: AppColors.primaryGold, size: 12),
                              const SizedBox(width: 8),
                              Text(
                                'Gold Rate',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            goldPrice != null ? '₹${goldPrice.toStringAsFixed(0)}' : '₹9160',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '22KT Per gram',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Silver Rate Card
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.grey, size: 12),
                              const SizedBox(width: 8),
                              Text(
                                'Silver Rate',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _currentSilverPrice != null ? '₹${_currentSilverPrice!.pricePerGram.toStringAsFixed(2)}' : '₹85.50',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Per gram',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Investment Schemes Section
            Text(
              'Investment Schemes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose from a range of investment products with unique benefits to suit your needs and convenience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // GOLDPLUS Flexi Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.goldGreenGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: const Text(
                      'VMUrugan Plus',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GOLDPLUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'flexi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'GPS | 15 months | 75% benefit on VA*',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.trending_up,
                        color: AppColors.primaryGold,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: const Text(
                            'Know More',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BuyGoldScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            ),
                            child: Text(
                              _schemeStatus?['gold']?['buttonText'] ?? 'Join Now',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // SILVERPLUS Flexi Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[700]!, Colors.grey[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: const Text(
                      'VMUrugan Plus',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SILVERPLUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'flexi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'SPS | 15 months | 65% benefit on VA*',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.trending_up,
                        color: Colors.grey.shade300,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: const Text(
                            'Know More',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BuySilverScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            ),
                            child: Text(
                              _schemeStatus?['silver']?['buttonText'] ?? 'Join Now',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1: // Portfolio
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PortfolioScreen()),
              );
              break;
            case 2: // History
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
              );
              break;
            case 3: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Customer Support: +91 9999999999'),
            SizedBox(height: 8),
            Text('📧 Email: support@vmurugan.com'),
            SizedBox(height: 8),
            Text('🕒 Hours: 9 AM - 6 PM (Mon-Sat)'),
            SizedBox(height: 16),
            Text('💡 Quick Help:'),
            Text('• Buy Gold: Tap "Buy Gold" button'),
            Text('• View Portfolio: Use bottom navigation'),
            Text('• Transaction History: Check History tab'),
            Text('• Profile: Tap profile icon or tab'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text('About VMUrugan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VMUrugan Gold Trading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your trusted partner for digital gold investments.'),
            SizedBox(height: 16),
            Text('✨ Features:'),
            Text('• Live gold prices'),
            Text('• Secure transactions'),
            Text('• Real-time portfolio tracking'),
            Text('• 24/7 digital gold trading'),
            SizedBox(height: 16),
            Text('🏆 Licensed & Regulated'),
            Text('🔒 Bank-grade security'),
            Text('💎 Pure 24K digital gold'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  void _createTestNotification() async {
    // Create a test notification to demonstrate the system
    await NotificationTemplates.adminMessage(
      title: 'Welcome to VMUrugan Gold Trading! 🎉',
      message: 'Thank you for choosing us for your gold investment journey. Start investing with as little as ₹100!',
      priority: NotificationPriority.normal,
    );

    // Also create a test transaction for demo
    await _createTestTransaction();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification and transaction created!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _createTestTransaction() async {
    try {
      // Create a mock successful transaction for demo
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerPhone = customerInfo['phone'] ?? '+91 9876543210';
      final customerName = customerInfo['name'] ?? 'Demo Customer';

      final transactionData = {
        'transaction_id': 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'type': 'BUY',
        'amount': 2000.0,
        'gold_grams': 0.216,
        'gold_price_per_gram': _currentPrice?.pricePerGram ?? 9259.0,
        'payment_method': 'Demo Payment',
        'status': 'SUCCESS',
        'gateway_transaction_id': 'demo_pay_${DateTime.now().millisecondsSinceEpoch}',
        'device_info': 'Demo Device',
        'location': 'Demo Location',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await CustomerService.saveTransactionWithCustomerData(
        transactionId: transactionData['transaction_id'] as String,
        type: transactionData['type'] as String,
        amount: transactionData['amount'] as double,
        goldGrams: transactionData['gold_grams'] as double,
        goldPricePerGram: transactionData['gold_price_per_gram'] as double,
        paymentMethod: transactionData['payment_method'] as String,
        status: transactionData['status'] as String,
        gatewayTransactionId: transactionData['gateway_transaction_id'] as String,
      );

      print('Demo transaction created successfully');
    } catch (e) {
      print('Error creating demo transaction: $e');
    }
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Logout user
        await AuthService.logoutUser();

        // Navigate to phone entry screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
