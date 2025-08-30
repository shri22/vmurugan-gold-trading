class MockDataService {
  static bool shouldUseMockData() => false; // Always use real data in production

  static List<Map<String, dynamic>> generateMockTransactions({
    required String period,
    int count = 10,
  }) {
    // Generate mock transactions for testing
    final transactions = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      transactions.add({
        'id': 'TXN_${now.millisecondsSinceEpoch}_$i',
        'amount': (1000 + (i * 500)).toDouble(),
        'gold_grams': (1.0 + (i * 0.5)),
        'silver_grams': i % 2 == 0 ? (10.0 + (i * 2)) : null,
        'type': i % 2 == 0 ? 'BUY' : 'SELL',
        'status': 'SUCCESS',
        'created_at': now.subtract(Duration(days: i)).toIso8601String(),
        'payment_method': 'UPI',
      });
    }

    return transactions;
  }
}
