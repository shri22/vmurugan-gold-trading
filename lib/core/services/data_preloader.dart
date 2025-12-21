import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../../features/portfolio/services/portfolio_service.dart';
import '../../features/gold/services/gold_scheme_service.dart';

/// Centralized data preloader for instant app experience
/// Fetches and caches all user data at login time
class DataPreloader {
  static const String _keyUserData = 'cached_user_data';
  static const String _keyTransactions = 'cached_transactions';
  static const String _keySchemes = 'cached_schemes';
  static const String _keyPortfolio = 'cached_portfolio';
  static const String _keyLastSync = 'last_data_sync';

  /// Preload all data at login - called once after successful login
  static Future<void> preloadAllData(String userPhone) async {
    print('🚀 PRELOADER: Starting data preload for $userPhone');
    final startTime = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Fetch all data in parallel for speed
      final results = await Future.wait([
        _fetchUserProfile(userPhone),
        _fetchTransactions(userPhone),
        _fetchSchemes(userPhone),
        _fetchPortfolio(userPhone),
      ]);

      // Save all data to cache
      if (results[0] != null) {
        await prefs.setString(_keyUserData, jsonEncode(results[0]));
      }
      if (results[1] != null) {
        await prefs.setString(_keyTransactions, jsonEncode(results[1]));
      }
      if (results[2] != null) {
        await prefs.setString(_keySchemes, jsonEncode(results[2]));
      }
      if (results[3] != null) {
        await prefs.setString(_keyPortfolio, jsonEncode(results[3]));
      }

      // Mark sync time
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());

      final duration = DateTime.now().difference(startTime);
      print('✅ PRELOADER: All data cached in ${duration.inMilliseconds}ms');
    } catch (e) {
      print('❌ PRELOADER: Error preloading data: $e');
    }
  }

  /// Refresh data in background - called when app opens
  static Future<void> refreshDataInBackground(String userPhone) async {
    print('🔄 PRELOADER: Background refresh started');
    
    // Run preload again (will update cache)
    await preloadAllData(userPhone);
  }

  /// Clear all cached data - called at logout
  static Future<void> clearAllData() async {
    print('🗑️ PRELOADER: Clearing all cached data');
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove(_keyUserData),
      prefs.remove(_keyTransactions),
      prefs.remove(_keySchemes),
      prefs.remove(_keyPortfolio),
      prefs.remove(_keyLastSync),
    ]);
    
    print('✅ PRELOADER: All data cleared');
  }

  /// Check if data needs refresh (older than 5 minutes)
  static Future<bool> needsRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_keyLastSync);
      
      if (lastSyncStr == null) return true;
      
      final lastSync = DateTime.parse(lastSyncStr);
      final age = DateTime.now().difference(lastSync);
      
      return age.inMinutes > 5; // Refresh if older than 5 minutes
    } catch (e) {
      return true;
    }
  }

  // Private fetch methods
  static Future<Map<String, dynamic>?> _fetchUserProfile(String phone) async {
    try {
      final result = await ApiService.getCustomerByPhone(phone);
      if (result['success'] == true) {
        return result['customer'];
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>?> _fetchTransactions(String phone) async {
    try {
      final portfolioService = PortfolioService();
      final transactions = await portfolioService.getTransactionHistory(limit: 100);
      return transactions.map((t) => t.toMap()).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>?> _fetchSchemes(String phone) async {
    try {
      final schemeService = GoldSchemeService();
      final schemes = await schemeService.fetchSchemesFromBackend();
      return schemes.map((s) => {
        'scheme_id': s.schemeId,
        'scheme_type': s.schemeType,
        'scheme_name': s.schemeName,
        'metal_type': s.metalType,
        'monthly_amount': s.monthlyAmount,
        'total_months': s.totalMonths,
        'completed_months': s.completedMonths,
        'status': s.status.toString(),
        'total_invested': s.totalInvested,
        'total_metal_accumulated': s.totalGoldAccumulated,
        'start_date': s.startDate.toIso8601String(),
        'end_date': s.endDate?.toIso8601String(),
        'has_paid_this_month': s.hasPaidThisMonth,
      }).toList();
    } catch (e) {
      print('Error fetching schemes: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _fetchPortfolio(String phone) async {
    try {
      final portfolioService = PortfolioService();
      final portfolio = await portfolioService.getPortfolio();
      return {
        'customer_id': portfolio.customerId,
        'customer_name': portfolio.customerName,
        'customer_email': portfolio.customerEmail,
        'total_gold_grams': portfolio.totalGoldGrams,
        'total_silver_grams': portfolio.totalSilverGrams,
        'total_invested': portfolio.totalInvested,
        'current_value': portfolio.currentValue,
        'profit_loss': portfolio.profitLoss,
        'profit_loss_percentage': portfolio.profitLossPercentage,
        'last_updated': portfolio.lastUpdated.toIso8601String(),
      };
    } catch (e) {
      print('Error fetching portfolio: $e');
    }
    return null;
  }
}
