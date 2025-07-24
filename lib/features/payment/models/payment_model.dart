class PaymentRequest {
  final String transactionId;
  final double amount;
  final String currency;
  final String merchantName;
  final String merchantUpiId;
  final String description;
  final PaymentMethod method;

  PaymentRequest({
    required this.transactionId,
    required this.amount,
    this.currency = 'INR',
    required this.merchantName,
    required this.merchantUpiId,
    required this.description,
    required this.method,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'merchantName': merchantName,
      'merchantUpiId': merchantUpiId,
      'description': description,
      'method': method.toString(),
    };
  }
}

class PaymentResponse {
  final String transactionId;
  final PaymentStatus status;
  final String? gatewayTransactionId;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  PaymentResponse({
    required this.transactionId,
    required this.status,
    this.gatewayTransactionId,
    this.errorMessage,
    required this.timestamp,
    this.additionalData,
  });

  factory PaymentResponse.success({
    required String transactionId,
    required String gatewayTransactionId,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.success,
      gatewayTransactionId: gatewayTransactionId,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }

  factory PaymentResponse.failed({
    required String transactionId,
    required String errorMessage,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.failed,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResponse.cancelled({
    required String transactionId,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.cancelled,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status.toString(),
      'gatewayTransactionId': gatewayTransactionId,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}

enum PaymentMethod {
  gpay,
  phonepe,
  upiIntent,
  qrCode,
}

enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
  timeout,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.gpay:
        return 'Google Pay';
      case PaymentMethod.phonepe:
        return 'PhonePe';
      case PaymentMethod.upiIntent:
        return 'UPI Apps';
      case PaymentMethod.qrCode:
        return 'QR Code';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.gpay:
        return '🟢'; // GPay icon
      case PaymentMethod.phonepe:
        return '🟣'; // PhonePe icon
      case PaymentMethod.upiIntent:
        return '💳'; // UPI icon
      case PaymentMethod.qrCode:
        return '📱'; // QR icon
    }
  }

  String get packageName {
    switch (this) {
      case PaymentMethod.gpay:
        return 'com.google.android.apps.nbu.paisa.user';
      case PaymentMethod.phonepe:
        return 'com.phonepe.app';
      case PaymentMethod.upiIntent:
        return '';
      case PaymentMethod.qrCode:
        return '';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Processing';
      case PaymentStatus.success:
        return 'Successful';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.timeout:
        return 'Timeout';
    }
  }

  String get icon {
    switch (this) {
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.success:
        return '✅';
      case PaymentStatus.failed:
        return '❌';
      case PaymentStatus.cancelled:
        return '🚫';
      case PaymentStatus.timeout:
        return '⏰';
    }
  }
}

class UpiConfig {
  static const String merchantName = 'Digi Gold';
  static const String merchantCode = 'DIGIGOLD';

  // Different UPI IDs for different payment methods
  static const String gpayUpiId = 'louismary@okicici';      // Google Pay UPI ID
  static const String phonepeUpiId = 'rockstarphpe@ibl';    // PhonePe UPI ID
  static const String defaultUpiId = 'louismary@okicici';   // Default for other UPI apps

  // Get UPI ID based on payment method
  static String getUpiId(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.gpay:
        return gpayUpiId;
      case PaymentMethod.phonepe:
        return phonepeUpiId;
      case PaymentMethod.upiIntent:
      case PaymentMethod.qrCode:
      default:
        return defaultUpiId;
    }
  }
  
  // UPI URL schemes
  static const String gpayScheme = 'tez://upi/pay';
  static const String phonepeScheme = 'phonepe://pay';
  static const String upiScheme = 'upi://pay';
  
  // Fallback URLs if apps not installed
  static const String gpayPlayStore = 'https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user';
  static const String phonepePlayStore = 'https://play.google.com/store/apps/details?id=com.phonepe.app';
}
