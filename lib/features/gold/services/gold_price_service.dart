import 'dart:async';
import '../models/gold_price_model.dart';
import 'mjdta_price_service.dart';

class GoldPriceService {
  static final GoldPriceService _instance = GoldPriceService._internal();
  factory GoldPriceService() => _instance;
  GoldPriceService._internal();

  // Stream controller for real-time price updates
  final StreamController<GoldPriceModel?> _priceController = StreamController<GoldPriceModel?>.broadcast();
  Stream<GoldPriceModel?> get priceStream => _priceController.stream;

  // Current price cache
  GoldPriceModel? _currentPrice;
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

  // Get current gold price
  GoldPriceModel? get currentPrice => _currentPrice;

  // Get current price as Future
  Future<GoldPriceModel?> getCurrentPrice() async {
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
        print('GoldPriceService: Loading initial price from MJDTA (attempt ${retryCount + 1}/$maxRetries)...');

        final mjdtaPrice = await _mjdtaService.fetchGoldPrice();
        if (mjdtaPrice != null) {
          print('GoldPriceService: Successfully loaded price from MJDTA: ${mjdtaPrice.formattedPrice}');
          _currentPrice = mjdtaPrice;
          _isMjdtaAvailable = true;
          _lastMjdtaCheck = DateTime.now();
          _priceController.add(_currentPrice);
          return;
        } else {
          print('GoldPriceService: ❌ MJDTA returned null price (attempt ${retryCount + 1})');
        }
      } catch (e) {
        print('GoldPriceService: Error loading initial price (attempt ${retryCount + 1}): $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        print('GoldPriceService: Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // All retries failed
    print('GoldPriceService: ❌ All retry attempts failed - no price data available');
    _currentPrice = null;
    _isMjdtaAvailable = false;
    _lastMjdtaCheck = DateTime.now();
    _priceController.add(null);
  }



  // Update price from MJDTA only
  Future<void> _updatePrice() async {
    try {
      // Check if we should retry MJDTA (every 5 minutes if it was down)
      final shouldRetryMjdta = !_isMjdtaAvailable &&
          _lastMjdtaCheck != null &&
          DateTime.now().difference(_lastMjdtaCheck!).inMinutes >= 5;

      if (_isMjdtaAvailable || shouldRetryMjdta) {
        print('GoldPriceService: Fetching updated price from MJDTA...');

        final mjdtaPrice = await _mjdtaService.fetchGoldPrice();
        if (mjdtaPrice != null) {
          print('GoldPriceService: Successfully updated price from MJDTA: ${mjdtaPrice.formattedPrice}');
          _currentPrice = mjdtaPrice;
          _isMjdtaAvailable = true;
          _lastMjdtaCheck = DateTime.now();
          _priceController.add(_currentPrice);
        } else {
          print('GoldPriceService: MJDTA still unavailable');
          _currentPrice = null;
          _isMjdtaAvailable = false;
          _lastMjdtaCheck = DateTime.now();
          _priceController.add(null);
        }
      }
    } catch (e) {
      print('GoldPriceService: Error updating price: $e');
      _currentPrice = null;
      _isMjdtaAvailable = false;
      _lastMjdtaCheck = DateTime.now();
      _priceController.add(null);
    }
  }



  // Manual price refresh
  Future<GoldPriceModel?> refreshPrice() async {
    await _updatePrice();
    return _currentPrice;
  }

  // Get MJDTA availability status
  bool get isMjdtaAvailable => _isMjdtaAvailable;

  // Get price source description
  String get priceSource {
    if (_isMjdtaAvailable) {
      return 'MJDTA Live Data (Chennai) - 22K';
    } else {
      return 'MJDTA Unavailable - No Price Data';
    }
  }

  // Force MJDTA retry
  Future<void> retryMjdtaConnection() async {
    await _updatePrice();
  }

  // Check if purchases are allowed (only when MJDTA is available)
  bool get canPurchase => _isMjdtaAvailable && _currentPrice != null;

  // Get historical prices (only available when MJDTA is working)
  Future<List<GoldPriceModel>> getHistoricalPrices({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Return empty list if MJDTA is not available
    if (!_isMjdtaAvailable || _currentPrice == null) {
      return [];
    }

    // Historical data would typically come from MJDTA API
    // For now, return empty list as we only support real-time data
    return [];
  }

  // Calculate investment scenarios (only available when MJDTA is working)
  Map<String, dynamic>? calculateInvestmentScenario({
    required double monthlyAmount,
    required int months,
  }) {
    // Return null if MJDTA is not available
    if (!_isMjdtaAvailable || _currentPrice == null) {
      return null;
    }

    final currentPrice = _currentPrice!.pricePerGram;
    final totalInvestment = monthlyAmount * months;

    // Simulate average price over the period (with slight appreciation)
    final averagePrice = currentPrice * (1 + (0.05 * months / 12)); // 5% annual appreciation
    final totalGoldQuantity = totalInvestment / averagePrice;

    // Calculate potential returns
    final futurePrice = currentPrice * (1 + (0.08 * months / 12)); // 8% annual appreciation
    final futureValue = totalGoldQuantity * futurePrice;
    final potentialGain = futureValue - totalInvestment;
    final potentialGainPercent = (potentialGain / totalInvestment) * 100;

    return {
      'totalInvestment': totalInvestment,
      'averagePrice': averagePrice,
      'totalGoldQuantity': totalGoldQuantity,
      'currentValue': totalGoldQuantity * currentPrice,
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
