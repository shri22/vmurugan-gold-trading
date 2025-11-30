import '../enums/metal_type.dart';
import 'notification_service.dart';
import '../../features/notifications/models/notification_model.dart';

/// Service for scheduling scheme-related notifications
class NotificationSchedulerService {
  static final NotificationSchedulerService _instance = NotificationSchedulerService._internal();
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();

  final _notificationService = NotificationService();

  /// Schedule monthly reminder for scheme installment
  Future<void> scheduleMonthlyReminder({
    required String schemeId,
    required int installmentNumber,
    required DateTime dueDate,
    required double amount,
    required MetalType metalType,
  }) async {
    try {
      // Calculate notification time (3 days before due date at 10 AM)
      final notificationDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - 3,
        10, // 10 AM
        0,
      );

      // Only schedule if notification date is in the future
      if (notificationDate.isAfter(DateTime.now())) {
        final metalName = metalType == MetalType.gold ? 'Gold' : 'Silver';
        final title = '💰 Scheme Payment Reminder';
        final message = 'Your $metalName scheme installment #$installmentNumber of ₹${amount.toStringAsFixed(2)} is due on ${_formatDate(dueDate)}';

        // Create notification using NotificationService
        await _notificationService.createNotification(
          type: NotificationType.schemeReminder,
          title: title,
          message: message,
          priority: NotificationPriority.high,
          data: {
            'scheme_id': schemeId,
            'installment_number': installmentNumber,
            'due_date': dueDate.toIso8601String(),
            'amount': amount,
          },
        );

        print('✅ Created reminder for $schemeId installment $installmentNumber on ${_formatDate(notificationDate)}');
      } else {
        print('⚠️ Skipping notification for past date: ${_formatDate(notificationDate)}');
      }
    } catch (e) {
      print('❌ Error scheduling monthly reminder: $e');
      // Don't rethrow - we don't want to fail scheme creation if notification fails
    }
  }

  /// Send confirmation notification after Flexi payment
  Future<void> sendFlexiPaymentConfirmation({
    required String schemeId,
    required double amount,
    required double metalGrams,
  }) async {
    try {
      final title = '✅ Payment Successful';
      final message = 'Your Flexi payment of ₹${amount.toStringAsFixed(2)} has been processed. You received ${metalGrams.toStringAsFixed(4)}g of metal.';

      await _notificationService.createNotification(
        type: NotificationType.paymentSuccess,
        title: title,
        message: message,
        priority: NotificationPriority.normal,
        data: {
          'scheme_id': schemeId,
          'amount': amount,
          'metal_grams': metalGrams,
        },
      );

      print('✅ Sent Flexi payment confirmation for $schemeId');
    } catch (e) {
      print('❌ Error sending Flexi payment confirmation: $e');
      // Don't rethrow - we don't want to fail payment if notification fails
    }
  }

  /// Cancel all notifications for a scheme (placeholder - not implemented in current NotificationService)
  Future<void> cancelSchemeNotifications(String schemeId) async {
    try {
      // This would require additional implementation in NotificationService
      // For now, just log
      print('⚠️ Cancel scheme notifications not fully implemented for $schemeId');
    } catch (e) {
      print('❌ Error cancelling scheme notifications: $e');
    }
  }

  /// Generate unique notification ID from scheme ID and installment number
  int _generateNotificationId(String schemeId, int installmentNumber) {
    // Use hash code of scheme ID combined with installment number
    // Ensure it's a positive 32-bit integer
    final hash = schemeId.hashCode.abs() % 1000000;
    return (hash * 100) + installmentNumber;
  }

  /// Format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

