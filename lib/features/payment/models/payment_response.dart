enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  timeout,
  unknown
}

class PaymentResponse {
  final String transactionId;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime timestamp;
  final String? gatewayTransactionId;
  final String? gatewayResponse;
  final String? errorMessage;
  final String? errorCode;
  final String? failureReason; // User-friendly failure reason
  final String? gatewayErrorCode; // Gateway-specific error code
  final String? gatewayErrorMessage; // Gateway-specific error message
  final Map<String, dynamic>? additionalData;

  const PaymentResponse({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.timestamp,
    this.gatewayTransactionId,
    this.gatewayResponse,
    this.errorMessage,
    this.errorCode,
    this.failureReason,
    this.gatewayErrorCode,
    this.gatewayErrorMessage,
    this.additionalData,
  });

  // Check if payment was successful
  bool get isSuccess => status == PaymentStatus.success;

  // Check if payment failed
  bool get isFailed => status == PaymentStatus.failed;

  // Check if payment is pending
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;

  // Check if payment was cancelled
  bool get isCancelled => status == PaymentStatus.cancelled;

  // Get formatted amount
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Get message based on status
  String get message {
    if (errorMessage != null) return errorMessage!;
    switch (status) {
      case PaymentStatus.success:
        return 'Payment completed successfully';
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled';
      case PaymentStatus.pending:
        return 'Payment is pending';
      case PaymentStatus.processing:
        return 'Payment is being processed';
      case PaymentStatus.timeout:
        return 'Payment timed out';
      default:
        return 'Unknown payment status';
    }
  }

  // Get status display text
  String get statusDisplay {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.success:
        return 'Success';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.timeout:
        return 'Timeout';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }

  // Get user-friendly status message
  String get statusMessage {
    switch (status) {
      case PaymentStatus.pending:
        return 'Payment is being processed';
      case PaymentStatus.processing:
        return 'Payment is in progress';
      case PaymentStatus.success:
        return 'Payment completed successfully';
      case PaymentStatus.failed:
        return errorMessage ?? 'Payment failed';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled';
      case PaymentStatus.timeout:
        return 'Payment timed out';
      case PaymentStatus.unknown:
        return 'Payment status unknown';
    }
  }

  // Copy with method for immutable updates
  PaymentResponse copyWith({
    String? transactionId,
    PaymentStatus? status,
    double? amount,
    String? currency,
    String? paymentMethod,
    DateTime? timestamp,
    String? gatewayTransactionId,
    String? gatewayResponse,
    String? errorMessage,
    String? errorCode,
    String? failureReason,
    String? gatewayErrorCode,
    String? gatewayErrorMessage,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      failureReason: failureReason ?? this.failureReason,
      gatewayErrorCode: gatewayErrorCode ?? this.gatewayErrorCode,
      gatewayErrorMessage: gatewayErrorMessage ?? this.gatewayErrorMessage,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
      'gatewayTransactionId': gatewayTransactionId,
      'gatewayResponse': gatewayResponse,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'failureReason': failureReason,
      'gatewayErrorCode': gatewayErrorCode,
      'gatewayErrorMessage': gatewayErrorMessage,
      'additionalData': additionalData,
    };
  }

  // Create from JSON
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      transactionId: json['transactionId'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      paymentMethod: json['paymentMethod'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      gatewayTransactionId: json['gatewayTransactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as String?,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      failureReason: json['failureReason'] as String?,
      gatewayErrorCode: json['gatewayErrorCode'] as String?,
      gatewayErrorMessage: json['gatewayErrorMessage'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Create success response
  factory PaymentResponse.success({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    String? gatewayTransactionId,
    String? gatewayResponse,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.success,
      amount: amount,
      currency: 'INR',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      gatewayTransactionId: gatewayTransactionId,
      gatewayResponse: gatewayResponse,
      additionalData: additionalData,
    );
  }

  // Create failed response
  factory PaymentResponse.failed({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    String? errorMessage,
    String? errorCode,
    String? failureReason,
    String? gatewayErrorCode,
    String? gatewayErrorMessage,
    String? gatewayResponse,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.failed,
      amount: amount,
      currency: 'INR',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      errorCode: errorCode,
      failureReason: failureReason,
      gatewayErrorCode: gatewayErrorCode,
      gatewayErrorMessage: gatewayErrorMessage,
      gatewayResponse: gatewayResponse,
      additionalData: additionalData,
    );
  }

  // Create cancelled response
  factory PaymentResponse.cancelled({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentResponse(
      transactionId: transactionId,
      status: PaymentStatus.cancelled,
      amount: amount,
      currency: 'INR',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentResponse && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;

  /// Get user-friendly error message for display
  String getUserFriendlyErrorMessage() {
    if (status == PaymentStatus.success) {
      return 'Payment completed successfully!';
    }

    // Priority order: failureReason > gatewayErrorMessage > errorMessage > generic message
    if (failureReason != null && failureReason!.isNotEmpty) {
      return failureReason!;
    }

    if (gatewayErrorMessage != null && gatewayErrorMessage!.isNotEmpty) {
      return gatewayErrorMessage!;
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }

    // Provide specific messages based on error codes
    if (gatewayErrorCode != null) {
      switch (gatewayErrorCode!.toLowerCase()) {
        case 'insufficient_funds':
          return 'Insufficient funds in your account. Please check your balance and try again.';
        case 'card_declined':
          return 'Your card was declined. Please try with a different card or contact your bank.';
        case 'expired_card':
          return 'Your card has expired. Please use a valid card.';
        case 'invalid_cvv':
          return 'Invalid CVV. Please check your card details and try again.';
        case 'network_error':
          return 'Network error occurred. Please check your internet connection and try again.';
        case 'timeout':
          return 'Payment timed out. Please try again.';
        case 'authentication_failed':
          return 'Authentication failed. Please verify your credentials and try again.';
        default:
          return 'Payment failed due to: ${gatewayErrorCode}';
      }
    }

    if (errorCode != null) {
      switch (errorCode!.toLowerCase()) {
        case 'network_error':
          return 'Network connection failed. Please check your internet and try again.';
        case 'timeout':
          return 'Request timed out. Please try again.';
        case 'invalid_request':
          return 'Invalid payment request. Please contact support.';
        default:
          return 'Payment failed with error: ${errorCode}';
      }
    }

    // Generic message based on status
    switch (status) {
      case PaymentStatus.failed:
        return 'Payment failed. Please try again or contact support.';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled by user.';
      case PaymentStatus.timeout:
        return 'Payment timed out. Please try again.';
      case PaymentStatus.pending:
        return 'Payment is being processed. Please wait.';
      case PaymentStatus.processing:
        return 'Payment is being processed. Please wait.';
      default:
        return 'Payment status: ${status.name}';
    }
  }

  @override
  String toString() {
    return 'PaymentResponse(transactionId: $transactionId, status: $status, '
           'amount: $amount, paymentMethod: $paymentMethod, timestamp: $timestamp)';
  }
}
