enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

enum PaymentMethod {
  netBanking,
  creditCard,
  debitCard,
  upi,
  wallet,
  gateway,
  scheme,
}

class Transaction {
  final String id;
  final String transactionId;
  final String type;
  final double amount;
  final double metalGrams;
  final double metalPricePerGram;
  final String metalType;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? gatewayTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.metalGrams,
    required this.metalPricePerGram,
    required this.metalType,
    required this.paymentMethod,
    required this.status,
    this.gatewayTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString() ?? '',
      transactionId: map['transaction_id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'BUY',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      metalGrams: (map['metal_grams'] as num?)?.toDouble() ?? 0.0,
      metalPricePerGram: (map['metal_price_per_gram'] as num?)?.toDouble() ?? 0.0,
      metalType: map['metal_type']?.toString() ?? 'GOLD',
      paymentMethod: _parsePaymentMethod(map['payment_method']?.toString()),
      status: _parseTransactionStatus(map['status']?.toString()),
      gatewayTransactionId: map['gateway_transaction_id']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'amount': amount,
      'metal_grams': metalGrams,
      'metal_price_per_gram': metalPricePerGram,
      'metal_type': metalType,
      'payment_method': paymentMethod.toString().split('.').last.toUpperCase(),
      'status': status.toString().split('.').last.toUpperCase(),
      'gateway_transaction_id': gatewayTransactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.gateway;
    
    switch (method.toUpperCase()) {
      case 'NET_BANKING':
      case 'NETBANKING':
        return PaymentMethod.netBanking;
      case 'CREDIT_CARD':
      case 'CREDITCARD':
        return PaymentMethod.creditCard;
      case 'DEBIT_CARD':
      case 'DEBITCARD':
        return PaymentMethod.debitCard;
      case 'UPI':
        return PaymentMethod.upi;
      case 'WALLET':
        return PaymentMethod.wallet;
      case 'SCHEME':
      case 'SCHEME_INVESTMENT':
        return PaymentMethod.scheme;
      default:
        return PaymentMethod.gateway;
    }
  }

  static TransactionStatus _parseTransactionStatus(String? status) {
    if (status == null) return TransactionStatus.pending;
    
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SUCCESS':
      case 'SUCCESSFUL':
        return TransactionStatus.completed;
      case 'PENDING':
        return TransactionStatus.pending;
      case 'FAILED':
      case 'FAILURE':
        return TransactionStatus.failed;
      case 'CANCELLED':
      case 'CANCELED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  Transaction copyWith({
    String? id,
    String? transactionId,
    String? type,
    double? amount,
    double? metalGrams,
    double? metalPricePerGram,
    String? metalType,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
    String? gatewayTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      metalGrams: metalGrams ?? this.metalGrams,
      metalPricePerGram: metalPricePerGram ?? this.metalPricePerGram,
      metalType: metalType ?? this.metalType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, transactionId: $transactionId, type: $type, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
