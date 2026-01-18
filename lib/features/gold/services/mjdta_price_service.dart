import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_price_model.dart';
import '../../silver/models/silver_price_model.dart';
import '../../../core/services/secure_http_client.dart';
import '../../../core/config/api_config.dart';

class MjdtaPriceService {
  static const String _baseUrl = 'https://thejewellersassociation.org';
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetch current gold price
  /// Updated to use backend API first, with local scraper as fallback
  Future<GoldPriceModel?> fetchGoldPrice() async {
    try {
      print('MjdtaPriceService: Fetching gold price from backend API...');
      
      final response = await SecureHttpClient.get(
        '${ApiConfig.baseUrl}/gold-price',
        timeout: _timeout,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['rate'] != null) {
          final double rate = data['rate'].toDouble();
          print('MjdtaPriceService: ✅ Received gold price from backend: ₹$rate');
          
          return GoldPriceModel(
            pricePerGram: rate,
            pricePerOunce: rate * 31.1035,
            currency: 'INR',
            timestamp: DateTime.now(),
            changePercent: 0.0,
            changeAmount: 0.0,
            trend: 'stable',
          );
        }
      }
      
      print('MjdtaPriceService: Backend API failed or returned error. Falling back to local scraper...');
      
      // Fallback to local scraper if backend fails
      final scraperResponse = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(_timeout);

      if (scraperResponse.statusCode == 200) {
        return _parseGoldPriceFromHtml(scraperResponse.body);
      }
      
      return null;
    } catch (e) {
      print('MjdtaPriceService: Error fetching gold price: $e');
      return null;
    }
  }

  /// Parse gold price from HTML content
  GoldPriceModel? _parseGoldPriceFromHtml(String htmlContent) {
    try {
      print('MjdtaPriceService: Parsing gold price from HTML...');

      double? gold22KPrice;

      // Method 1: Look for span with id="goldrate_22ct" or class="gold_rate"
      final spanPatterns = [
        RegExp(r'id="goldrate_22ct"[^>]*>([\d,]+\.?\d{0,2})'),
        RegExp(r'class="gold_rate"[^>]*>([\d,]+\.?\d{0,2})'),
      ];

      for (final pattern in spanPatterns) {
        final match = pattern.firstMatch(htmlContent);
        if (match != null) {
          final priceStr = match.group(1)?.replaceAll(',', '');
          if (priceStr != null) {
            gold22KPrice = double.tryParse(priceStr);
            if (gold22KPrice != null) {
              print('MjdtaPriceService: ✅ Found gold price: ₹$gold22KPrice');
              break;
            }
          }
        }
      }

      if (gold22KPrice == null) return null;

      return GoldPriceModel(
        pricePerGram: gold22KPrice,
        pricePerOunce: gold22KPrice * 31.1035,
        currency: 'INR',
        timestamp: DateTime.now(),
        changePercent: 0.0,
        changeAmount: 0.0,
        trend: 'stable',
      );
    } catch (e) {
      print('MjdtaPriceService: Error parsing gold HTML: $e');
      return null;
    }
  }

  /// Fetch current silver price
  /// Updated to use backend API first, with local scraper as fallback
  Future<SilverPriceModel?> fetchSilverPrice() async {
    try {
      print('MjdtaPriceService: Fetching silver price from backend API...');
      
      final response = await SecureHttpClient.get(
        '${ApiConfig.baseUrl}/silver-price',
        timeout: _timeout,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['rate'] != null) {
          final double rate = data['rate'].toDouble();
          print('MjdtaPriceService: ✅ Received silver price from backend: ₹$rate');
          
          return SilverPriceModel(
            pricePerGram: rate,
            pricePerOunce: rate * 31.1035,
            currency: 'INR',
            timestamp: DateTime.now(),
            changePercent: 0.0,
            changeAmount: 0.0,
            trend: 'stable',
          );
        }
      }
      
      print('MjdtaPriceService: Backend API failed for silver. Falling back to local scraper...');

      // Fallback to local scraper if backend fails
      final scraperResponse = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(_timeout);

      if (scraperResponse.statusCode == 200) {
        return _parseSilverPriceFromHtml(scraperResponse.body);
      }
      
      return null;
    } catch (e) {
      print('MjdtaPriceService: Error fetching silver price: $e');
      return null;
    }
  }

  /// Parse silver price from HTML content
  SilverPriceModel? _parseSilverPriceFromHtml(String htmlContent) {
    try {
      print('MjdtaPriceService: Parsing silver price from HTML...');
      double? silverPrice;

      // Improved Extraction: Anchored to "1 Gm Silver" text
      final anchoredPattern = RegExp(r'1\s*Gm\s*Silver.*?class="silver_rate"[^>]*>([\d,]+\.?\d{0,2})', dotAll: true);
      final anchoredMatch = anchoredPattern.firstMatch(htmlContent);
      
      if (anchoredMatch != null) {
        final priceStr = anchoredMatch.group(1)?.replaceAll(',', '');
        if (priceStr != null) {
          silverPrice = double.tryParse(priceStr);
        }
      }

      // Fallback: Generic class match
      if (silverPrice == null) {
        final genericPattern = RegExp(r'class="silver_rate"[^>]*>([\d,]+\.?\d{0,2})');
        final matches = genericPattern.allMatches(htmlContent);
        for (final match in matches) {
          final priceStr = match.group(1)?.replaceAll(',', '');
          if (priceStr != null) {
            final val = double.tryParse(priceStr);
            // Filter out hidden/low values like "9"
            if (val != null && val > 20.0) {
              silverPrice = val;
              break;
            }
          }
        }
      }

      if (silverPrice == null) return null;

      print('MjdtaPriceService: ✅ Found silver price: ₹$silverPrice');

      return SilverPriceModel(
        pricePerGram: silverPrice,
        pricePerOunce: silverPrice * 31.1035,
        currency: 'INR',
        timestamp: DateTime.now(),
        changePercent: 0.0,
        changeAmount: 0.0,
        trend: 'stable',
      );
    } catch (e) {
      print('MjdtaPriceService: Error parsing silver HTML: $e');
      return null;
    }
  }

  /// Test connectivity to MJDTA website
  Future<bool> testConnection() async {
    try {
      final response = await http.head(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('MjdtaPriceService: Connection test failed: $e');
      return false;
    }
  }

  /// Test both gold and silver price fetching with detailed logging
  Future<Map<String, dynamic>> testPriceFetching() async {
    final gold = await fetchGoldPrice();
    final silver = await fetchSilverPrice();
    return {
      'gold': gold != null ? {'price': gold.pricePerGram} : 'failed',
      'silver': silver != null ? {'price': silver.pricePerGram} : 'failed',
    };
  }

  /// Get additional information about MJDTA rates
  Map<String, dynamic> getMjdtaInfo() {
    return {
      'source': 'MJDTA (Madras Jewellery and Diamond Traders Association)',
      'location': 'Chennai, Tamil Nadu, India',
      'update_times': ['9:30 AM IST', '3:30 PM IST'],
      'gold_purity': '22K',
      'website': 'https://thejewellersassociation.org',
    };
  }
}

