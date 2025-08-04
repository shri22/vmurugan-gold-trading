import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_service.dart';
import '../models/portfolio_model.dart';
import '../../gold/models/gold_price_model.dart';
import '../../schemes/models/scheme_installment_model.dart';

class PortfolioService {
  final DatabaseService _db = DatabaseService();

  // Get current portfolio
  Future<Portfolio> getPortfolio() async {
    try {
      final portfolioData = await _db.getPortfolio();
      if (portfolioData != null) {
        return Portfolio.fromMap(portfolioData);
      }
      
      // Return empty portfolio if none exists
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
    } catch (e) {
      print('Error getting portfolio: $e');
      rethrow;
    }
  }

  // Update portfolio after successful purchase
  Future<void> addGoldPurchase({
    required double goldGrams,
    required double amountPaid,
    required double pricePerGram,
  }) async {
    try {
      final currentPortfolio = await getPortfolio();
      
      final newTotalGrams = currentPortfolio.totalGoldGrams + goldGrams;
      final newTotalInvested = currentPortfolio.totalInvested + amountPaid;
      
      // Calculate current value (will be updated when price changes)
      final currentValue = newTotalGrams * pricePerGram;
      final profitLoss = currentValue - newTotalInvested;
      final profitLossPercentage = newTotalInvested > 0 ? (profitLoss / newTotalInvested) * 100 : 0.0;

      final updatedPortfolio = {
        'total_gold_grams': newTotalGrams,
        'total_invested': newTotalInvested,
        'current_value': currentValue,
        'profit_loss': profitLoss,
        'profit_loss_percentage': profitLossPercentage,
      };

      await _db.updatePortfolio(updatedPortfolio);
      print('Portfolio updated: +${goldGrams}g gold, +₹${amountPaid}');
    } catch (e) {
      print('Error updating portfolio: $e');
      rethrow;
    }
  }

  // Update portfolio after successful silver purchase
  Future<void> addSilverPurchase({
    required double silverGrams,
    required double amountPaid,
  }) async {
    try {
      final currentPortfolio = await getPortfolio();

      final newTotalSilverGrams = currentPortfolio.totalSilverGrams + silverGrams;
      final newTotalInvested = currentPortfolio.totalInvested + amountPaid;

      final updatedPortfolio = {
        'total_silver_grams': newTotalSilverGrams,
        'total_invested': newTotalInvested,
      };

      await _db.updatePortfolio(updatedPortfolio);
      print('Portfolio updated: +${silverGrams}g silver, +₹${amountPaid}');
    } catch (e) {
      print('Error updating portfolio with silver: $e');
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

  // Save transaction
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
      // Support backward compatibility
      final finalMetalGrams = metalGrams ?? goldGrams ?? 0.0;
      final finalMetalPricePerGram = metalPricePerGram ?? goldPricePerGram ?? 0.0;

      final transaction = Transaction(
        transactionId: transactionId,
        type: type,
        amount: amount,
        metalGrams: finalMetalGrams,
        metalPricePerGram: finalMetalPricePerGram,
        metalType: metalType,
        paymentMethod: paymentMethod,
        status: status,
        gatewayTransactionId: gatewayTransactionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.insertTransaction(transaction.toMap());
      
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
      
      print('Transaction saved: ${transaction.transactionId}');
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  // Get transaction history
  Future<List<Transaction>> getTransactionHistory({int? limit}) async {
    try {
      final transactionData = await _db.getTransactions(limit: limit);
      return transactionData.map((data) => Transaction.fromMap(data)).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final transactionData = await _db.getTransactionById(transactionId);
      if (transactionData != null) {
        return Transaction.fromMap(transactionData);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      await _db.updateTransactionStatus(transactionId, status.toString().split('.').last);
      
      // If transaction becomes successful, update portfolio
      if (status == TransactionStatus.SUCCESS) {
        final transaction = await getTransaction(transactionId);
        if (transaction != null && transaction.type == TransactionType.BUY) {
          await addGoldPurchase(
            goldGrams: transaction.goldGrams,
            amountPaid: transaction.amount,
            pricePerGram: transaction.goldPricePerGram,
          );
        }
      }
    } catch (e) {
      print('Error updating transaction status: $e');
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
