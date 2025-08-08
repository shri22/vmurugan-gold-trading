import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/firebase_service.dart';

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

  // Dispose resources
  void dispose() {
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
    required double goldGrams,
    required String paymentMethod,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.paymentSuccess,
      title: 'Payment Successful! 🎉',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} was successful. You have purchased ${goldGrams.toStringAsFixed(3)}g of gold.',
      priority: NotificationPriority.high,
      data: {
        'transactionId': transactionId,
        'amount': amount,
        'goldGrams': goldGrams,
        'paymentMethod': paymentMethod,
      },
    );
  }

  // Payment failed notification
  static Future<NotificationModel> paymentFailed({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    return await NotificationService().createNotification(
      type: NotificationType.paymentFailed,
      title: 'Payment Failed ❌',
      message: 'Your payment of ₹${amount.toStringAsFixed(2)} failed. Reason: $reason',
      priority: NotificationPriority.high,
      data: {
        'transactionId': transactionId,
        'amount': amount,
        'reason': reason,
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
}
