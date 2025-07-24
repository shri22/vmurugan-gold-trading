enum SchemeStatus { active, completed, paused, cancelled }

class GoldSchemeModel {
  final String id;
  final String userId;
  final String schemeName;
  final double monthlyAmount;
  final int totalMonths;
  final int completedMonths;
  final DateTime startDate;
  final DateTime? endDate;
  final SchemeStatus status;
  final double totalInvested;
  final double totalGoldAccumulated;
  final List<SchemePayment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoldSchemeModel({
    required this.id,
    required this.userId,
    required this.schemeName,
    required this.monthlyAmount,
    required this.totalMonths,
    required this.completedMonths,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.totalInvested,
    required this.totalGoldAccumulated,
    required this.payments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoldSchemeModel.fromJson(Map<String, dynamic> json) {
    return GoldSchemeModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      schemeName: json['schemeName'] as String,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      totalMonths: json['totalMonths'] as int,
      completedMonths: json['completedMonths'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      status: SchemeStatus.values.firstWhere((e) => e.name == json['status']),
      totalInvested: (json['totalInvested'] as num).toDouble(),
      totalGoldAccumulated: (json['totalGoldAccumulated'] as num).toDouble(),
      payments: (json['payments'] as List<dynamic>)
          .map((payment) => SchemePayment.fromJson(payment as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'schemeName': schemeName,
      'monthlyAmount': monthlyAmount,
      'totalMonths': totalMonths,
      'completedMonths': completedMonths,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'totalInvested': totalInvested,
      'totalGoldAccumulated': totalGoldAccumulated,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  double get progressPercentage => (completedMonths / totalMonths) * 100;
  int get remainingMonths => totalMonths - completedMonths;
  double get remainingAmount => (totalMonths - completedMonths) * monthlyAmount;
  bool get isCompleted => completedMonths >= totalMonths;
  bool get isActive => status == SchemeStatus.active;

  DateTime get nextPaymentDate {
    if (isCompleted) return endDate ?? DateTime.now();
    return DateTime(
      startDate.year,
      startDate.month + completedMonths + 1,
      startDate.day,
    );
  }

  String get formattedTotalInvested => '₹${totalInvested.toStringAsFixed(2)}';
  String get formattedMonthlyAmount => '₹${monthlyAmount.toStringAsFixed(0)}';
  String get formattedGoldAccumulated => '${totalGoldAccumulated.toStringAsFixed(4)} grams';

  GoldSchemeModel copyWith({
    String? id,
    String? userId,
    String? schemeName,
    double? monthlyAmount,
    int? totalMonths,
    int? completedMonths,
    DateTime? startDate,
    DateTime? endDate,
    SchemeStatus? status,
    double? totalInvested,
    double? totalGoldAccumulated,
    List<SchemePayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoldSchemeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schemeName: schemeName ?? this.schemeName,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      totalMonths: totalMonths ?? this.totalMonths,
      completedMonths: completedMonths ?? this.completedMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalInvested: totalInvested ?? this.totalInvested,
      totalGoldAccumulated: totalGoldAccumulated ?? this.totalGoldAccumulated,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SchemePayment {
  final String id;
  final String schemeId;
  final double amount;
  final double goldPrice;
  final double goldQuantity;
  final DateTime paymentDate;
  final String paymentMethod;
  final String transactionId;
  final String status; // 'pending', 'completed', 'failed'

  const SchemePayment({
    required this.id,
    required this.schemeId,
    required this.amount,
    required this.goldPrice,
    required this.goldQuantity,
    required this.paymentDate,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
  });

  factory SchemePayment.fromJson(Map<String, dynamic> json) {
    return SchemePayment(
      id: json['id'] as String,
      schemeId: json['schemeId'] as String,
      amount: (json['amount'] as num).toDouble(),
      goldPrice: (json['goldPrice'] as num).toDouble(),
      goldQuantity: (json['goldQuantity'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schemeId': schemeId,
      'amount': amount,
      'goldPrice': goldPrice,
      'goldQuantity': goldQuantity,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
    };
  }

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedGoldQuantity => '${goldQuantity.toStringAsFixed(4)} grams';
  String get formattedGoldPrice => '₹${goldPrice.toStringAsFixed(2)}/gram';
}
