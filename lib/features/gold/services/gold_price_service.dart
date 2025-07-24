import 'dart:async';
import 'dart:math';
import '../models/gold_price_model.dart';
import 'metals_live_api_service.dart';
import 'mjdta_price_service.dart';

class GoldPriceService {
  static final GoldPriceService _instance = GoldPriceService._internal();
  factory GoldPriceService() => _instance;
  GoldPriceService._internal();

  // Stream controller for real-time price updates
  final StreamController<GoldPriceModel> _priceController = StreamController<GoldPriceModel>.broadcast();
  Stream<GoldPriceModel> get priceStream => _priceController.stream;

  // Current price cache
  GoldPriceModel? _currentPrice;
  Timer? _priceUpdateTimer;

  // API services for fetching live prices
  final MetalsLiveApiService _apiService = MetalsLiveApiService();
  final MjdtaPriceService _mjdtaService = MjdtaPriceService();

  // Fallback base prices for simulation when API is unavailable
  static const double _fallbackBasePrice24K = 7850.0; // 24K gold price per gram
  static const double _fallbackBasePrice22K = 7200.0; // 22K gold price per gram (more common in India)

  // Use 22K as default for calculations (matches MJDTA)
  static const double _fallbackBasePrice = _fallbackBasePrice22K;
  final Random _random = Random();

  // Track API availability
  bool _isApiAvailable = true;
  DateTime? _lastApiCheck;

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
  Future<GoldPriceModel> getCurrentPrice() async {
    if (_currentPrice == null) {
      await _loadInitialPrice();
    }
    return _currentPrice!;
  }

