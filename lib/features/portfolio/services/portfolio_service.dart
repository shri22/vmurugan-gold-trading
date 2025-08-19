import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_service.dart';
import '../models/portfolio_model.dart';
import '../../gold/models/gold_price_model.dart';
import '../../schemes/models/scheme_installment_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/client_server_config.dart';

class PortfolioService {
  final DatabaseService _db = DatabaseService();
  static const String baseUrl = ClientServerConfig.baseUrl;

  // Get current user ID from shared preferences
  Future<int?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('current_user_id');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Get current user phone from shared preferences
  Future<String?> _getUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_phone');
    } catch (e) {
      print('Error getting user phone: $e');
      return null;
    }
  }

  // Get current portfolio from server
  Future<Portfolio> getPortfolio() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('📊 PortfolioService: Fetching portfolio from server for user $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/portfolio?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final portfolioData = data['portfolio'];
          print('✅ PortfolioService: Portfolio fetched successfully');

          return Portfolio(
            id: userId,
            totalGoldGrams: (portfolioData['total_gold_grams'] ?? 0.0).toDouble(),
            totalSilverGrams: (portfolioData['total_silver_grams'] ?? 0.0).toDouble(),
            totalInvested: (portfolioData['total_invested'] ?? 0.0).toDouble(),
            currentValue: (portfolioData['current_value'] ?? 0.0).toDouble(),
            profitLoss: (portfolioData['profit_loss'] ?? 0.0).toDouble(),
            profitLossPercentage: (portfolioData['profit_loss_percentage'] ?? 0.0).toDouble(),
            lastUpdated: DateTime.parse(portfolioData['last_updated'] ?? DateTime.now().toIso8601String()),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch portfolio');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PortfolioService: Error getting portfolio: $e');

      // Fallback to empty portfolio
      return Portfolio(
        id: 1,
        totalGoldGrams: 0.0,
        totalSilverGrams: 0.0,
        totalInvested: 0.0,
        currentValue: 0.0,
        profitLoss: 0.0,
        profitLossPercentage: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Update portfolio after successful purchase - SERVER VERSION
  Future<void> addGoldPurchase({
    required double goldGrams,
    required double amountPaid,
    required double pricePerGram,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('📊 PortfolioService: Updating portfolio on server - Gold purchase');

      // For Node.js server, we'll create the transaction and let the portfolio be calculated from transactions
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'customer_phone': await _getUserPhone(),
          'amount': amountPaid,
          'gold_grams': goldGrams,
          'silver_grams': 0.0,
          'metal_type': 'GOLD',
          'transaction_type': 'BUY',
          'status': 'SUCCESS',
          'gold_price_per_gram': pricePerGram,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ PortfolioService: Gold purchase added to portfolio successfully');
          print('📊 New Gold: ${goldGrams}g, Amount: ₹${amountPaid}');
        } else {
          throw Exception(data['message'] ?? 'Failed to update portfolio');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PortfolioService: Error updating portfolio with gold: $e');
      rethrow;
    }
  }

  // Update portfolio after successful silver purchase - SERVER VERSION
  Future<void> addSilverPurchase({
    required double silverGrams,
    required double amountPaid,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('📊 PortfolioService: Updating portfolio on server - Silver purchase');

      // For Node.js server, create silver transaction
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'customer_phone': await _getUserPhone(),
          'amount': amountPaid,
          'gold_grams': 0.0,
          'silver_grams': silverGrams,
          'metal_type': 'SILVER',
          'transaction_type': 'BUY',
          'status': 'SUCCESS',
          'silver_price_per_gram': amountPaid / silverGrams,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ PortfolioService: Silver purchase added to portfolio successfully');
          print('📊 New Silver: ${silverGrams}g, Amount: ₹${amountPaid}');
        } else {
          throw Exception(data['message'] ?? 'Failed to update portfolio');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PortfolioService: Error updating portfolio with silver: $e');
      rethrow;
    }
  }

  // Update portfolio value based on current gold price
  Future<void> updatePortfolioValue(GoldPriceModel currentPrice) async {
    try {
      final portfolio = await getPortfolio();
      
      if (portfolio.totalGoldGrams > 0) {
        final currentValue = portfolio.totalGoldGrams * currentPrice.pricePerGram;
        final profitLoss = currentValue - portfolio.totalInvested;
        final profitLossPercentage = portfolio.totalInvested > 0 ? (profitLoss / portfolio.totalInvested) * 100 : 0.0;

        final updatedPortfolio = {
          'current_value': currentValue,
          'profit_loss': profitLoss,
          'profit_loss_percentage': profitLossPercentage,
        };

        await _db.updatePortfolio(updatedPortfolio);
      }
    } catch (e) {
      print('Error updating portfolio value: $e');
    }
  }

  // Save transaction - SERVER VERSION
  Future<void> saveTransaction({
    required String transactionId,
    required TransactionType type,
    required double amount,
    required double metalGrams,
    required double metalPricePerGram,
    required MetalType metalType,
    required String paymentMethod,
    required TransactionStatus status,
    String? gatewayTransactionId,
    // Backward compatibility
    double? goldGrams,
    double? goldPricePerGram,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Support backward compatibility
      final finalMetalGrams = metalGrams ?? goldGrams ?? 0.0;
      final finalMetalPricePerGram = metalPricePerGram ?? goldPricePerGram ?? 0.0;

      print('📊 PortfolioService: Saving transaction to server');

      final response = await http.post(
        Uri.parse('$baseUrl/transaction_create.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transaction_id': transactionId,
          'type': type.toString().split('.').last.toUpperCase(),
          'metal_type': metalType.name.toUpperCase(),
          'quantity': finalMetalGrams,
          'price_per_gram': finalMetalPricePerGram,
          'total_amount': amount,
          'payment_method': paymentMethod,
          'payment_status': status.toString().split('.').last.toUpperCase(),
          'gateway_transaction_id': gatewayTransactionId ?? '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ PortfolioService: Transaction saved successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to save transaction');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
      
      // If transaction is successful and it's a purchase, update portfolio
      if (status == TransactionStatus.SUCCESS && type == TransactionType.BUY) {
        if (metalType == MetalType.gold) {
          await addGoldPurchase(
            goldGrams: finalMetalGrams,
            amountPaid: amount,
            pricePerGram: finalMetalPricePerGram,
          );
        } else {
          await addSilverPurchase(
            silverGrams: finalMetalGrams,
            amountPaid: amount,
          );
        }
      }
      
      print('✅ Transaction saved: $transactionId');
    } catch (e) {
      print('❌ Error saving transaction: $e');
      rethrow;
    }
  }

  // Get transaction history - SERVER VERSION
  Future<List<Transaction>> getTransactionHistory({int? limit}) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('📊 PortfolioService: Fetching transaction history from server');

      final userPhone = await _getUserPhone();
      if (userPhone == null) {
        throw Exception('User phone not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transaction-history?phone=$userPhone&limit=${limit ?? 50}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final transactions = data['transactions'] as List;
          print('✅ PortfolioService: Transaction history fetched successfully');

          return transactions.map((txnData) => Transaction.fromMap({
            'id': txnData['id'],
            'transaction_id': txnData['transaction_id'],
            'type': txnData['transaction_type'] ?? 'BUY',
            'amount': txnData['amount'],
            'metal_grams': (txnData['gold_grams'] ?? 0.0) + (txnData['silver_grams'] ?? 0.0),
            'metal_price_per_gram': txnData['gold_price_per_gram'] ?? txnData['silver_price_per_gram'] ?? 0.0,
            'metal_type': txnData['metal_type'] ?? 'GOLD',
            'payment_method': txnData['payment_method'] ?? 'NET_BANKING',
            'status': txnData['status'],
            'gateway_transaction_id': txnData['gateway_transaction_id'],
            'created_at': txnData['timestamp'],
            'updated_at': txnData['updated_at'] ?? txnData['timestamp'],
          })).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch transaction history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PortfolioService: Error getting transaction history: $e');
      return [];
    }
  }

  // Get transaction by ID - SERVER VERSION
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('📊 PortfolioService: Fetching transaction from server: $transactionId');

      // Get transaction history and find the specific transaction
      final transactions = await getTransactionHistory(limit: 100);
      final transaction = transactions.where((t) => t.transactionId == transactionId).firstOrNull;

      if (transaction != null) {
        print('✅ PortfolioService: Transaction found: $transactionId');
        return transaction;
      } else {
        print('❌ PortfolioService: Transaction not found: $transactionId');
        return null;
      }
    } catch (e) {
      print('❌ PortfolioService: Error getting transaction: $e');
      return null;
    }
  }

  // Update transaction status - SERVER VERSION
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      print('📊 PortfolioService: Updating transaction status on server');

      final response = await http.post(
        Uri.parse('$baseUrl/transaction-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': transactionId,
          'status': status.toString().split('.').last.toUpperCase(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ PortfolioService: Transaction status updated successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to update transaction status');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PortfolioService: Error updating transaction status: $e');
      rethrow;
    }
  }

  // Get portfolio summary
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    try {
      final portfolio = await getPortfolio();
      final transactions = await getTransactionHistory(limit: 10);
      final summary = await _db.getTransactionSummary();
      
      return {
        'portfolio': portfolio,
        'recent_transactions': transactions,
        'summary': summary,
        'total_transactions': transactions.length,
      };
    } catch (e) {
      print('Error getting portfolio summary: $e');
      return {};
    }
  }

  // Save price history
  Future<void> savePriceHistory(GoldPriceModel price, String source) async {
    try {
      final priceHistory = PriceHistory(
        pricePer22K: price.pricePerGram,
        pricePer24K: price.pricePerGram * 1.09, // Approximate 24K price
        timestamp: DateTime.now(),
        source: source,
      );

      await _db.insertPriceHistory(priceHistory.toMap());
    } catch (e) {
      print('Error saving price history: $e');
    }
  }

  // Get price history
  Future<List<PriceHistory>> getPriceHistory({int? limit}) async {
    try {
      final priceData = await _db.getPriceHistory(limit: limit);
      return priceData.map((data) => PriceHistory.fromMap(data)).toList();
    } catch (e) {
      print('Error getting price history: $e');
      return [];
    }
  }
}
