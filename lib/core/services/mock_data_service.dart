import 'dart:math';

/// Service to provide mock data for testing purposes
class MockDataService {
  static final Random _random = Random();
  
  /// Generate mock transaction data for statements
  static List<Map<String, dynamic>> generateMockTransactions({
    required DateTime startDate,
    required DateTime endDate,
    int? count,
  }) {
    // If count is not specified, generate a random number of transactions
    final transactionCount = count ?? _random.nextInt(15) + 5; // 5-20 transactions
    
    final transactions = <Map<String, dynamic>>[];
    
    for (int i = 0; i < transactionCount; i++) {
      transactions.add(_generateSingleTransaction(startDate, endDate));
    }
    
    // Sort by date (newest first)
    transactions.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    
    return transactions;
  }
  
  /// Generate a single mock transaction
  static Map<String, dynamic> _generateSingleTransaction(DateTime startDate, DateTime endDate) {
    final transactionTypes = ['BUY', 'SELL'];
    final metalTypes = ['GOLD', 'SILVER'];
    final paymentMethods = ['UPI', 'Google Pay', 'PhonePe', 'Bank Transfer'];
    final statuses = ['SUCCESS', 'PENDING', 'FAILED'];
    
    // Generate random date between start and end
    final daysDifference = endDate.difference(startDate).inDays;
    final randomDays = _random.nextInt(daysDifference + 1);
    final transactionDate = startDate.add(Duration(days: randomDays));
    
    // Add random time
    final randomHour = _random.nextInt(24);
    final randomMinute = _random.nextInt(60);
    final randomSecond = _random.nextInt(60);
    final fullDate = DateTime(
      transactionDate.year,
      transactionDate.month,
      transactionDate.day,
      randomHour,
      randomMinute,
      randomSecond,
    );
    
    final transactionType = transactionTypes[_random.nextInt(transactionTypes.length)];
    final metalType = metalTypes[_random.nextInt(metalTypes.length)];
    final paymentMethod = paymentMethods[_random.nextInt(paymentMethods.length)];
    final status = statuses[_random.nextInt(statuses.length)];
    
    // Generate realistic amounts and prices
    final amount = _generateRealisticAmount();
    final pricePerGram = _generateRealisticPrice(metalType);
    final metalGrams = amount / pricePerGram;
    
    return {
      'transaction_id': 'TXN_${fullDate.millisecondsSinceEpoch}',
      'customer_phone': '9876543210',
      'customer_name': 'John Doe',
      'type': transactionType,
      'metal_type': metalType,
      'amount': amount,
      'metal_grams': metalGrams,
      'price_per_gram': pricePerGram,
      'payment_method': paymentMethod,
      'status': status,
      'timestamp': fullDate.toIso8601String(),
      'gateway_transaction_id': 'GTW_${_random.nextInt(999999999)}',
      'scheme_id': _random.nextBool() ? 'SCH_${_random.nextInt(99999)}' : null,
      'notes': _generateTransactionNotes(transactionType, metalType),
    };
  }
  
  /// Generate realistic transaction amounts
  static double _generateRealisticAmount() {
    final amounts = [
      1000, 2000, 3000, 5000, 7500, 10000, 15000, 20000, 25000, 30000,
      50000, 75000, 100000, 150000, 200000
    ];
    return amounts[_random.nextInt(amounts.length)].toDouble();
  }
  
  /// Generate realistic metal prices
  static double _generateRealisticPrice(String metalType) {
    if (metalType == 'GOLD') {
      // Gold prices typically range from 6000-8000 per gram
      return 6000 + _random.nextDouble() * 2000;
    } else {
      // Silver prices typically range from 80-120 per gram
      return 80 + _random.nextDouble() * 40;
    }
  }
  
  /// Generate transaction notes
  static String _generateTransactionNotes(String type, String metalType) {
    final notes = [
      '$type $metalType - Investment purchase',
      '$type $metalType - Portfolio diversification',
      '$type $metalType - Monthly SIP',
      '$type $metalType - Festival purchase',
      '$type $metalType - Bulk investment',
      '$type $metalType - Regular savings',
    ];
    return notes[_random.nextInt(notes.length)];
  }
  
