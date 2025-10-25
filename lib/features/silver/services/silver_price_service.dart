import 'dart:async';
import '../models/silver_price_model.dart';
import '../../gold/services/mjdta_price_service.dart';

class SilverPriceService {
  static final SilverPriceService _instance = SilverPriceService._internal();
  factory SilverPriceService() => _instance;
  SilverPriceService._internal();

  // Stream controller for real-time price updates
  final StreamController<SilverPriceModel?> _priceController = StreamController<SilverPriceModel?>.broadcast();
  Stream<SilverPriceModel?> get priceStream => _priceController.stream;

  // Current price cache
  SilverPriceModel? _currentPrice;
  Timer? _priceUpdateTimer;

  // MJDTA service - our only price source
  final MjdtaPriceService _mjdtaService = MjdtaPriceService();

  // Track MJDTA availability
  bool _isMjdtaAvailable = false;
  DateTime? _lastMjdtaCheck;

  // Initialize the service
  void initialize() {
    _loadInitialPrice();
    _startPriceUpdates();
  }

  // Dispose resources
  void dispose() {
    _priceUpdateTimer?.cancel();
    _priceController.close();
  }

  // Get current silver price
  SilverPriceModel? get currentPrice => _currentPrice;

  // Get current price as Future
  Future<SilverPriceModel?> getCurrentPrice() async {
    if (_currentPrice == null) {
      await _loadInitialPrice();
    }
    return _currentPrice;
  }

