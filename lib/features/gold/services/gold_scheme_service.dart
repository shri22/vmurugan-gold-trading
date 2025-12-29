import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/secure_http_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/config/sql_server_config.dart';
import '../models/gold_scheme_model.dart';
import 'gold_price_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

class GoldSchemeService {
  static final GoldSchemeService _instance = GoldSchemeService._internal();
  factory GoldSchemeService() => _instance;
  GoldSchemeService._internal();

  final GoldPriceService _priceService = GoldPriceService();

  // Cache for user schemes
  List<GoldSchemeModel> _userSchemes = [];
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  // Backend API base URL
  // Backend API base URL - Use the same one as SqlServerService
  static String get baseUrl => 'https://${SqlServerConfig.serverIP}:3001/api';

  // Initialize service
  void initialize() {
    // Service initialized
    print('🔧 GoldSchemeService initialized');
  }

  // Get customer phone from SharedPreferences
  Future<String?> _getCustomerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('customer_phone');
    } catch (e) {
      print('❌ Error getting customer phone: $e');
      return null;
    }
  }

  // Fetch schemes from backend API
  Future<List<GoldSchemeModel>> fetchSchemesFromBackend() async {
    try {
      final phone = await _getCustomerPhone();
      if (phone == null) {
        print('⚠️ GoldSchemeService: Customer phone not found. Cannot fetch schemes.');
        return [];
      }

      print('📊 GoldSchemeService: Fetching schemes for: $phone');

      // Try to get token, but proceed even if not available
      final token = await AuthService.getBackendToken();
      if (token != null) {
        print('🔐 GoldSchemeService: Using authenticated request');
      } else {
        print('⚠️ GoldSchemeService: No token - attempting unauthenticated request');
      }

      final response = await SecureHttpClient.get(
        '$baseUrl/schemes/$phone',
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final schemesData = data['schemes'] as List<dynamic>;

          _userSchemes = schemesData
              .map((schemeJson) => GoldSchemeModel.fromBackendApi(schemeJson as Map<String, dynamic>))
              .toList();

          _lastFetchTime = DateTime.now();
          return _userSchemes;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching schemes: $e');
      return [];
    }
  }

  // Get all user schemes (with caching)
  Future<List<GoldSchemeModel>> getUserSchemes() async {
    // Check if cache is still valid
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        _userSchemes.isNotEmpty) {
      print('📦 Returning cached schemes (${_userSchemes.length} schemes)');
      return List.unmodifiable(_userSchemes);
    }

    // Fetch fresh data from backend
    await fetchSchemesFromBackend();
    return List.unmodifiable(_userSchemes);
  }

  // Get active schemes
  Future<List<GoldSchemeModel>> getActiveSchemes() async {
    final schemes = await getUserSchemes();
    return schemes.where((scheme) => scheme.isActive).toList();
  }

  // Refresh schemes (force fetch from backend)
  Future<List<GoldSchemeModel>> refreshSchemes() async {
    _lastFetchTime = null; // Invalidate cache
    return await getUserSchemes();
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

    // Check if MJDTA price is available
    if (currentPrice == null) {
      throw Exception('MJDTA price service unavailable - cannot process scheme payment');
    }

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

    // Create scheme payment notification
    await NotificationTemplates.schemePayment(
      schemeName: scheme.schemeName,
      amount: amount,
      monthNumber: scheme.completedMonths + 1,
      totalMonths: scheme.totalMonths,
    );

    return payment;
  }

  // Get scheme by ID
  Future<GoldSchemeModel?> getSchemeById(String schemeId) async {
    try {
      final schemes = await getUserSchemes();
      return schemes.firstWhere((scheme) => scheme.id == schemeId || scheme.schemeId == schemeId);
    } catch (e) {
      print('❌ Scheme not found: $schemeId');
      return null;
    }
  }

  // Calculate scheme performance
  Future<Map<String, dynamic>?> calculateSchemePerformance(String schemeId) async {
    final scheme = await getSchemeById(schemeId);
    if (scheme == null) return null;

    final currentPrice = _priceService.currentPrice?.pricePerGram;
    if (currentPrice == null) {
      // Return null if MJDTA price is not available
      return null;
    }
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
  Future<List<Map<String, dynamic>>> getUpcomingPayments() async {
    final schemes = await getUserSchemes();
    final upcomingPayments = <Map<String, dynamic>>[];

    for (final scheme in schemes) {
      if (scheme.isActive && !scheme.isCompleted) {
        upcomingPayments.add({
          'schemeId': scheme.schemeId ?? scheme.id,
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


}
