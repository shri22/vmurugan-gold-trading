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
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.failed,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }

  factory PaymentResponse.cancelled({
    required String transactionId,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.cancelled,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }

  factory PaymentResponse.pending({
    required String transactionId,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.pending,
      timestamp: DateTime.now(),
      additionalData: additionalData,
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
  // UPI Methods (existing)
  gpay,
  phonepe,
  upiIntent,
  qrCode,

  // Omniware Gateway Methods
  omniwareNetbanking,  // Available in testing environment
  omniwareUpi,         // Available in live environment
  omniwareCard,        // Available in live environment
  omniwareWallet,      // Available in live environment
  omniwareEmi,         // Available in live environment
}

extension PaymentMethodExtension on PaymentMethod {
  /// Get display name for payment method
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
      case PaymentMethod.omniwareNetbanking:
        return 'Net Banking';
      case PaymentMethod.omniwareUpi:
        return 'UPI';
      case PaymentMethod.omniwareCard:
        return 'Credit/Debit Card';
      case PaymentMethod.omniwareWallet:
        return 'Digital Wallet';
      case PaymentMethod.omniwareEmi:
        return 'EMI';
    }
  }

  /// Check if this is an Omniware payment method
  bool get isOmniware {
    switch (this) {
      case PaymentMethod.omniwareNetbanking:
      case PaymentMethod.omniwareUpi:
      case PaymentMethod.omniwareCard:
      case PaymentMethod.omniwareWallet:
      case PaymentMethod.omniwareEmi:
        return true;
      default:
        return false;
    }
  }

  /// Check if this method is available in testing environment
  bool get isAvailableInTesting {
    switch (this) {
      case PaymentMethod.omniwareNetbanking:
        return true; // Only netbanking available in testing
      case PaymentMethod.gpay:
      case PaymentMethod.phonepe:
      case PaymentMethod.upiIntent:
      case PaymentMethod.qrCode:
        return true; // UPI methods always available
      default:
        return false; // Other Omniware methods only in live
    }
  }

  /// Get Omniware payment method string
  String get omniwareMethodString {
    switch (this) {
      case PaymentMethod.omniwareNetbanking:
        return 'netbanking';
      case PaymentMethod.omniwareUpi:
        return 'upi';
      case PaymentMethod.omniwareCard:
        return 'card';
      case PaymentMethod.omniwareWallet:
        return 'wallet';
      case PaymentMethod.omniwareEmi:
        return 'emi';
      default:
        return 'netbanking'; // Default fallback
    }
  }
}

enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
  timeout,
}



class UpiConfig {
  static const String merchantName = 'Digi Gold';
  static const String merchantCode = 'DIGIGOLD';

  // Single UPI ID for all payment methods
  static const String gpayUpiId = 'vmuruganjew2127@fbl';    // V Murugan Gold Trading UPI ID
  static const String phonepeUpiId = 'vmuruganjew2127@fbl'; // V Murugan Gold Trading UPI ID
  static const String defaultUpiId = 'vmuruganjew2127@fbl'; // V Murugan Gold Trading UPI ID

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
  static const String gpayScheme = 'gpay://upi/pay';        // Updated Google Pay scheme
  static const String phonepeScheme = 'phonepe://pay';
  static const String upiScheme = 'upi://pay';
  
  // Fallback URLs if apps not installed
  static const String gpayPlayStore = 'https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user';
  static const String phonepePlayStore = 'https://play.google.com/store/apps/details?id=com.phonepe.app';
}

/// Omniware Payment Gateway Response Model
class OmniwarePaymentResponse {
  final bool success;
  final String transactionId;
  final String? paymentUrl;
  final String? gatewayTransactionId;
  final String? message;
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  OmniwarePaymentResponse({
    required this.success,
    required this.transactionId,
    this.paymentUrl,
    this.gatewayTransactionId,
    this.message,
    this.errorMessage,
    this.additionalData,
  });

  factory OmniwarePaymentResponse.fromJson(Map<String, dynamic> json) {
    return OmniwarePaymentResponse(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'] ?? '',
      paymentUrl: json['payment_url'],
      gatewayTransactionId: json['gateway_transaction_id'],
      message: json['message'],
      errorMessage: json['error_message'],
      additionalData: json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transaction_id': transactionId,
      'payment_url': paymentUrl,
      'gateway_transaction_id': gatewayTransactionId,
      'message': message,
      'error_message': errorMessage,
      'additional_data': additionalData,
    };
  }

  @override
  String toString() {
    return 'OmniwarePaymentResponse(success: $success, transactionId: $transactionId, paymentUrl: $paymentUrl)';
  }
}

/// Omniware Payment Status Model
class OmniwarePaymentStatus {
  final String transactionId;
  final String status; // SUCCESS, FAILED, PENDING, CANCELLED, ERROR
  final String? gatewayTransactionId;
  final String? amount;
  final String? message;
  final String? timestamp;
  final Map<String, dynamic>? additionalData;

  OmniwarePaymentStatus({
    required this.transactionId,
    required this.status,
    this.gatewayTransactionId,
    this.amount,
    this.message,
    this.timestamp,
    this.additionalData,
  });

  /// Check if payment was successful
  bool get isSuccess => status.toUpperCase() == 'SUCCESS';

  /// Check if payment failed
  bool get isFailed => status.toUpperCase() == 'FAILED';

  /// Check if payment is pending
  bool get isPending => status.toUpperCase() == 'PENDING';

  /// Check if payment was cancelled
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Convert to PaymentResponse for compatibility
  PaymentResponse toPaymentResponse() {
    if (isSuccess) {
      return PaymentResponse.success(
        transactionId: transactionId,
        gatewayTransactionId: gatewayTransactionId ?? '',
        additionalData: {
          'omniware_status': status,
          'amount': amount,
          'timestamp': timestamp,
          'message': message,
          ...?additionalData,
        },
      );
    } else if (isFailed) {
      return PaymentResponse.failed(
        transactionId: transactionId,
        errorMessage: message ?? 'Payment failed',
        additionalData: additionalData,
      );
    } else if (isCancelled) {
      return PaymentResponse.cancelled(
        transactionId: transactionId,
        additionalData: additionalData,
      );
    } else {
      return PaymentResponse.pending(
        transactionId: transactionId,
        additionalData: {
          'omniware_status': status,
          'message': message,
          ...?additionalData,
        },
      );
    }
  }

  factory OmniwarePaymentStatus.fromJson(Map<String, dynamic> json) {
    return OmniwarePaymentStatus(
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      gatewayTransactionId: json['gateway_transaction_id'],
      amount: json['amount']?.toString(),
      message: json['message'],
      timestamp: json['timestamp'],
      additionalData: json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'status': status,
      'gateway_transaction_id': gatewayTransactionId,
      'amount': amount,
      'message': message,
      'timestamp': timestamp,
      'additional_data': additionalData,
    };
  }

  @override
  String toString() {
    return 'OmniwarePaymentStatus(transactionId: $transactionId, status: $status, amount: $amount)';
  }
}
