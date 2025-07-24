class GoldPriceModel {
  final double pricePerGram;
  final double pricePerOunce;
  final String currency;
  final DateTime timestamp;
  final double changePercent;
  final double changeAmount;
  final String trend; // 'up', 'down', 'stable'

  const GoldPriceModel({
    required this.pricePerGram,
    required this.pricePerOunce,
    required this.currency,
    required this.timestamp,
    required this.changePercent,
    required this.changeAmount,
    required this.trend,
  });

  factory GoldPriceModel.fromJson(Map<String, dynamic> json) {
    return GoldPriceModel(
      pricePerGram: (json['pricePerGram'] as num).toDouble(),
      pricePerOunce: (json['pricePerOunce'] as num).toDouble(),
      currency: json['currency'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      changePercent: (json['changePercent'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      trend: json['trend'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pricePerGram': pricePerGram,
      'pricePerOunce': pricePerOunce,
      'currency': currency,
      'timestamp': timestamp.toIso8601String(),
      'changePercent': changePercent,
      'changeAmount': changeAmount,
      'trend': trend,
    };
  }

  // Helper methods
  bool get isPositive => changePercent > 0;
  bool get isNegative => changePercent < 0;
  bool get isStable => changePercent == 0;

  String get formattedPrice => '₹${pricePerGram.toStringAsFixed(2)}';
  String get formattedChange => '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
  String get formattedChangeAmount => '${changeAmount >= 0 ? '+' : ''}₹${changeAmount.toStringAsFixed(2)}';

  // Calculate gold quantity for given amount
  double calculateGoldQuantity(double investmentAmount) {
    return investmentAmount / pricePerGram;
  }

  // Calculate investment amount for given gold quantity
  double calculateInvestmentAmount(double goldQuantity) {
    return goldQuantity * pricePerGram;
  }

  GoldPriceModel copyWith({
    double? pricePerGram,
    double? pricePerOunce,
    String? currency,
    DateTime? timestamp,
    double? changePercent,
    double? changeAmount,
    String? trend,
  }) {
    return GoldPriceModel(
      pricePerGram: pricePerGram ?? this.pricePerGram,
      pricePerOunce: pricePerOunce ?? this.pricePerOunce,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      changePercent: changePercent ?? this.changePercent,
      changeAmount: changeAmount ?? this.changeAmount,
      trend: trend ?? this.trend,
    );
  }

  @override
  String toString() {
    return 'GoldPriceModel(pricePerGram: $pricePerGram, currency: $currency, timestamp: $timestamp, changePercent: $changePercent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoldPriceModel &&
        other.pricePerGram == pricePerGram &&
        other.pricePerOunce == pricePerOunce &&
        other.currency == currency &&
        other.timestamp == timestamp &&
        other.changePercent == changePercent &&
        other.changeAmount == changeAmount &&
        other.trend == trend;
  }

  @override
  int get hashCode {
    return pricePerGram.hashCode ^
        pricePerOunce.hashCode ^
        currency.hashCode ^
        timestamp.hashCode ^
        changePercent.hashCode ^
        changeAmount.hashCode ^
        trend.hashCode;
  }
}