  /// Generate mock customer data
  static Map<String, dynamic> generateMockCustomerData() {
    final names = ['John Doe', 'Jane Smith', 'Raj Patel', 'Priya Sharma', 'Amit Kumar'];
    final cities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Hyderabad'];
    
    return {
      'customer_id': 'CUST_${_random.nextInt(99999)}',
      'name': names[_random.nextInt(names.length)],
      'phone': '98765${_random.nextInt(99999).toString().padLeft(5, '0')}',
      'email': 'customer${_random.nextInt(999)}@example.com',
      'city': cities[_random.nextInt(cities.length)],
      'total_investment': _generateRealisticAmount() * 5,
      'total_gold_grams': _random.nextDouble() * 100,
      'total_silver_grams': _random.nextDouble() * 1000,
      'registration_date': DateTime.now().subtract(Duration(days: _random.nextInt(365))).toIso8601String(),
    };
  }
  
  /// Generate mock portfolio summary
  static Map<String, dynamic> generateMockPortfolioSummary() {
    final goldGrams = _random.nextDouble() * 50 + 10; // 10-60 grams
    final silverGrams = _random.nextDouble() * 500 + 100; // 100-600 grams
    final goldPrice = _generateRealisticPrice('GOLD');
    final silverPrice = _generateRealisticPrice('SILVER');
    
    return {
      'total_investment': goldGrams * goldPrice + silverGrams * silverPrice,
      'current_value': goldGrams * goldPrice * 1.1 + silverGrams * silverPrice * 1.05, // 5-10% gain
      'gold_holdings': {
        'grams': goldGrams,
        'current_price': goldPrice,
        'value': goldGrams * goldPrice,
      },
      'silver_holdings': {
        'grams': silverGrams,
        'current_price': silverPrice,
        'value': silverGrams * silverPrice,
      },
      'total_transactions': _random.nextInt(50) + 10,
      'last_transaction_date': DateTime.now().subtract(Duration(days: _random.nextInt(30))).toIso8601String(),
    };
  }
  
  /// Generate mock statement summary
  static Map<String, dynamic> generateMockStatementSummary(List<Map<String, dynamic>> transactions) {
    final totalAmount = transactions.fold<double>(0, (sum, txn) => sum + txn['amount']);
    final totalGoldGrams = transactions
        .where((txn) => txn['metal_type'] == 'GOLD')
        .fold<double>(0, (sum, txn) => sum + txn['metal_grams']);
    final totalSilverGrams = transactions
        .where((txn) => txn['metal_type'] == 'SILVER')
        .fold<double>(0, (sum, txn) => sum + txn['metal_grams']);
    
    final successfulTransactions = transactions.where((txn) => txn['status'] == 'SUCCESS').length;
    final pendingTransactions = transactions.where((txn) => txn['status'] == 'PENDING').length;
    final failedTransactions = transactions.where((txn) => txn['status'] == 'FAILED').length;
    
    return {
      'total_transactions': transactions.length,
      'successful_transactions': successfulTransactions,
      'pending_transactions': pendingTransactions,
      'failed_transactions': failedTransactions,
      'total_amount': totalAmount,
      'total_gold_grams': totalGoldGrams,
      'total_silver_grams': totalSilverGrams,
      'statement_generated_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// Check if mock data should be used (for testing)
  static bool shouldUseMockData() {
    // You can add logic here to determine when to use mock data
    // For now, we'll use an environment variable or debug flag
    return true; // Set to false in production
  }
  
  /// Get mock data configuration
  static Map<String, dynamic> getMockDataConfig() {
    return {
      'enabled': shouldUseMockData(),
      'transaction_count_range': '5-20 per period',
      'supported_periods': ['current_month', 'last_3_months', 'all_transactions', 'custom'],
      'metal_types': ['GOLD', 'SILVER'],
      'transaction_types': ['BUY', 'SELL'],
      'payment_methods': ['UPI', 'Google Pay', 'PhonePe', 'Bank Transfer'],
      'status_types': ['SUCCESS', 'PENDING', 'FAILED'],
    };
  }
}
