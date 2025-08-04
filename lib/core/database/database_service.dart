import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'digi_gold.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        gold_grams REAL NOT NULL,
        gold_price_per_gram REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        gateway_transaction_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create portfolio table
    await db.execute('''
      CREATE TABLE portfolio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_gold_grams REAL NOT NULL DEFAULT 0,
        total_silver_grams REAL NOT NULL DEFAULT 0,
        total_invested REAL NOT NULL DEFAULT 0,
        current_value REAL NOT NULL DEFAULT 0,
        profit_loss REAL NOT NULL DEFAULT 0,
        profit_loss_percentage REAL NOT NULL DEFAULT 0,
        last_updated TEXT NOT NULL
      )
    ''');

    // Create price history table
    await db.execute('''
      CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        price_per_gram_22k REAL NOT NULL,
        price_per_gram_24k REAL NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');

    // Insert initial portfolio record
    await db.insert('portfolio', {
      'total_gold_grams': 0.0,
      'total_silver_grams': 0.0,
      'total_invested': 0.0,
      'current_value': 0.0,
      'profit_loss': 0.0,
      'profit_loss_percentage': 0.0,
      'last_updated': DateTime.now().toIso8601String(),
    });

    print('Database tables created successfully');
  }

  // Transaction operations
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions({int? limit}) async {
    final db = await database;
    return await db.query(
      'transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateTransactionStatus(String transactionId, String status) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  // Portfolio operations
  Future<Map<String, dynamic>?> getPortfolio() async {
    final db = await database;
    final results = await db.query('portfolio', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updatePortfolio(Map<String, dynamic> portfolio) async {
    final db = await database;
    portfolio['last_updated'] = DateTime.now().toIso8601String();
    return await db.update(
      'portfolio',
      portfolio,
      where: 'id = ?',
      whereArgs: [1], // Always update the first (and only) record
    );
  }

  // Price history operations
  Future<int> insertPriceHistory(Map<String, dynamic> priceData) async {
    final db = await database;
    return await db.insert('price_history', priceData);
  }

  Future<List<Map<String, dynamic>>> getPriceHistory({int? limit}) async {
    final db = await database;
    return await db.query(
      'price_history',
      orderBy: 'timestamp DESC',
      limit: limit ?? 100,
    );
  }

  // Analytics
  Future<Map<String, dynamic>> getTransactionSummary() async {
    final db = await database;
    
    final totalBought = await db.rawQuery('''
      SELECT 
        SUM(gold_grams) as total_grams,
        SUM(amount) as total_invested,
        COUNT(*) as transaction_count
      FROM transactions 
      WHERE type = 'BUY' AND status = 'SUCCESS'
    ''');

    final totalSold = await db.rawQuery('''
      SELECT 
        SUM(gold_grams) as total_grams,
        SUM(amount) as total_received,
        COUNT(*) as transaction_count
      FROM transactions 
      WHERE type = 'SELL' AND status = 'SUCCESS'
    ''');

    return {
      'bought': totalBought.first,
      'sold': totalSold.first,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
