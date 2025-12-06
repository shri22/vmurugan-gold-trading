import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/config/client_server_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<List<NotificationModel>> _notificationsController = 
      StreamController<List<NotificationModel>>.broadcast();
  final StreamController<int> _unreadCountController = 
      StreamController<int>.broadcast();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  // Streams
  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Getters
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  // Initialize service
  Future<void> initialize() async {
    await _loadNotifications();
    _updateUnreadCount();
  }

  // Create a new notification
  Future<NotificationModel> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    String? imageUrl,
    String? actionUrl,
  }) async {
    // Check if user has enabled this notification type
    final isEnabled = await _isNotificationTypeEnabled(type);
    if (!isEnabled) {
      print('Notification type ${type.toString()} is disabled by user');
      // Return a dummy notification that won't be shown
      return NotificationModel(
        id: 'disabled_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'disabled',
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        data: data,
        priority: priority,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );
    }

    final customerInfo = await CustomerService.getCustomerInfo();
    final userId = customerInfo['phone'] ?? 'unknown';

    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
      priority: priority,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    await _addNotification(notification);
    return notification;
  }

  // Check if notification type is enabled by user
  Future<bool> _isNotificationTypeEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_${type.toString()}') ?? true; // Default enabled
  }

  // Add notification to list and save
  Future<void> _addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification); // Add to beginning
    await _saveNotifications();
    _updateUnreadCount();
    _notificationsController.add(_notifications);
    _unreadCountController.add(_unreadCount);

    // Save to Firebase if configured
    await _saveToFirebase(notification);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await _saveNotifications();
      _updateUnreadCount();
      _notificationsController.add(_notifications);
      _unreadCountController.add(_unreadCount);
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveNotifications();
      _updateUnreadCount();
      _notificationsController.add(_notifications);
      _unreadCountController.add(_unreadCount);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    _updateUnreadCount();
    _notificationsController.add(_notifications);
    _unreadCountController.add(_unreadCount);
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    _updateUnreadCount();
    _notificationsController.add(_notifications);
    _unreadCountController.add(_unreadCount);
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Update unread count
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications = notificationsList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        
        // Sort by creation date (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Save notification to Firebase
  Future<void> _saveToFirebase(NotificationModel notification) async {
    try {
      await FirebaseService.saveNotification(
        notificationId: notification.id,
        userId: notification.userId,
        type: notification.type.toString(),
        title: notification.title,
        message: notification.message,
        data: notification.data ?? {},
        priority: notification.priority.toString(),
      );
    } catch (e) {
      print('Error saving notification to Firebase: $e');
    }
  }

  // Sync notifications from backend
  Future<void> syncNotificationsFromBackend(String userPhone) async {
    try {
      print('🔄 Syncing notifications from backend for user: $userPhone');

      final response = await http.get(
        Uri.parse('${ClientServerConfig.baseUrl}/notifications/$userPhone'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final backendNotifications = (data['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          // Merge with local notifications (avoid duplicates)
          int newCount = 0;
          for (final backendNotif in backendNotifications) {
            if (!_notifications.any((n) => n.id == backendNotif.id)) {
              _notifications.add(backendNotif);
              newCount++;
            }
          }

          // Sort by date (newest first)
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Save to local storage
          await _saveNotifications();

          // Update streams
          _updateUnreadCount();
          _notificationsController.add(_notifications);
          _unreadCountController.add(_unreadCount);

          print('✅ Synced $newCount new notifications from backend (Total: ${backendNotifications.length})');
        }
      } else {
        print('⚠️ Backend sync failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Failed to sync notifications from backend: $e');
    }
  }

  // Auto-sync timer
  Timer? _syncTimer;

  // Start auto-sync (every 5 minutes)
  void startAutoSync(String userPhone) {
    print('🔄 Starting auto-sync for notifications (every 5 minutes)');
    _syncTimer?.cancel();

    // Initial sync
    syncNotificationsFromBackend(userPhone);

    // Periodic sync
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncNotificationsFromBackend(userPhone);
    });
  }

  // Stop auto-sync
  void stopAutoSync() {
    print('⏹️ Stopping auto-sync for notifications');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Mark notification as read on backend
  Future<void> markAsReadOnBackend(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${ClientServerConfig.baseUrl}/notifications/$notificationId/read'),
      );

      if (response.statusCode == 200) {
        print('✅ Notification marked as read on backend: $notificationId');
      }
    } catch (e) {
      print('⚠️ Failed to mark notification as read on backend: $e');
    }
  }

  // Dispose resources
  void dispose() {
    stopAutoSync();
    _notificationsController.close();
    _unreadCountController.close();
  }
}

