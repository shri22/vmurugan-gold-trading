class Portfolio {
  final int id;
  final double totalGoldGrams;
  final double totalInvested;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercentage;
  final DateTime lastUpdated;

  Portfolio({
    required this.id,
    required this.totalGoldGrams,
    required this.totalInvested,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
    required this.lastUpdated,
  });

  factory Portfolio.fromMap(Map<String, dynamic> map) {
    return Portfolio(
      id: map['id'] ?? 0,
      totalGoldGrams: (map['total_gold_grams'] ?? 0.0).toDouble(),
      totalInvested: (map['total_invested'] ?? 0.0).toDouble(),
      currentValue: (map['current_value'] ?? 0.0).toDouble(),
      profitLoss: (map['profit_loss'] ?? 0.0).toDouble(),
      profitLossPercentage: (map['profit_loss_percentage'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(map['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_gold_grams': totalGoldGrams,
      'total_invested': totalInvested,
      'current_value': currentValue,
      'profit_loss': profitLoss,
      'profit_loss_percentage': profitLossPercentage,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  Portfolio copyWith({
    int? id,
    double? totalGoldGrams,
    double? totalInvested,
    double? currentValue,
    double? profitLoss,
    double? profitLossPercentage,
    DateTime? lastUpdated,
  }) {
    return Portfolio(
      id: id ?? this.id,
      totalGoldGrams: totalGoldGrams ?? this.totalGoldGrams,
      totalInvested: totalInvested ?? this.totalInvested,
      currentValue: currentValue ?? this.currentValue,
      profitLoss: profitLoss ?? this.profitLoss,
      profitLossPercentage: profitLossPercentage ?? this.profitLossPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasGold => totalGoldGrams > 0;
  bool get isProfit => profitLoss > 0;
  String get profitLossDisplay => isProfit ? '+₹${profitLoss.toStringAsFixed(2)}' : '-₹${profitLoss.abs().toStringAsFixed(2)}';
}

class Transaction {
  final int? id;
  final String transactionId;
  final TransactionType type;
  final double amount;
  final double goldGrams;
  final double goldPricePerGram;
  final String paymentMethod;
  final TransactionStatus status;
  final String? gatewayTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.goldGrams,
    required this.goldPricePerGram,
    required this.paymentMethod,
    required this.status,
    this.gatewayTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      transactionId: map['transaction_id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.BUY,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      goldGrams: (map['gold_grams'] ?? 0.0).toDouble(),
      goldPricePerGram: (map['gold_price_per_gram'] ?? 0.0).toDouble(),
      paymentMethod: map['payment_method'] ?? '',
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TransactionStatus.PENDING,
      ),
      gatewayTransactionId: map['gateway_transaction_id'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'gold_grams': goldGrams,
      'gold_price_per_gram': goldPricePerGram,
      'payment_method': paymentMethod,
      'status': status.toString().split('.').last,
      'gateway_transaction_id': gatewayTransactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case TransactionStatus.SUCCESS:
        return 'Completed';
      case TransactionStatus.PENDING:
        return 'Pending';
      case TransactionStatus.FAILED:
        return 'Failed';
      case TransactionStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  String get typeDisplay {
    switch (type) {
      case TransactionType.BUY:
        return 'Buy Gold';
      case TransactionType.SELL:
        return 'Sell Gold';
    }
  }
}

enum TransactionType { BUY, SELL }
enum TransactionStatus { PENDING, SUCCESS, FAILED, CANCELLED }

class PriceHistory {
  final int? id;
  final double pricePer22K;
  final double pricePer24K;
  final DateTime timestamp;
  final String source;

  PriceHistory({
    this.id,
    required this.pricePer22K,
    required this.pricePer24K,
    required this.timestamp,
    required this.source,
  });

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'],
      pricePer22K: (map['price_per_gram_22k'] ?? 0.0).toDouble(),
      pricePer24K: (map['price_per_gram_24k'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      source: map['source'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'price_per_gram_22k': pricePer22K,
      'price_per_gram_24k': pricePer24K,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }
}