  // Start real-time price updates
  void _startPriceUpdates() {
    // Update every 2 minutes for live API calls (to avoid rate limiting)
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updatePrice();
    });
  }

  // Load initial price from MJDTA only
  Future<void> _loadInitialPrice() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('🥈 SilverPriceService: Loading initial price from MJDTA (attempt ${retryCount + 1}/$maxRetries)...');

        final silverPrice = await _mjdtaService.fetchSilverPrice();
        if (silverPrice != null) {
          print('🥈 SilverPriceService: ✅ Successfully loaded price from MJDTA: ${silverPrice.formattedPrice}');
          print('🥈 SilverPriceService: Raw price value: ${silverPrice.pricePerGram}');

          // Validate price is reasonable
          if (silverPrice.pricePerGram >= 30.0 && silverPrice.pricePerGram <= 300.0) {
            _currentPrice = silverPrice;
            _isMjdtaAvailable = true;
            _lastMjdtaCheck = DateTime.now();
            _priceController.add(_currentPrice);
            return; // Success, exit retry loop
          } else {
            print('🥈 SilverPriceService: ⚠️ Price validation failed: ${silverPrice.pricePerGram} is outside reasonable range');
          }
        } else {
          print('🥈 SilverPriceService: ❌ MJDTA returned null price (attempt ${retryCount + 1})');
        }
      } catch (e) {
        print('🥈 SilverPriceService: Error loading initial price (attempt ${retryCount + 1}): $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        print('🥈 SilverPriceService: Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // All retries failed
    print('🥈 SilverPriceService: ❌ All retry attempts failed - no price data available');
    _currentPrice = null;
    _isMjdtaAvailable = false;
    _lastMjdtaCheck = DateTime.now();
    _priceController.add(null);
  }

  // Update price from MJDTA
  Future<void> _updatePrice() async {
    try {
      // Check if we should retry MJDTA (every 10 minutes if it was unavailable)
      final shouldRetryMjdta = _lastMjdtaCheck == null || 
          DateTime.now().difference(_lastMjdtaCheck!).inMinutes >= 10;

      if (_isMjdtaAvailable || shouldRetryMjdta) {
        print('SilverPriceService: Fetching updated price from MJDTA...');

        final silverPrice = await _mjdtaService.fetchSilverPrice();
        if (silverPrice != null) {
          print('🥈 SilverPriceService: ✅ Successfully updated price from MJDTA: ${silverPrice.formattedPrice}');
          print('🥈 SilverPriceService: Updated raw price value: ${silverPrice.pricePerGram}');
          _currentPrice = silverPrice;
          _isMjdtaAvailable = true;
          _lastMjdtaCheck = DateTime.now();
          _priceController.add(_currentPrice);
        } else {
          print('🥈 SilverPriceService: ❌ MJDTA still unavailable');
          _currentPrice = null;
          _isMjdtaAvailable = false;
          _lastMjdtaCheck = DateTime.now();
          _priceController.add(null);
        }
      }
    } catch (e) {
      print('SilverPriceService: Error updating price: $e');
      _currentPrice = null;
      _isMjdtaAvailable = false;
      _lastMjdtaCheck = DateTime.now();
      _priceController.add(null);
    }
  }

  // Manual price refresh
  Future<SilverPriceModel?> refreshPrice() async {
    await _updatePrice();
    return _currentPrice;
  }

  // Get MJDTA availability status
  bool get isMjdtaAvailable => _isMjdtaAvailable;

  // Get price source description
  String get priceSource {
    if (_isMjdtaAvailable) {
      return 'MJDTA Live Data (Chennai) - Silver';
    } else {
      return 'MJDTA Unavailable - No Price Data';
    }
  }

  // Force MJDTA retry
  Future<void> retryMjdtaConnection() async {
    await _updatePrice();
  }

  // Test method to directly fetch and log silver price
  Future<SilverPriceModel?> testFetchSilverPrice() async {
    print('🥈 SilverPriceService: TEST - Direct silver price fetch...');
    final result = await _mjdtaService.fetchSilverPrice();
    if (result != null) {
      print('🥈 SilverPriceService: TEST - ✅ Success: ${result.pricePerGram} (${result.formattedPrice})');
    } else {
      print('🥈 SilverPriceService: TEST - ❌ Failed to fetch silver price');
    }
    return result;
  }

  // Comprehensive test method
  Future<Map<String, dynamic>> runDiagnostics() async {
    print('🥈 SilverPriceService: 🔍 Running comprehensive diagnostics...');

    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'service_status': {
        'is_mjdta_available': _isMjdtaAvailable,
        'last_mjdta_check': _lastMjdtaCheck?.toIso8601String(),
        'current_price': _currentPrice?.toJson(),
        'can_purchase': canPurchase,
      },
      'mjdta_test': null,
      'price_fetch_test': null,
    };

    try {
      // Test MJDTA connection and parsing
      diagnostics['mjdta_test'] = await _mjdtaService.testPriceFetching();

      // Test direct price fetch
      final testPrice = await testFetchSilverPrice();
      diagnostics['price_fetch_test'] = testPrice != null ? {
        'success': true,
        'price': testPrice.pricePerGram,
        'formatted': testPrice.formattedPrice,
        'timestamp': testPrice.timestamp.toIso8601String(),
      } : {
        'success': false,
        'error': 'Failed to fetch price',
      };

    } catch (e) {
      diagnostics['error'] = e.toString();
      print('🥈 SilverPriceService: 🔍 Diagnostics error: $e');
    }

    print('🥈 SilverPriceService: 🔍 Diagnostics completed');
    return diagnostics;
  }



  // Check if purchases are allowed (only when MJDTA is available)
  bool get canPurchase => _isMjdtaAvailable && _currentPrice != null;

  // Calculate SIP returns for silver
  Map<String, dynamic>? calculateSipReturns({
    required double monthlyAmount,
    required int months,
  }) {
    if (_currentPrice == null) return null;

    final currentPrice = _currentPrice!.pricePerGram;
    final totalInvestment = monthlyAmount * months;

    // Simulate average price over the period (with slight appreciation)
    final averagePrice = currentPrice * (1 + (0.04 * months / 12)); // 4% annual appreciation for silver
    final totalSilverQuantity = totalInvestment / averagePrice;

    // Calculate potential returns
    final futurePrice = currentPrice * (1 + (0.06 * months / 12)); // 6% annual appreciation for silver
    final futureValue = totalSilverQuantity * futurePrice;
    final potentialGain = futureValue - totalInvestment;
    final potentialGainPercent = (potentialGain / totalInvestment) * 100;

    return {
      'totalInvestment': totalInvestment,
      'averagePrice': averagePrice,
      'totalSilverQuantity': totalSilverQuantity,
      'currentValue': totalSilverQuantity * currentPrice,
      'futureValue': futureValue,
      'potentialGain': potentialGain,
      'potentialGainPercent': potentialGainPercent,
    };
  }

  // Get price alerts (for future implementation)
  Future<void> setPriceAlert({
    required double targetPrice,
    required String alertType, // 'above' or 'below'
  }) async {
    // TODO: Implement price alerts
    // This would typically involve backend integration
  }
}
