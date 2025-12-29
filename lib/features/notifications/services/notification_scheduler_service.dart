import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service for scheduling recurring notifications
class NotificationSchedulerService {
  static final NotificationSchedulerService _instance = NotificationSchedulerService._internal();
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the scheduler
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Initialize notifications plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;

    print('✅ Notification Scheduler initialized');
  }

  /// Schedule monthly reminder for Plus schemes
  Future<void> scheduleMonthlyReminder({
    required String schemeId,
    required String schemeName,
    required String schemeType,
    required double monthlyAmount,
    required int monthNumber,
    required int totalMonths,
    required DateTime dueDate,
  }) async {
    await initialize();

    try {
      // Create notification ID from scheme ID
      final notificationId = schemeId.hashCode;

      // Schedule notification 3 days before due date
      final reminderDate = dueDate.subtract(const Duration(days: 3));
      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local);

      // Only schedule if the date is in the future
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('⚠️ Reminder date is in the past, skipping: $reminderDate');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'scheme_reminders',
        'Scheme Payment Reminders',
        channelDescription: 'Monthly reminders for scheme payments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = '💰 Scheme Payment Reminder';
      final body = '$schemeName - Month $monthNumber/$totalMonths payment of ₹${monthlyAmount.toStringAsFixed(2)} is due on ${_formatDate(dueDate)}';

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Also save to notification history
      await NotificationService().createNotification(
        type: NotificationType.schemeReminder,
        title: title,
        message: body,
        priority: NotificationPriority.high,
        data: {
          'scheme_id': schemeId,
          'scheme_name': schemeName,
          'scheme_type': schemeType,
          'month_number': monthNumber,
          'total_months': totalMonths,
          'due_date': dueDate.toIso8601String(),
        },
      );

      print('✅ Scheduled monthly reminder for $schemeName - Month $monthNumber on $reminderDate');
    } catch (e) {
      print('❌ Error scheduling monthly reminder: $e');
    }
  }

  /// Cancel scheduled reminder for a scheme
  Future<void> cancelSchemeReminder(String schemeId) async {
    await initialize();

    try {
      final notificationId = schemeId.hashCode;
      await _notificationsPlugin.cancel(notificationId);
      print('✅ Cancelled reminder for scheme: $schemeId');
    } catch (e) {
      print('❌ Error cancelling reminder: $e');
    }
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await initialize();

    try {
      await _notificationsPlugin.cancelAll();
      print('✅ Cancelled all scheduled reminders');
    } catch (e) {
      print('❌ Error cancelling all reminders: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

