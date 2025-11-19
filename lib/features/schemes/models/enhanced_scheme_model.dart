import '../../../core/enums/metal_type.dart';

class EnhancedSchemeModel {
  final String id;
  final String name;
  final String description;
  final MetalType metalType;
  final int durationMonths;
  final double monthlyAmount;
  final double bonusPercentage;
  final int minAge;
  final int maxAge;
  final bool isActive;
  final List<String> features;
  final List<String> benefits;
  final List<String> terms;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EnhancedSchemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.metalType,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.bonusPercentage,
    required this.minAge,
    required this.maxAge,
    required this.isActive,
    required this.features,
    required this.benefits,
    required this.terms,
    this.createdAt,
    this.updatedAt,
  });

  // Calculate total investment amount
  double get totalInvestment => monthlyAmount * durationMonths;

  // Calculate bonus amount (approximate, based on current metal price)
  double calculateBonusAmount(double currentMetalPrice) {
    final totalMetalGrams = totalInvestment / currentMetalPrice;
    final bonusGrams = totalMetalGrams * (bonusPercentage / 100);
    return bonusGrams * currentMetalPrice;
  }

  // Calculate total metal grams (including bonus)
  double calculateTotalMetalGrams(double currentMetalPrice) {
    final baseGrams = totalInvestment / currentMetalPrice;
    final bonusGrams = baseGrams * (bonusPercentage / 100);
    return baseGrams + bonusGrams;
  }

  // Get scheme type display name
  String get schemeTypeDisplay {
    switch (metalType) {
      case MetalType.gold:
        return 'Gold Plus';
      case MetalType.silver:
        return 'Silver Plus';
    }
  }

  // Get metal type display name
  String get metalTypeDisplay {
    switch (metalType) {
      case MetalType.gold:
        return 'Gold';
      case MetalType.silver:
        return 'Silver';
    }
  }

  // Check if user is eligible based on age
  bool isEligibleForAge(int userAge) {
    return userAge >= minAge && userAge <= maxAge;
  }

  // Get formatted monthly amount
  String get formattedMonthlyAmount {
    return '₹${monthlyAmount.toStringAsFixed(0)}';
  }

  // Get formatted total investment
  String get formattedTotalInvestment {
    return '₹${totalInvestment.toStringAsFixed(0)}';
  }

  // Get formatted bonus percentage
  String get formattedBonusPercentage {
    return '${bonusPercentage.toStringAsFixed(1)}%';
  }

  // Get scheme duration display
  String get durationDisplay {
    if (durationMonths == 12) {
      return '1 Year';
    } else if (durationMonths == 24) {
      return '2 Years';
    } else if (durationMonths % 12 == 0) {
      return '${durationMonths ~/ 12} Years';
    } else {
      return '$durationMonths Months';
    }
  }

  // Get age eligibility display
  String get ageEligibilityDisplay {
    return '$minAge - $maxAge years';
  }

  // Copy with method for immutable updates
  EnhancedSchemeModel copyWith({
    String? id,
    String? name,
    String? description,
    MetalType? metalType,
    int? durationMonths,
    double? monthlyAmount,
    double? bonusPercentage,
    int? minAge,
    int? maxAge,
    bool? isActive,
    List<String>? features,
    List<String>? benefits,
    List<String>? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnhancedSchemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metalType: metalType ?? this.metalType,
      durationMonths: durationMonths ?? this.durationMonths,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      bonusPercentage: bonusPercentage ?? this.bonusPercentage,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      benefits: benefits ?? this.benefits,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metalType': metalType.name,
      'durationMonths': durationMonths,
      'monthlyAmount': monthlyAmount,
      'bonusPercentage': bonusPercentage,
      'minAge': minAge,
      'maxAge': maxAge,
      'isActive': isActive,
      'features': features,
      'benefits': benefits,
      'terms': terms,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory EnhancedSchemeModel.fromJson(Map<String, dynamic> json) {
    return EnhancedSchemeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      metalType: MetalType.values.firstWhere(
        (e) => e.name == json['metalType'],
        orElse: () => MetalType.gold,
      ),
      durationMonths: json['durationMonths'] as int,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      bonusPercentage: (json['bonusPercentage'] as num).toDouble(),
      minAge: json['minAge'] as int,
      maxAge: json['maxAge'] as int,
      isActive: json['isActive'] as bool,
      features: List<String>.from(json['features'] as List),
      benefits: List<String>.from(json['benefits'] as List),
      terms: List<String>.from(json['terms'] as List),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedSchemeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EnhancedSchemeModel(id: $id, name: $name, metalType: $metalType, '
           'durationMonths: $durationMonths, monthlyAmount: $monthlyAmount, '
           'bonusPercentage: $bonusPercentage)';
  }
}
