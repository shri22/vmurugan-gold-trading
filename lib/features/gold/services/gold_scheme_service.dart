import 'dart:async';
import '../models/gold_scheme_model.dart';
import 'gold_price_service.dart';

class GoldSchemeService {
  static final GoldSchemeService _instance = GoldSchemeService._internal();
  factory GoldSchemeService() => _instance;
  GoldSchemeService._internal();

  final GoldPriceService _priceService = GoldPriceService();
  
  // Mock user schemes (in real app, this would come from backend)
  final List<GoldSchemeModel> _userSchemes = [];

  // Initialize service
  void initialize() {
    _createSampleScheme();
  }

  // Get all user schemes
  List<GoldSchemeModel> getUserSchemes() {
    return List.unmodifiable(_userSchemes);
  }

  // Get active schemes
  List<GoldSchemeModel> getActiveSchemes() {
    return _userSchemes.where((scheme) => scheme.isActive).toList();
  }

  // Create new gold scheme
  Future<GoldSchemeModel> createScheme({
    required String userId,
    required String schemeName,
    required double monthlyAmount,
    required int totalMonths,
  }) async {
    final now = DateTime.now();
    final scheme = GoldSchemeModel(
      id: 'scheme_${now.millisecondsSinceEpoch}',
      userId: userId,
      schemeName: schemeName,
      monthlyAmount: monthlyAmount,
      totalMonths: totalMonths,
      completedMonths: 0,
      startDate: now,
      status: SchemeStatus.active,
      totalInvested: 0.0,
      totalGoldAccumulated: 0.0,
      payments: [],
      createdAt: now,
      updatedAt: now,
    );

    _userSchemes.add(scheme);
    return scheme;
  }

  // Make payment for scheme
  Future<SchemePayment> makeSchemePayment({
    required String schemeId,
    required double amount,
    required String paymentMethod,
  }) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex == -1) {
      throw Exception('Scheme not found');
    }

    final scheme = _userSchemes[schemeIndex];
    final currentPrice = await _priceService.getCurrentPrice();
    final goldQuantity = currentPrice.calculateGoldQuantity(amount);
    
    final payment = SchemePayment(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      schemeId: schemeId,
      amount: amount,
      goldPrice: currentPrice.pricePerGram,
      goldQuantity: goldQuantity,
      paymentDate: DateTime.now(),
      paymentMethod: paymentMethod,
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      status: 'completed',
    );

    // Update scheme
    final updatedPayments = [...scheme.payments, payment];
    final updatedScheme = scheme.copyWith(
      completedMonths: scheme.completedMonths + 1,
      totalInvested: scheme.totalInvested + amount,
      totalGoldAccumulated: scheme.totalGoldAccumulated + goldQuantity,
      payments: updatedPayments,
      updatedAt: DateTime.now(),
      status: scheme.completedMonths + 1 >= scheme.totalMonths 
          ? SchemeStatus.completed 
          : SchemeStatus.active,
      endDate: scheme.completedMonths + 1 >= scheme.totalMonths 
          ? DateTime.now() 
          : null,
    );

    _userSchemes[schemeIndex] = updatedScheme;
    return payment;
  }

  // Get scheme by ID
  GoldSchemeModel? getSchemeById(String schemeId) {
    try {
      return _userSchemes.firstWhere((scheme) => scheme.id == schemeId);
    } catch (e) {
      return null;
    }
  }

  // Calculate scheme performance
  Map<String, dynamic> calculateSchemePerformance(String schemeId) {
    final scheme = getSchemeById(schemeId);
    if (scheme == null) return {};

    final currentPrice = _priceService.currentPrice?.pricePerGram ?? 6250.50;
    final currentValue = scheme.totalGoldAccumulated * currentPrice;
    final totalGain = currentValue - scheme.totalInvested;
    final gainPercentage = scheme.totalInvested > 0 
        ? (totalGain / scheme.totalInvested) * 100 
        : 0.0;

    // Calculate average purchase price
    double averagePurchasePrice = 0.0;
    if (scheme.payments.isNotEmpty) {
      final totalAmount = scheme.payments.fold(0.0, (sum, payment) => sum + payment.amount);
      final totalGold = scheme.payments.fold(0.0, (sum, payment) => sum + payment.goldQuantity);
      averagePurchasePrice = totalGold > 0 ? totalAmount / totalGold : 0.0;
    }

    return {
      'currentValue': currentValue,
      'totalGain': totalGain,
      'gainPercentage': gainPercentage,
      'averagePurchasePrice': averagePurchasePrice,
      'currentPrice': currentPrice,
      'priceAppreciation': averagePurchasePrice > 0 
          ? ((currentPrice - averagePurchasePrice) / averagePurchasePrice) * 100 
          : 0.0,
    };
  }

  // Get upcoming payments
  List<Map<String, dynamic>> getUpcomingPayments() {
    final upcomingPayments = <Map<String, dynamic>>[];
    
    for (final scheme in _userSchemes) {
      if (scheme.isActive && !scheme.isCompleted) {
        upcomingPayments.add({
          'schemeId': scheme.id,
          'schemeName': scheme.schemeName,
          'amount': scheme.monthlyAmount,
          'dueDate': scheme.nextPaymentDate,
          'daysUntilDue': scheme.nextPaymentDate.difference(DateTime.now()).inDays,
        });
      }
    }

    // Sort by due date
    upcomingPayments.sort((a, b) => 
        (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

    return upcomingPayments;
  }

  // Pause scheme
  Future<void> pauseScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.paused,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Resume scheme
  Future<void> resumeScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.active,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Cancel scheme
  Future<void> cancelScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.cancelled,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Create sample scheme for demo
  void _createSampleScheme() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 3, now.day); // Started 3 months ago
    
    // Create sample payments
    final samplePayments = <SchemePayment>[];
    for (int i = 0; i < 3; i++) {
      final paymentDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      final goldPrice = 6200.0 + (i * 25); // Simulate price increase
      final goldQuantity = 2000.0 / goldPrice;
      
      samplePayments.add(SchemePayment(
        id: 'payment_sample_$i',
        schemeId: 'scheme_sample',
        amount: 2000.0,
        goldPrice: goldPrice,
        goldQuantity: goldQuantity,
        paymentDate: paymentDate,
        paymentMethod: 'UPI',
        transactionId: 'txn_sample_$i',
        status: 'completed',
      ));
    }

    final totalInvested = samplePayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final totalGold = samplePayments.fold(0.0, (sum, payment) => sum + payment.goldQuantity);

    final sampleScheme = GoldSchemeModel(
      id: 'scheme_sample',
      userId: 'user_demo',
      schemeName: '11-Month Gold Scheme',
      monthlyAmount: 2000.0,
      totalMonths: 11,
      completedMonths: 3,
      startDate: startDate,
      status: SchemeStatus.active,
      totalInvested: totalInvested,
      totalGoldAccumulated: totalGold,
      payments: samplePayments,
      createdAt: startDate,
      updatedAt: now,
    );

    _userSchemes.add(sampleScheme);
  }
}