  // Start real-time price updates
  void _startPriceUpdates() {
    // Update every 2 minutes for live API calls (to avoid rate limiting)
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updatePrice();
    });
  }

  // Load initial price from API or fallback to simulation
  Future<void> _loadInitialPrice() async {
    try {
      print('GoldPriceService: Loading initial price from MJDTA...');

      // Try MJDTA first (most reliable for Indian market)
      final mjdtaPrice = await _mjdtaService.fetchGoldPrice();
      if (mjdtaPrice != null) {
        print('GoldPriceService: Successfully loaded price from MJDTA: ${mjdtaPrice.formattedPrice}');
        _currentPrice = mjdtaPrice;
        _isApiAvailable = true;
        _lastApiCheck = DateTime.now();
        _priceController.add(_currentPrice!);
        return;
      }

      print('GoldPriceService: MJDTA unavailable, trying metals.live...');
      final apiPrice = await _apiService.fetchGoldPrice();

      if (apiPrice != null) {
        print('GoldPriceService: Successfully loaded price from metals.live: ${apiPrice.formattedPrice}');
        _currentPrice = apiPrice;
        _isApiAvailable = true;
        _lastApiCheck = DateTime.now();
      } else {
        print('GoldPriceService: All APIs unavailable, using fallback simulation');
        _generateFallbackPrice();
        _isApiAvailable = false;
        _lastApiCheck = DateTime.now();
      }
    } catch (e) {
      print('GoldPriceService: Error loading initial price: $e');
      _generateFallbackPrice();
      _isApiAvailable = false;
      _lastApiCheck = DateTime.now();
    }

    if (_currentPrice != null) {
      _priceController.add(_currentPrice!);
    }
  }

  // Generate fallback price when API is unavailable
  void _generateFallbackPrice() {
    final now = DateTime.now();
    final priceVariation = (_random.nextDouble() - 0.5) * 100; // ±50 variation
    final newPrice = _fallbackBasePrice + priceVariation;

    _currentPrice = GoldPriceModel(
      pricePerGram: newPrice,
      pricePerOunce: newPrice * 31.1035, // 1 ounce = 31.1035 grams
      currency: 'INR',
      timestamp: now,
      changePercent: 0.0,
      changeAmount: 0.0,
      trend: 'stable',
    );
  }

  // Update price from API or fallback to simulation
  Future<void> _updatePrice() async {
    if (_currentPrice == null) return;

    try {
      // Check if we should retry API (every 10 minutes if it was down)
      final shouldRetryApi = !_isApiAvailable &&
          _lastApiCheck != null &&
          DateTime.now().difference(_lastApiCheck!).inMinutes >= 10;

      if (_isApiAvailable || shouldRetryApi) {
        print('GoldPriceService: Fetching updated price from MJDTA...');

        // Try MJDTA first
        final mjdtaPrice = await _mjdtaService.fetchGoldPrice();
        if (mjdtaPrice != null) {
          print('GoldPriceService: Successfully updated price from MJDTA: ${mjdtaPrice.formattedPrice}');
          _currentPrice = mjdtaPrice;
          _isApiAvailable = true;
          _lastApiCheck = DateTime.now();
          _priceController.add(_currentPrice!);
          return;
        }

        print('GoldPriceService: MJDTA unavailable, trying metals.live...');
        final apiPrice = await _apiService.fetchGoldPrice();

        if (apiPrice != null) {
          print('GoldPriceService: Successfully updated price from metals.live: ${apiPrice.formattedPrice}');
          _currentPrice = apiPrice;
          _isApiAvailable = true;
          _lastApiCheck = DateTime.now();
          _priceController.add(_currentPrice!);
          return;
        } else {
          print('GoldPriceService: All APIs still unavailable, falling back to simulation');
          _isApiAvailable = false;
          _lastApiCheck = DateTime.now();
        }
      }

      // Fallback to simulation if API is unavailable
      _updatePriceWithSimulation();
    } catch (e) {
      print('GoldPriceService: Error updating price: $e');
      _isApiAvailable = false;
      _lastApiCheck = DateTime.now();
      _updatePriceWithSimulation();
    }
  }

  // Update price with simulation when API is unavailable
  void _updatePriceWithSimulation() {
    if (_currentPrice == null) return;

    final now = DateTime.now();
    final previousPrice = _currentPrice!.pricePerGram;

    // Generate realistic price movement (±2% max change)
    final changePercent = (_random.nextDouble() - 0.5) * 4; // ±2%
    final changeAmount = previousPrice * (changePercent / 100);
    final newPrice = previousPrice + changeAmount;

    // Ensure price doesn't go below a reasonable minimum
    final finalPrice = newPrice < 5000 ? 5000.0 : newPrice;
    final finalChangeAmount = finalPrice - previousPrice;
    final finalChangePercent = (finalChangeAmount / previousPrice) * 100;

    String trend;
    if (finalChangePercent > 0.1) {
      trend = 'up';
    } else if (finalChangePercent < -0.1) {
      trend = 'down';
    } else {
      trend = 'stable';
    }

    _currentPrice = GoldPriceModel(
      pricePerGram: finalPrice,
      pricePerOunce: finalPrice * 31.1035,
      currency: 'INR',
      timestamp: now,
      changePercent: finalChangePercent,
      changeAmount: finalChangeAmount,
      trend: trend,
    );

    _priceController.add(_currentPrice!);
  }

  // Manual price refresh
  Future<GoldPriceModel> refreshPrice() async {
    await _updatePrice();
    return _currentPrice!;
  }

  // Get API availability status
  bool get isApiAvailable => _isApiAvailable;

  // Get price source description
  String get priceSource {
    if (_isApiAvailable) {
      return 'MJDTA Live Data (Chennai) - 22K';
    } else {
      return 'Simulated Data (₹${_fallbackBasePrice22K.toStringAsFixed(0)} base) - 22K';
    }
  }

  // Force API retry
  Future<void> retryApiConnection() async {
    _isApiAvailable = true;
    await _updatePrice();
  }

  // Get historical prices (simulated)
  Future<List<GoldPriceModel>> getHistoricalPrices({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<GoldPriceModel> historicalPrices = [];
    final daysDifference = endDate.difference(startDate).inDays;
    
    for (int i = 0; i <= daysDifference; i++) {
      final date = startDate.add(Duration(days: i));
      final basePrice = _currentPrice?.pricePerGram ?? _fallbackBasePrice;
      final priceVariation = (_random.nextDouble() - 0.5) * 200; // ±100 variation
      final price = basePrice + priceVariation;
      final changePercent = (_random.nextDouble() - 0.5) * 6; // ±3%
      final changeAmount = price * (changePercent / 100);
      
      String trend;
      if (changePercent > 0.5) {
        trend = 'up';
      } else if (changePercent < -0.5) {
        trend = 'down';
      } else {
        trend = 'stable';
      }

      historicalPrices.add(GoldPriceModel(
        pricePerGram: price,
        pricePerOunce: price * 31.1035,
        currency: 'INR',
        timestamp: date,
        changePercent: changePercent,
        changeAmount: changeAmount,
        trend: trend,
      ));
    }

    return historicalPrices;
  }

  // Calculate investment scenarios
  Map<String, dynamic> calculateInvestmentScenario({
    required double monthlyAmount,
    required int months,
  }) {
    final currentPrice = _currentPrice?.pricePerGram ?? _fallbackBasePrice;
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
