import '../../../core/utils/number_formatter.dart';

enum SchemeStatus { active, completed, paused, cancelled }

class GoldSchemeModel {
  final String id;
  final String? schemeId; // Backend scheme ID (e.g., GP_P1, GF_P2)
  final String userId;
  final String schemeName;
  final String? schemeType; // GOLDPLUS, GOLDFLEXI, SILVERPLUS, SILVERFLEXI
  final String? metalType; // GOLD, SILVER
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
  final bool hasPaidThisMonth;
  final bool nextPaymentAllowed;

  const GoldSchemeModel({
    required this.id,
    this.schemeId,
    required this.userId,
    required this.schemeName,
    this.schemeType,
    this.metalType,
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
    this.hasPaidThisMonth = false,
    this.nextPaymentAllowed = true,
  });

  // Factory for parsing backend API response
  factory GoldSchemeModel.fromBackendApi(Map<String, dynamic> json) {
    // Parse status from backend (ACTIVE, PAUSED, COMPLETED, CANCELLED)
    SchemeStatus status;
    final statusStr = (json['status'] as String?)?.toUpperCase() ?? 'ACTIVE';
    switch (statusStr) {
      case 'ACTIVE':
        status = SchemeStatus.active;
        break;
      case 'PAUSED':
        status = SchemeStatus.paused;
        break;
      case 'COMPLETED':
        status = SchemeStatus.completed;
        break;
      case 'CANCELLED':
        status = SchemeStatus.cancelled;
        break;
      default:
        status = SchemeStatus.active;
    }

    // Parse scheme type to get display name
    final schemeType = json['scheme_type'] as String?;
    String schemeName = schemeType ?? 'Unknown Scheme';
    if (schemeType != null) {
      switch (schemeType.toUpperCase()) {
        case 'GOLDPLUS':
          schemeName = 'Gold Plus';
          break;
        case 'GOLDFLEXI':
          schemeName = 'Gold Flexi';
          break;
        case 'SILVERPLUS':
          schemeName = 'Silver Plus';
          break;
        case 'SILVERFLEXI':
          schemeName = 'Silver Flexi';
          break;
      }
    }

    return GoldSchemeModel(
      id: json['id']?.toString() ?? '',
      schemeId: json['scheme_id'] as String?,
      userId: json['customer_id']?.toString() ?? '',
      schemeName: schemeName,
      schemeType: schemeType,
      metalType: json['metal_type'] as String?,
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble() ?? 0.0,
      totalMonths: json['duration_months'] as int? ?? 12,
      completedMonths: json['completed_installments'] as int? ?? 0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: status,
      totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0.0,
      totalGoldAccumulated: (json['total_metal_accumulated'] as num?)?.toDouble() ?? 0.0,
      payments: [], // Payments will be loaded separately if needed
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      hasPaidThisMonth: () {
        final rawValue = json['has_paid_this_month'];
        print('🔍 PARSING hasPaidThisMonth for ${json['scheme_type']}: raw=$rawValue (type=${rawValue.runtimeType})');
        
        // Handle both boolean and integer (0/1) from backend
        if (rawValue is bool) {
          return rawValue;
        } else if (rawValue is int) {
          return rawValue == 1;
        } else if (rawValue is String) {
          return rawValue == '1' || rawValue.toLowerCase() == 'true';
        }
        return false;
      }(),
      nextPaymentAllowed: () {
        final rawValue = json['next_payment_allowed'];
        print('🔍 PARSING nextPaymentAllowed for ${json['scheme_type']}: raw=$rawValue (type=${rawValue.runtimeType})');
        
        // Handle both boolean and integer (0/1) from backend
        if (rawValue is bool) {
          return rawValue;
        } else if (rawValue is int) {
          return rawValue == 1;
        } else if (rawValue is String) {
          return rawValue == '1' || rawValue.toLowerCase() == 'true';
        }
        return true; // Default to allowing payment if parsing fails
      }(),
    );
  }

  // Factory for parsing local JSON (mock data)
  factory GoldSchemeModel.fromJson(Map<String, dynamic> json) {
    return GoldSchemeModel(
      id: json['id'] as String,
      schemeId: json['schemeId'] as String?,
      userId: json['userId'] as String,
      schemeName: json['schemeName'] as String,
      schemeType: json['schemeType'] as String?,
      metalType: json['metalType'] as String?,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      totalMonths: json['totalMonths'] as int,
      completedMonths: json['completedMonths'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      status: SchemeStatus.values.firstWhere((e) => e.name == json['status']),
      totalInvested: (json['totalInvested'] as num).toDouble(),
      totalGoldAccumulated: (json['totalGoldAccumulated'] as num).toDouble(),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((payment) => SchemePayment.fromJson(payment as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schemeId': schemeId,
      'userId': userId,
      'schemeName': schemeName,
      'schemeType': schemeType,
      'metalType': metalType,
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
  String get formattedGoldAccumulated => '${NumberFormatter.formatToThreeDecimals(totalGoldAccumulated)} grams';

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
  final String? metalType; // 'GOLD' or 'SILVER'

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
    this.metalType,
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
      metalType: json['metalType'] as String?,
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
      'metalType': metalType,
    };
  }

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedGoldQuantity => '${NumberFormatter.formatToThreeDecimals(goldQuantity)} grams';
  String get formattedGoldPrice => '₹${goldPrice.toStringAsFixed(2)}/gram';
}
