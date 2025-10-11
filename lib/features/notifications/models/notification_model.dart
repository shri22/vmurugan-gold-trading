class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final NotificationPriority priority;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
    this.priority = NotificationPriority.normal,
    this.imageUrl,
    this.actionUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.general,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      data: json['data'] as Map<String, dynamic>?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'priority': priority.toString(),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (notificationDate == today) {
      return 'Today ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NotificationType {
  // Payment related
  paymentSuccess,
  paymentFailed,
  paymentPending,
  
  // Transaction related
  goldPurchased,
  goldSold,
  schemePayment,
  
  // Price alerts
  priceAlert,
  priceTarget,
  
  // Account related
  kycApproved,
  kycRejected,
  kycPending,
  accountVerified,
  
  // Scheme related
  schemeMatured,
  schemeReminder,
  schemeBonus,
  
  // General
  general,
  promotional,
  systemUpdate,
  maintenance,
  adminMessage,
  announcement,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.paymentSuccess:
        return 'Payment Success';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.paymentPending:
        return 'Payment Pending';
      case NotificationType.goldPurchased:
        return 'Gold Purchased';
      case NotificationType.goldSold:
        return 'Gold Sold';
      case NotificationType.schemePayment:
        return 'Scheme Payment';
      case NotificationType.priceAlert:
        return 'Price Alert';
      case NotificationType.priceTarget:
        return 'Price Target';
      case NotificationType.kycApproved:
        return 'KYC Approved';
      case NotificationType.kycRejected:
        return 'KYC Rejected';
      case NotificationType.kycPending:
        return 'KYC Pending';
      case NotificationType.accountVerified:
        return 'Account Verified';
      case NotificationType.schemeMatured:
        return 'Scheme Matured';
      case NotificationType.schemeReminder:
        return 'Scheme Reminder';
      case NotificationType.schemeBonus:
        return 'Scheme Bonus';
      case NotificationType.general:
        return 'General';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.maintenance:
        return 'Maintenance';
      case NotificationType.adminMessage:
        return 'Admin Message';
      case NotificationType.announcement:
        return 'Announcement';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.paymentSuccess:
        return '✅';
      case NotificationType.paymentFailed:
        return '❌';
      case NotificationType.paymentPending:
        return '⏳';
      case NotificationType.goldPurchased:
        return '🪙';
      case NotificationType.goldSold:
        return '💰';
      case NotificationType.schemePayment:
        return '📅';
      case NotificationType.priceAlert:
        return '📈';
      case NotificationType.priceTarget:
        return '🎯';
      case NotificationType.kycApproved:
        return '✅';
      case NotificationType.kycRejected:
        return '❌';
      case NotificationType.kycPending:
        return '⏳';
      case NotificationType.accountVerified:
        return '🔐';
      case NotificationType.schemeMatured:
        return '🎉';
      case NotificationType.schemeReminder:
        return '⏰';
      case NotificationType.schemeBonus:
        return '🎁';
      case NotificationType.general:
        return 'ℹ️';
      case NotificationType.promotional:
        return '🎯';
      case NotificationType.systemUpdate:
        return '🔄';
      case NotificationType.maintenance:
        return '🔧';
      case NotificationType.adminMessage:
        return '👨‍💼';
      case NotificationType.announcement:
        return '📢';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.normal:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.urgent:
        return 4;
    }
  }
}
