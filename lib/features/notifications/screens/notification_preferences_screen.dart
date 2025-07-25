import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../models/notification_model.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  Map<NotificationType, bool> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Default all notification types to enabled
      for (final type in NotificationType.values) {
        _preferences[type] = prefs.getBool('notification_${type.toString()}') ?? true;
      }
      _isLoading = false;
    });
  }

  Future<void> _savePreference(NotificationType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_${type.toString()}', enabled);
    
    setState(() {
      _preferences[type] = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPaymentNotifications(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTransactionNotifications(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPriceNotifications(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAccountNotifications(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSchemeNotifications(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGeneralNotifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: AppColors.primary, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Notification Preferences',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose which notifications you want to receive. You can always change these settings later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentNotifications() {
    return _buildNotificationSection(
      title: 'Payment Notifications',
      icon: Icons.payment,
      color: Colors.green,
      types: [
        NotificationType.paymentSuccess,
        NotificationType.paymentFailed,
        NotificationType.paymentPending,
      ],
    );
  }

  Widget _buildTransactionNotifications() {
    return _buildNotificationSection(
      title: 'Transaction Notifications',
      icon: Icons.swap_horiz,
      color: AppColors.primaryGold,
      types: [
        NotificationType.goldPurchased,
        NotificationType.goldSold,
      ],
    );
  }

  Widget _buildPriceNotifications() {
    return _buildNotificationSection(
      title: 'Price Alerts',
      icon: Icons.trending_up,
      color: Colors.blue,
      types: [
        NotificationType.priceAlert,
        NotificationType.priceTarget,
      ],
    );
  }

  Widget _buildAccountNotifications() {
    return _buildNotificationSection(
      title: 'Account Notifications',
      icon: Icons.account_circle,
      color: Colors.purple,
      types: [
        NotificationType.kycApproved,
        NotificationType.kycRejected,
        NotificationType.kycPending,
        NotificationType.accountVerified,
      ],
    );
  }

  Widget _buildSchemeNotifications() {
    return _buildNotificationSection(
      title: 'Scheme Notifications',
      icon: Icons.savings,
      color: Colors.orange,
      types: [
        NotificationType.schemePayment,
        NotificationType.schemeMatured,
        NotificationType.schemeReminder,
        NotificationType.schemeBonus,
      ],
    );
  }

  Widget _buildGeneralNotifications() {
    return _buildNotificationSection(
      title: 'General Notifications',
      icon: Icons.info,
      color: Colors.grey,
      types: [
        NotificationType.general,
        NotificationType.promotional,
        NotificationType.systemUpdate,
        NotificationType.maintenance,
        NotificationType.adminMessage,
        NotificationType.announcement,
      ],
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<NotificationType> types,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...types.map((type) => _buildNotificationToggle(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(NotificationType type) {
    final isEnabled = _preferences[type] ?? true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            type.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getNotificationDescription(type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) => _savePreference(type, value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  String _getNotificationDescription(NotificationType type) {
    switch (type) {
      case NotificationType.paymentSuccess:
        return 'When your payments are successful';
      case NotificationType.paymentFailed:
        return 'When payments fail or are declined';
      case NotificationType.paymentPending:
        return 'When payments are being processed';
      case NotificationType.goldPurchased:
        return 'When you successfully buy gold';
      case NotificationType.goldSold:
        return 'When you sell gold from your portfolio';
      case NotificationType.schemePayment:
        return 'When scheme payments are made';
      case NotificationType.priceAlert:
        return 'When gold prices reach your targets';
      case NotificationType.priceTarget:
        return 'Price target notifications';
      case NotificationType.kycApproved:
        return 'When your KYC is approved';
      case NotificationType.kycRejected:
        return 'When KYC verification fails';
      case NotificationType.kycPending:
        return 'KYC status updates';
      case NotificationType.accountVerified:
        return 'Account verification confirmations';
      case NotificationType.schemeMatured:
        return 'When your schemes mature';
      case NotificationType.schemeReminder:
        return 'Scheme payment reminders';
      case NotificationType.schemeBonus:
        return 'Scheme bonus notifications';
      case NotificationType.general:
        return 'General app notifications';
      case NotificationType.promotional:
        return 'Special offers and promotions';
      case NotificationType.systemUpdate:
        return 'App updates and new features';
      case NotificationType.maintenance:
        return 'Maintenance and downtime alerts';
      case NotificationType.adminMessage:
        return 'Important messages from admin';
      case NotificationType.announcement:
        return 'Company announcements';
    }
  }
}
