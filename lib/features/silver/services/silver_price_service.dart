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
    try {
      print('🥈 SilverPriceService: Loading initial price from MJDTA...');

      final silverPrice = await _mjdtaService.fetchSilverPrice();
      if (silverPrice != null) {
        print('🥈 SilverPriceService: ✅ Successfully loaded price from MJDTA: ${silverPrice.formattedPrice}');
        print('🥈 SilverPriceService: Raw price value: ${silverPrice.pricePerGram}');
        _currentPrice = silverPrice;
        _isMjdtaAvailable = true;
        _lastMjdtaCheck = DateTime.now();
        _priceController.add(_currentPrice);
      } else {
        print('🥈 SilverPriceService: ❌ MJDTA unavailable - no price data available');
        _currentPrice = null;
        _isMjdtaAvailable = false;
        _lastMjdtaCheck = DateTime.now();
        _priceController.add(null);
      }
    } catch (e) {
      print('SilverPriceService: Error loading initial price: $e');
      _currentPrice = null;
      _isMjdtaAvailable = false;
      _lastMjdtaCheck = DateTime.now();
      _priceController.add(null);
    }
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
