import '../../../core/enums/metal_type.dart';

enum InstallmentStatus { pending, paid, failed, cancelled }

class SchemeInstallmentModel {
  final String installmentId;
  final String schemeId;
  final String customerPhone;
  final int installmentNumber;
  final double amount;
  final double metalGrams;
  final double metalPricePerGram;
  final MetalType metalType;
  final String? paymentMethod;
  final String? transactionId;
  final InstallmentStatus status;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String businessId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchemeInstallmentModel({
    required this.installmentId,
    required this.schemeId,
    required this.customerPhone,
    required this.installmentNumber,
    required this.amount,
    required this.metalGrams,
    required this.metalPricePerGram,
    required this.metalType,
    this.paymentMethod,
    this.transactionId,
    required this.status,
    required this.dueDate,
    this.paidDate,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchemeInstallmentModel.fromJson(Map<String, dynamic> json) {
    return SchemeInstallmentModel(
      installmentId: json['installment_id'] as String,
      schemeId: json['scheme_id'] as String,
      customerPhone: json['customer_phone'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      metalGrams: (json['metal_grams'] as num).toDouble(),
      metalPricePerGram: (json['metal_price_per_gram'] as num).toDouble(),
      metalType: MetalType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['metal_type'] as String).toUpperCase(),
      ),
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      status: InstallmentStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
      ),
      dueDate: DateTime.parse(json['due_date'] as String),
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'] as String) : null,
      businessId: json['business_id'] as String? ?? 'VMURUGAN_001',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installment_id': installmentId,
      'scheme_id': schemeId,
      'customer_phone': customerPhone,
      'installment_number': installmentNumber,
      'amount': amount,
      'metal_grams': metalGrams,
      'metal_price_per_gram': metalPricePerGram,
      'metal_type': metalType.name.toUpperCase(),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': status.name.toUpperCase(),
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SchemeInstallmentModel copyWith({
    String? installmentId,
    String? schemeId,
    String? customerPhone,
    int? installmentNumber,
    double? amount,
    double? metalGrams,
    double? metalPricePerGram,
    MetalType? metalType,
    String? paymentMethod,
    String? transactionId,
    InstallmentStatus? status,
    DateTime? dueDate,
    DateTime? paidDate,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchemeInstallmentModel(
      installmentId: installmentId ?? this.installmentId,
      schemeId: schemeId ?? this.schemeId,
      customerPhone: customerPhone ?? this.customerPhone,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      metalGrams: metalGrams ?? this.metalGrams,
      metalPricePerGram: metalPricePerGram ?? this.metalPricePerGram,
      metalType: metalType ?? this.metalType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPaid => status == InstallmentStatus.paid;
  bool get isPending => status == InstallmentStatus.pending;
  bool get isFailed => status == InstallmentStatus.failed;
  bool get isCancelled => status == InstallmentStatus.cancelled;
  bool get isOverdue => isPending && DateTime.now().isAfter(dueDate);
  
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedMetalGrams => '${metalGrams.toStringAsFixed(4)}g';
  String get metalTypeDisplay => metalType == MetalType.gold ? 'Gold' : 'Silver';
  String get statusDisplay => status.name.toUpperCase();
  
  String get formattedDueDate {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference == 0) return 'Due Today';
    if (difference == 1) return 'Due Tomorrow';
    if (difference > 0) return 'Due in $difference days';
    return 'Overdue by ${-difference} days';
  }
}

class SchemeModel {
  final String schemeId;
  final String customerId;
  final String customerPhone;
  final String customerName;
  final double monthlyAmount;
  final int durationMonths;
  final String schemeType;
  final MetalType metalType;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final double totalAmount;
  final double totalMetalGrams;
  final int completedInstallments;
  final String businessId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SchemeInstallmentModel> installments;

  const SchemeModel({
    required this.schemeId,
    required this.customerId,
    required this.customerPhone,
    required this.customerName,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.schemeType,
    required this.metalType,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.totalAmount,
    required this.totalMetalGrams,
    required this.completedInstallments,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.installments = const [],
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      schemeId: json['scheme_id'] as String,
      customerId: json['customer_id'] as String,
      customerPhone: json['customer_phone'] as String,
      customerName: json['customer_name'] as String,
      monthlyAmount: (json['monthly_amount'] as num).toDouble(),
      durationMonths: json['duration_months'] as int,
      schemeType: json['scheme_type'] as String,
      metalType: MetalType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['metal_type'] as String).toUpperCase(),
      ),
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalMetalGrams: (json['total_metal_grams'] as num?)?.toDouble() ?? 0.0,
      completedInstallments: json['completed_installments'] as int? ?? 0,
      businessId: json['business_id'] as String? ?? 'VMURUGAN_001',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      installments: (json['installments'] as List<dynamic>?)
          ?.map((installment) => SchemeInstallmentModel.fromJson(installment as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheme_id': schemeId,
      'customer_id': customerId,
      'customer_phone': customerPhone,
      'customer_name': customerName,
      'monthly_amount': monthlyAmount,
      'duration_months': durationMonths,
      'scheme_type': schemeType,
      'metal_type': metalType.name.toUpperCase(),
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'total_amount': totalAmount,
      'total_metal_grams': totalMetalGrams,
      'completed_installments': completedInstallments,
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'installments': installments.map((installment) => installment.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  
  int get remainingInstallments => durationMonths - completedInstallments;
  double get progressPercentage => (completedInstallments / durationMonths) * 100;
  
  String get metalTypeDisplay => metalType == MetalType.gold ? 'Gold' : 'Silver';
  String get formattedMonthlyAmount => '₹${monthlyAmount.toStringAsFixed(0)}';
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedTotalMetalGrams => '${totalMetalGrams.toStringAsFixed(4)}g';
  
  SchemeInstallmentModel? get nextPendingInstallment {
    return installments
        .where((installment) => installment.isPending)
        .isNotEmpty
        ? installments.where((installment) => installment.isPending).first
        : null;
  }
  
  String get nextInstallmentText {
    if (isCompleted) return 'Scheme Completed';
    if (completedInstallments == 0) return 'Join Now';
    return '${completedInstallments + 1}${_getOrdinalSuffix(completedInstallments + 1)} Installment';
  }
  
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  SchemeModel copyWith({
    String? schemeId,
    String? customerId,
    String? customerPhone,
    String? customerName,
    double? monthlyAmount,
    int? durationMonths,
    String? schemeType,
    MetalType? metalType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    double? totalMetalGrams,
    int? completedInstallments,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SchemeInstallmentModel>? installments,
  }) {
    return SchemeModel(
      schemeId: schemeId ?? this.schemeId,
      customerId: customerId ?? this.customerId,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName ?? this.customerName,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      durationMonths: durationMonths ?? this.durationMonths,
      schemeType: schemeType ?? this.schemeType,
      metalType: metalType ?? this.metalType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      totalMetalGrams: totalMetalGrams ?? this.totalMetalGrams,
      completedInstallments: completedInstallments ?? this.completedInstallments,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installments: installments ?? this.installments,
    );
  }
}
