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

  // Paynimo Gateway Methods
  paynimoCard,         // Credit/Debit Card
  paynimoNetbanking,   // Net Banking
  paynimoUpi,          // UPI
  paynimoWallet,       // Digital Wallet
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
      case PaymentMethod.paynimoCard:
        return 'Credit/Debit Card';
      case PaymentMethod.paynimoNetbanking:
        return 'Net Banking';
      case PaymentMethod.paynimoUpi:
        return 'UPI';
      case PaymentMethod.paynimoWallet:
        return 'Digital Wallet';
    }
  }

  /// Check if this method is available in testing environment
  bool get isAvailableInTesting {
    switch (this) {
      case PaymentMethod.gpay:
      case PaymentMethod.phonepe:
      case PaymentMethod.upiIntent:
      case PaymentMethod.qrCode:
      case PaymentMethod.paynimoCard:
      case PaymentMethod.paynimoNetbanking:
      case PaymentMethod.paynimoUpi:
      case PaymentMethod.paynimoWallet:
        return true; // All methods available in testing
      default:
        return false;
    }
  }

  /// Get Paynimo payment method string
  String get paynimoMethodString {
    switch (this) {
      case PaymentMethod.paynimoCard:
        return 'credit_card';
      case PaymentMethod.paynimoNetbanking:
        return 'net_banking';
      case PaymentMethod.paynimoUpi:
        return 'upi';
      case PaymentMethod.paynimoWallet:
        return 'wallet';
      default:
        return 'credit_card'; // Default fallback
    }
  }



  /// Check if method is a Paynimo gateway method
  bool get isPaynimoMethod {
    switch (this) {
      case PaymentMethod.paynimoCard:
      case PaymentMethod.paynimoNetbanking:
      case PaymentMethod.paynimoUpi:
      case PaymentMethod.paynimoWallet:
        return true;
      default:
        return false;
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





// =============================================================================
// PAYNIMO PAYMENT MODELS
// =============================================================================

/// Paynimo Payment Response Model
class PaynimoPaymentResponse {
  final bool success;
  final String transactionId;
  final String? paymentId;
  final String? gatewayTransactionId;
  final String? paymentUrl;
  final String? message;
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  PaynimoPaymentResponse({
    required this.success,
    required this.transactionId,
    this.paymentId,
    this.gatewayTransactionId,
    this.paymentUrl,
    this.message,
    this.errorMessage,
    this.additionalData,
  });

  factory PaynimoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaynimoPaymentResponse(
      success: json['success'] ?? false,
      transactionId: json['transactionId'] ?? '',
      paymentId: json['paymentId'],
      gatewayTransactionId: json['gatewayTransactionId'],
      paymentUrl: json['paymentUrl'],
      message: json['message'],
      errorMessage: json['errorMessage'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'paymentId': paymentId,
      'gatewayTransactionId': gatewayTransactionId,
      'paymentUrl': paymentUrl,
      'message': message,
      'errorMessage': errorMessage,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'PaynimoPaymentResponse(success: $success, transactionId: $transactionId, paymentId: $paymentId)';
  }
}

/// Paynimo Payment Status Model
class PaynimoPaymentStatus {
  final String transactionId;
  final String status;
  final String message;
  final String? gatewayTransactionId;
  final String? amount;
  final String? paymentMethod;
  final String? timestamp;
  final Map<String, dynamic>? additionalData;

  PaynimoPaymentStatus({
    required this.transactionId,
    required this.status,
    required this.message,
    this.gatewayTransactionId,
    this.amount,
    this.paymentMethod,
    this.timestamp,
    this.additionalData,
  });

  factory PaynimoPaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaynimoPaymentStatus(
      transactionId: json['transactionId'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      message: json['message'] ?? '',
      gatewayTransactionId: json['gatewayTransactionId'],
      amount: json['amount'],
      paymentMethod: json['paymentMethod'],
      timestamp: json['timestamp'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'message': message,
      'gatewayTransactionId': gatewayTransactionId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp,
      'additionalData': additionalData,
    };
  }

  /// Check if payment was successful
  bool get isSuccess => status.toUpperCase() == 'SUCCESS';

  /// Check if payment failed
  bool get isFailed => status.toUpperCase() == 'FAILED';

  /// Check if payment is pending
  bool get isPending => status.toUpperCase() == 'PENDING';

  /// Convert to PaymentResponse for compatibility
  PaymentResponse toPaymentResponse() {
    if (isSuccess) {
      return PaymentResponse.success(
        transactionId: transactionId,
        gatewayTransactionId: gatewayTransactionId ?? '',
        additionalData: {
          'paynimo_status': status,
          'amount': amount,
          'timestamp': timestamp,
          'message': message,
          'paymentMethod': paymentMethod,
          ...?additionalData,
        },
      );
    } else if (isFailed) {
      return PaymentResponse.failed(
        transactionId: transactionId,
        errorMessage: message,
        additionalData: additionalData,
      );
    } else {
      return PaymentResponse.pending(
        transactionId: transactionId,
        additionalData: {
          'paynimo_status': status,
          'message': message,
          'paymentMethod': paymentMethod,
          ...?additionalData,
        },
      );
    }
  }

  @override
  String toString() {
    return 'PaynimoPaymentStatus(transactionId: $transactionId, status: $status, amount: $amount)';
  }
}