// Notification templates for common scenarios
class NotificationTemplates {
  // Payment success notification
  static Future<NotificationModel> paymentSuccess({
    required String transactionId,
    required double amount,
    double? goldGrams,
    String? paymentMethod,
  }) async {
    String message;
    if (goldGrams != null) {
      message = 'Your payment of ₹${amount.toStringAsFixed(2)} was successful. You have purchased ${goldGrams.toStringAsFixed(3)}g of gold.';
    } else {
      message = 'Your payment of ₹${amount.toStringAsFixed(2)} was successful!';
    }

    return await NotificationService().createNotification(
      type: NotificationType.paymentSuccess,
      title: 'Payment Successful! 🎉',
      message: message,
      priority: NotificationPriority.high,
      data: {
        'transactionId': transactionId,
        'amount': amount,
        if (goldGrams != null) 'goldGrams': goldGrams,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
    );
  }

  // Payment failed notification
  static Future<NotificationModel> paymentFailed({
    required double amount,
    required String reason,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.paymentFailed,
      title: 'Payment Failed ❌',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} failed. Reason: $reason',
      priority: NotificationPriority.high,
      data: {
        'amount': amount,
        'reason': reason,
      },
    );
  }

  // Payment cancelled notification
  static Future<NotificationModel> paymentCancelled({
    required double amount,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.paymentFailed, // Reuse paymentFailed type for cancelled
      title: 'Payment Cancelled ⚠️',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} was cancelled.',
      priority: NotificationPriority.normal,
      data: {
        'amount': amount,
        'status': 'cancelled',
      },
    );
  }

  // Gold purchase notification
  static Future<NotificationModel> goldPurchased({
    required double goldGrams,
    required double pricePerGram,
    required double totalAmount,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.goldPurchased,
      title: 'Gold Purchased Successfully! 🪙',
      message: 'You have successfully purchased ${goldGrams.toStringAsFixed(3)}g of gold at ₹${pricePerGram.toStringAsFixed(2)}/gram.',
      priority: NotificationPriority.normal,
      data: {
        'goldGrams': goldGrams,
        'pricePerGram': pricePerGram,
        'totalAmount': totalAmount,
      },
    );
  }

  // Scheme payment notification
  static Future<NotificationModel> schemePayment({
    required String schemeName,
    required double amount,
    required int monthNumber,
    required int totalMonths,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.schemePayment,
      title: 'Scheme Payment Successful! 📅',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} for $schemeName (Month $monthNumber/$totalMonths) was successful.',
      priority: NotificationPriority.normal,
      data: {
        'schemeName': schemeName,
        'amount': amount,
        'monthNumber': monthNumber,
        'totalMonths': totalMonths,
      },
    );
  }

  // Price alert notification
  static Future<NotificationModel> priceAlert({
    required double currentPrice,
    required double targetPrice,
    required String condition, // 'above' or 'below'
  }) async {
    final isAbove = condition.toLowerCase() == 'above';
    return await NotificationService().createNotification(
      type: NotificationType.priceAlert,
      title: 'Price Alert Triggered! 📈',
      message: 'Gold price is now ${isAbove ? 'above' : 'below'} your target of ₹${targetPrice.toStringAsFixed(2)}. Current price: ₹${currentPrice.toStringAsFixed(2)}',
      priority: NotificationPriority.high,
      data: {
        'currentPrice': currentPrice,
        'targetPrice': targetPrice,
        'condition': condition,
      },
    );
  }

  // Admin message notification
  static Future<NotificationModel> adminMessage({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.adminMessage,
      title: title,
      message: message,
      priority: priority,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      data: {
        'isAdminMessage': true,
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Payment pending notification
  static Future<NotificationModel> paymentPending({
    required double amount,
    required String transactionId,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.paymentPending,
      title: 'Payment Processing ⏳',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} is being processed. Transaction ID: $transactionId',
      priority: NotificationPriority.normal,
      data: {
        'amount': amount,
        'transactionId': transactionId,
      },
    );
  }

  // Gold sold notification
  static Future<NotificationModel> goldSold({
    required double goldGrams,
    required double pricePerGram,
    required double totalAmount,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.goldSold,
      title: 'Gold Sold Successfully! 💰',
      message: 'You have successfully sold ${goldGrams.toStringAsFixed(3)}g of gold at ₹${pricePerGram.toStringAsFixed(2)}/gram for ₹${totalAmount.toStringAsFixed(2)}.',
      priority: NotificationPriority.high,
      data: {
        'goldGrams': goldGrams,
        'pricePerGram': pricePerGram,
        'totalAmount': totalAmount,
      },
    );
  }

  // Price target notification
  static Future<NotificationModel> priceTarget({
    required double currentPrice,
    required double targetPrice,
    required String metalType,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.priceTarget,
      title: 'Price Target Reached! 🎯',
      message: '$metalType price has reached your target of ₹${targetPrice.toStringAsFixed(2)}. Current price: ₹${currentPrice.toStringAsFixed(2)}',
      priority: NotificationPriority.high,
      data: {
        'currentPrice': currentPrice,
        'targetPrice': targetPrice,
        'metalType': metalType,
      },
    );
  }

  // KYC approved notification
  static Future<NotificationModel> kycApproved() async {
    return await NotificationService().createNotification(
      type: NotificationType.kycApproved,
      title: 'KYC Approved! ✅',
      message: 'Congratulations! Your KYC verification has been approved. You can now access all features.',
      priority: NotificationPriority.high,
      data: {
        'approvedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // KYC rejected notification
  static Future<NotificationModel> kycRejected({
    required String reason,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.kycRejected,
      title: 'KYC Rejected ❌',
      message: 'Your KYC verification was rejected. Reason: $reason. Please resubmit with correct documents.',
      priority: NotificationPriority.urgent,
      data: {
        'reason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // KYC pending notification
  static Future<NotificationModel> kycPending() async {
    return await NotificationService().createNotification(
      type: NotificationType.kycPending,
      title: 'KYC Verification Pending ⏳',
      message: 'Your KYC documents have been submitted and are under review. We will notify you once verified.',
      priority: NotificationPriority.normal,
      data: {
        'submittedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Account verified notification
  static Future<NotificationModel> accountVerified() async {
    return await NotificationService().createNotification(
      type: NotificationType.accountVerified,
      title: 'Account Verified! 🔐',
      message: 'Your account has been successfully verified. Welcome to VMurugan Gold Trading!',
      priority: NotificationPriority.high,
      data: {
        'verifiedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Scheme matured notification
  static Future<NotificationModel> schemeMatured({
    required String schemeName,
    required double totalAmount,
    required double bonusAmount,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.schemeMatured,
      title: 'Scheme Matured! 🎉',
      message: 'Congratulations! Your $schemeName has matured. Total amount: ₹${totalAmount.toStringAsFixed(2)} + Bonus: ₹${bonusAmount.toStringAsFixed(2)}',
      priority: NotificationPriority.urgent,
      data: {
        'schemeName': schemeName,
        'totalAmount': totalAmount,
        'bonusAmount': bonusAmount,
        'maturedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Scheme reminder notification
  static Future<NotificationModel> schemeReminder({
    required String schemeName,
    required double amount,
    required int daysRemaining,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.schemeReminder,
      title: 'Scheme Payment Reminder ⏰',
      message: 'Your $schemeName payment of ₹${amount.toStringAsFixed(2)} is due in $daysRemaining days.',
      priority: NotificationPriority.high,
      data: {
        'schemeName': schemeName,
        'amount': amount,
        'daysRemaining': daysRemaining,
      },
    );
  }

  // Scheme bonus notification
  static Future<NotificationModel> schemeBonus({
    required String schemeName,
    required double bonusAmount,
    required String reason,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.schemeBonus,
      title: 'Scheme Bonus Received! 🎁',
      message: 'You have received a bonus of ₹${bonusAmount.toStringAsFixed(2)} for your $schemeName. Reason: $reason',
      priority: NotificationPriority.high,
      data: {
        'schemeName': schemeName,
        'bonusAmount': bonusAmount,
        'reason': reason,
      },
    );
  }

  // General notification
  static Future<NotificationModel> general({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.general,
      title: title,
      message: message,
      priority: NotificationPriority.normal,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      data: {
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Promotional notification
  static Future<NotificationModel> promotional({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.promotional,
      title: title,
      message: message,
      priority: NotificationPriority.low,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      data: {
        'isPromotional': true,
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // System update notification
  static Future<NotificationModel> systemUpdate({
    required String title,
    required String message,
    String? version,
    String? actionUrl,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.systemUpdate,
      title: title,
      message: message,
      priority: NotificationPriority.normal,
      actionUrl: actionUrl,
      data: {
        if (version != null) 'version': version,
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Maintenance notification
  static Future<NotificationModel> maintenance({
    required String title,
    required String message,
    DateTime? scheduledAt,
    int? durationMinutes,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.maintenance,
      title: title,
      message: message,
      priority: NotificationPriority.urgent,
      data: {
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Announcement notification
  static Future<NotificationModel> announcement({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.announcement,
      title: title,
      message: message,
      priority: NotificationPriority.high,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      data: {
        'isAnnouncement': true,
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
