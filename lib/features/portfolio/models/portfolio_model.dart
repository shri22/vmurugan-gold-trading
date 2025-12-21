import '../../schemes/models/scheme_installment_model.dart';
import '../../../core/enums/metal_type.dart';

// Portfolio Breakdown Model
class PortfolioBreakdown {
  final double goldTotal;
  final double goldDirectPurchase;
  final double goldPlus;
  final double goldFlexi;
  final double silverTotal;
  final double silverDirectPurchase;
  final double silverPlus;
  final double silverFlexi;

  PortfolioBreakdown({
    required this.goldTotal,
    required this.goldDirectPurchase,
    required this.goldPlus,
    required this.goldFlexi,
    required this.silverTotal,
    required this.silverDirectPurchase,
    required this.silverPlus,
    required this.silverFlexi,
  });

  factory PortfolioBreakdown.fromMap(Map<String, dynamic> map) {
    // Helper for safe number parsing
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    final gold = map['gold'] ?? {};
    final silver = map['silver'] ?? {};

    return PortfolioBreakdown(
      goldTotal: safeDouble(gold['total']),
      goldDirectPurchase: safeDouble(gold['direct_purchase']),
      goldPlus: safeDouble(gold['gold_plus']),
      goldFlexi: safeDouble(gold['gold_flexi']),
      silverTotal: safeDouble(silver['total']),
      silverDirectPurchase: safeDouble(silver['direct_purchase']),
      silverPlus: safeDouble(silver['silver_plus']),
      silverFlexi: safeDouble(silver['silver_flexi']),
    );
  }
}

class Portfolio {
  final int id;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerPanCard;
  final String? customerNomineeName;
  final String? customerNomineeRelationship;
  final String? customerNomineePhone;
  final double totalGoldGrams;
  final double totalSilverGrams;
  final double totalInvested;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercentage;
  final double? currentGoldPrice; // Current gold price from MJDTA (for display)
  final double? currentSilverPrice; // Current silver price from MJDTA (for display)
  final DateTime lastUpdated;
  final PortfolioBreakdown? breakdown;

  Portfolio({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerAddress,
    this.customerPanCard,
    this.customerNomineeName,
    this.customerNomineeRelationship,
    this.customerNomineePhone,
    required this.totalGoldGrams,
    required this.totalSilverGrams,
    required this.totalInvested,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
    this.currentGoldPrice,
    this.currentSilverPrice,
    required this.lastUpdated,
    this.breakdown,
  });

  factory Portfolio.fromMap(Map<String, dynamic> map) {
    // Helper for safe number parsing
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Portfolio(
      id: map['id'] ?? 0,
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      customerEmail: map['customer_email'],
      customerAddress: map['customer_address'],
      customerPanCard: map['customer_pan_card'],
      customerNomineeName: map['customer_nominee_name'],
      customerNomineeRelationship: map['customer_nominee_relationship'],
      customerNomineePhone: map['customer_nominee_phone'],
      totalGoldGrams: safeDouble(map['total_gold_grams']),
      totalSilverGrams: safeDouble(map['total_silver_grams']),
      totalInvested: safeDouble(map['total_invested']),
      currentValue: safeDouble(map['current_value']),
      profitLoss: safeDouble(map['profit_loss']),
      profitLossPercentage: safeDouble(map['profit_loss_percentage']),
      currentGoldPrice: map['current_gold_price'] != null ? safeDouble(map['current_gold_price']) : null,
      currentSilverPrice: map['current_silver_price'] != null ? safeDouble(map['current_silver_price']) : null,
      lastUpdated: DateTime.tryParse(map['last_updated'] ?? '') ?? DateTime.now(),
      breakdown: map['breakdown'] != null ? PortfolioBreakdown.fromMap(map['breakdown']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (customerPanCard != null) 'customer_pan_card': customerPanCard,
      if (customerNomineeName != null) 'customer_nominee_name': customerNomineeName,
      if (customerNomineeRelationship != null) 'customer_nominee_relationship': customerNomineeRelationship,
      if (customerNomineePhone != null) 'customer_nominee_phone': customerNomineePhone,
      'total_gold_grams': totalGoldGrams,
      'total_silver_grams': totalSilverGrams,
      'total_invested': totalInvested,
      'current_value': currentValue,
      'profit_loss': profitLoss,
      'profit_loss_percentage': profitLossPercentage,
      if (currentGoldPrice != null) 'current_gold_price': currentGoldPrice,
      if (currentSilverPrice != null) 'current_silver_price': currentSilverPrice,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  Portfolio copyWith({
    int? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerAddress,
    String? customerPanCard,
    String? customerNomineeName,
    String? customerNomineeRelationship,
    String? customerNomineePhone,
    double? totalGoldGrams,
    double? totalSilverGrams,
    double? totalInvested,
    double? currentValue,
    double? profitLoss,
    double? profitLossPercentage,
    DateTime? lastUpdated,
  }) {
    return Portfolio(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPanCard: customerPanCard ?? this.customerPanCard,
      customerNomineeName: customerNomineeName ?? this.customerNomineeName,
      customerNomineeRelationship: customerNomineeRelationship ?? this.customerNomineeRelationship,
      customerNomineePhone: customerNomineePhone ?? this.customerNomineePhone,
      totalGoldGrams: totalGoldGrams ?? this.totalGoldGrams,
      totalSilverGrams: totalSilverGrams ?? this.totalSilverGrams,
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
  final double metalGrams;
  final double metalPricePerGram;
  final MetalType metalType;
  final String paymentMethod;
  final TransactionStatus status;
  final String? gatewayTransactionId;
  final String? schemeType;
  final String? schemeId;
  final int? installmentNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.metalGrams,
    required this.metalPricePerGram,
    required this.metalType,
    required this.paymentMethod,
    required this.status,
    this.gatewayTransactionId,
    this.schemeType,
    this.schemeId,
    this.installmentNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Helper for safe number parsing
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Transaction(
      id: map['id'],
      transactionId: map['transaction_id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.BUY,
      ),
      amount: safeDouble(map['amount']),
      metalGrams: safeDouble(map['metal_grams'] ?? map['gold_grams']),
      metalPricePerGram: safeDouble(map['metal_price_per_gram'] ?? map['gold_price_per_gram']),
      metalType: MetalType.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['metal_type'] ?? 'GOLD').toUpperCase(),
        orElse: () => MetalType.gold,
      ),
      paymentMethod: map['payment_method'] ?? '',
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TransactionStatus.PENDING,
      ),
      gatewayTransactionId: map['gateway_transaction_id'],
      schemeType: map['scheme_type'],
      schemeId: map['scheme_id'],
      installmentNumber: map['installment_number'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'metal_grams': metalGrams,
      'metal_price_per_gram': metalPricePerGram,
      'metal_type': metalType.name.toUpperCase(),
      'payment_method': paymentMethod,
      'status': status.toString().split('.').last,
      'gateway_transaction_id': gatewayTransactionId,
      'scheme_type': schemeType,
      'scheme_id': schemeId,
      'installment_number': installmentNumber,
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
    final metalName = metalType == MetalType.gold ? 'Gold' : 'Silver';
    switch (type) {
      case TransactionType.BUY:
        return 'Buy $metalName';
      case TransactionType.SELL:
        return 'Sell $metalName';
    }
  }

  String get metalTypeDisplay => metalType == MetalType.gold ? 'Gold' : 'Silver';

  // Backward compatibility getter
  double get goldGrams => metalGrams;
  double get goldPricePerGram => metalPricePerGram;
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