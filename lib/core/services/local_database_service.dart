import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'vmurugan_gold_trading.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String customersTable = 'customers';
  static const String transactionsTable = 'transactions';
  static const String schemesTable = 'schemes';
  static const String analyticsTable = 'analytics';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  static Future<void> _createTables(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE $customersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        address TEXT,
        pan_card TEXT,
        device_id TEXT,
        registration_date TEXT NOT NULL,
        business_id TEXT DEFAULT 'VMURUGAN_001',
        total_invested REAL DEFAULT 0.0,
        total_gold REAL DEFAULT 0.0,
        transaction_count INTEGER DEFAULT 0,
        last_transaction TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE $transactionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE NOT NULL,
        customer_phone TEXT,
        customer_name TEXT,
        type TEXT NOT NULL CHECK (type IN ('BUY', 'SELL')),
        amount REAL NOT NULL,
        metal_grams REAL NOT NULL,
        metal_price_per_gram REAL NOT NULL,
        metal_type TEXT NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
        gateway_transaction_id TEXT,
        device_info TEXT,
        location TEXT,
        business_id TEXT DEFAULT 'VMURUGAN_001',
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_phone) REFERENCES $customersTable (phone)
      )
    ''');

    // Schemes table
    await db.execute('''
      CREATE TABLE $schemesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheme_id TEXT UNIQUE NOT NULL,
        customer_id TEXT,
        customer_phone TEXT,
        customer_name TEXT,
        monthly_amount REAL NOT NULL,
        duration_months INTEGER NOT NULL,
        scheme_type TEXT NOT NULL,
        metal_type TEXT NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
        status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
        start_date TEXT NOT NULL,
        end_date TEXT,
        total_amount REAL,
        total_metal_grams REAL DEFAULT 0.0,
        completed_installments INTEGER DEFAULT 0,
        business_id TEXT DEFAULT 'VMURUGAN_001',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_phone) REFERENCES $customersTable (phone)
      )
    ''');

    // Scheme installments table
    await db.execute('''
      CREATE TABLE scheme_installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        installment_id TEXT UNIQUE NOT NULL,
        scheme_id TEXT NOT NULL,
        customer_phone TEXT,
        installment_number INTEGER NOT NULL,
        amount REAL NOT NULL,
        metal_grams REAL NOT NULL,
        metal_price_per_gram REAL NOT NULL,
        metal_type TEXT NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
        payment_method TEXT,
        transaction_id TEXT,
        status TEXT NOT NULL CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'CANCELLED')),
        due_date TEXT,
        paid_date TEXT,
        business_id TEXT DEFAULT 'VMURUGAN_001',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (scheme_id) REFERENCES $schemesTable (scheme_id),
        FOREIGN KEY (customer_phone) REFERENCES $customersTable (phone)
      )
    ''');

    // Analytics table
    await db.execute('''
      CREATE TABLE $analyticsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL,
        data TEXT,
        business_id TEXT DEFAULT 'VMURUGAN_001',
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_customers_phone ON $customersTable (phone)');
    await db.execute('CREATE INDEX idx_transactions_customer ON $transactionsTable (customer_phone)');
    await db.execute('CREATE INDEX idx_transactions_status ON $transactionsTable (status)');
    await db.execute('CREATE INDEX idx_transactions_timestamp ON $transactionsTable (timestamp)');
    await db.execute('CREATE INDEX idx_schemes_customer ON $schemesTable (customer_phone)');
    await db.execute('CREATE INDEX idx_analytics_event ON $analyticsTable (event)');

    print('✅ Local database tables created successfully');
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    print('Database upgraded from version $oldVersion to $newVersion');
  }

  // =============================================================================
  // CUSTOMER OPERATIONS
  // =============================================================================

  static Future<Map<String, dynamic>> saveCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String deviceId,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final customerData = {
        'phone': phone,
        'name': name,
        'email': email,
        'address': address,
        'pan_card': panCard,
        'device_id': deviceId,
        'registration_date': now,
        'business_id': 'VMURUGAN_001',
        'total_invested': 0.0,
        'total_gold': 0.0,
        'transaction_count': 0,
        'created_at': now,
        'updated_at': now,
      };

      await db.insert(
        customersTable,
        customerData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Customer saved to local database: $phone');
      
      return {
        'success': true,
        'message': 'Customer saved successfully to local database',
        'customer_id': phone,
      };
    } catch (e) {
      print('❌ Error saving customer to local database: $e');
      return {
        'success': false,
        'message': 'Failed to save customer: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        customersTable,
        where: 'phone = ?',
        whereArgs: [phone],
      );

      if (result.isNotEmpty) {
        return {
          'success': true,
          'customer': result.first,
        };
      } else {
        return {
          'success': false,
          'customer': null,
          'message': 'Customer not found',
        };
      }
    } catch (e) {
      print('❌ Error getting customer: $e');
      return {
        'success': false,
        'customer': null,
        'message': 'Error retrieving customer: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final db = await database;
      return await db.query(
        customersTable,
        orderBy: 'registration_date DESC',
      );
    } catch (e) {
      print('❌ Error getting all customers: $e');
      return [];
    }
  }

  // =============================================================================
  // TRANSACTION OPERATIONS
  // =============================================================================

  static Future<Map<String, dynamic>> saveTransaction({
    required String transactionId,
    required String customerPhone,
    required String customerName,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required String status,
    String? gatewayTransactionId,
    String? deviceInfo,
    String? location,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final transactionData = {
        'transaction_id': transactionId,
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'type': type,
        'amount': amount,
        'gold_grams': goldGrams,
        'gold_price_per_gram': goldPricePerGram,
        'payment_method': paymentMethod,
        'status': status,
        'gateway_transaction_id': gatewayTransactionId,
        'device_info': deviceInfo,
        'location': location,
        'business_id': 'VMURUGAN_001',
        'timestamp': now,
        'created_at': now,
      };

      await db.insert(
        transactionsTable,
        transactionData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update customer stats if transaction is successful
      if (status == 'SUCCESS' && type == 'BUY') {
        await _updateCustomerStats(customerPhone, amount, goldGrams);
      }

      print('✅ Transaction saved to local database: $transactionId');
      
      return {
        'success': true,
        'message': 'Transaction saved successfully to local database',
        'transaction_id': transactionId,
      };
    } catch (e) {
      print('❌ Error saving transaction to local database: $e');
      return {
        'success': false,
        'message': 'Failed to save transaction: $e',
      };
    }
  }

  static Future<void> _updateCustomerStats(String phone, double amount, double goldGrams) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.rawUpdate('''
        UPDATE $customersTable 
        SET total_invested = total_invested + ?,
            total_gold = total_gold + ?,
            transaction_count = transaction_count + 1,
            last_transaction = ?,
            updated_at = ?
        WHERE phone = ?
      ''', [amount, goldGrams, now, now, phone]);

      print('✅ Customer stats updated for: $phone');
    } catch (e) {
      print('❌ Error updating customer stats: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactions({
    String? customerPhone,
    String? status,
    int limit = 50,
  }) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (customerPhone != null) {
        whereClause = 'customer_phone = ?';
        whereArgs.add(customerPhone);
      }

      if (status != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'status = ?';
        whereArgs.add(status);
      }

      return await db.query(
        transactionsTable,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }

  // =============================================================================
  // SCHEME OPERATIONS
  // =============================================================================

  static Future<Map<String, dynamic>> saveScheme({
    required String schemeId,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required double monthlyAmount,
    required int durationMonths,
    required String schemeType,
    required String status,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final endDate = DateTime.now().add(Duration(days: durationMonths * 30)).toIso8601String();

      final schemeData = {
        'scheme_id': schemeId,
        'customer_id': customerId,
        'customer_phone': customerPhone,
        'customer_name': customerName,
        'monthly_amount': monthlyAmount,
        'duration_months': durationMonths,
        'scheme_type': schemeType,
        'status': status,
        'start_date': now,
        'end_date': endDate,
        'total_amount': monthlyAmount * durationMonths,
        'total_gold': 0.0,
        'business_id': 'VMURUGAN_001',
        'created_at': now,
        'updated_at': now,
      };

      await db.insert(
        schemesTable,
        schemeData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Scheme saved to local database: $schemeId');

      return {
        'success': true,
        'message': 'Scheme saved successfully to local database',
        'scheme_id': schemeId,
      };
    } catch (e) {
      print('❌ Error saving scheme to local database: $e');
      return {
        'success': false,
        'message': 'Failed to save scheme: $e',
      };
    }
  }

  // =============================================================================
  // ANALYTICS OPERATIONS
  // =============================================================================

  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final analyticsData = {
        'event': event,
        'data': data.toString(),
        'business_id': 'VMURUGAN_001',
        'timestamp': now,
        'created_at': now,
      };

      await db.insert(analyticsTable, analyticsData);
      print('✅ Analytics logged to local database: $event');
    } catch (e) {
      print('❌ Error logging analytics: $e');
    }
  }

  // =============================================================================
  // DASHBOARD & STATISTICS
  // =============================================================================

  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final db = await database;

      // Get statistics
      final List<Map<String, dynamic>> statsResult = await db.rawQuery('''
        SELECT
          COUNT(DISTINCT customer_phone) as total_customers,
          COUNT(*) as total_transactions,
          SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) as total_revenue,
          SUM(CASE WHEN status = 'SUCCESS' THEN gold_grams ELSE 0 END) as total_gold_sold
        FROM $transactionsTable
      ''');

      // Get recent transactions
      final List<Map<String, dynamic>> recentTransactions = await getTransactions(limit: 20);

      // Get customers
      final List<Map<String, dynamic>> customers = await getAllCustomers();

      return {
        'success': true,
        'data': {
          'stats': statsResult.isNotEmpty ? statsResult.first : {},
          'recent_transactions': recentTransactions,
          'customers': customers,
        },
      };
    } catch (e) {
      print('❌ Error getting dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get dashboard data: $e',
        'data': {},
      };
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      final customers = await getAllCustomers();
      final transactions = await getTransactions(limit: 1000);
      final analytics = await _getAllAnalytics();

      return {
        'success': true,
        'data': {
          'customers': customers,
          'transactions': transactions,
          'analytics': analytics,
          'export_date': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ Error exporting data: $e');
      return {
        'success': false,
        'message': 'Failed to export data: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> _getAllAnalytics() async {
    try {
      final db = await database;
      return await db.query(
        analyticsTable,
        orderBy: 'timestamp DESC',
        limit: 1000,
      );
    } catch (e) {
      print('❌ Error getting analytics: $e');
      return [];
    }
  }

  static Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(customersTable);
      await db.delete(transactionsTable);
      await db.delete(schemesTable);
      await db.delete(analyticsTable);
      print('✅ All local data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('✅ Database closed');
    }
  }

  // Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;
      final customerCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $customersTable')
      ) ?? 0;

      final transactionCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $transactionsTable')
      ) ?? 0;

      final schemeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $schemesTable')
      ) ?? 0;

      return {
        'database_name': _databaseName,
        'database_version': _databaseVersion,
        'customers_count': customerCount,
        'transactions_count': transactionCount,
        'schemes_count': schemeCount,
        'database_path': join(await getDatabasesPath(), _databaseName),
      };
    } catch (e) {
      print('❌ Error getting database info: $e');
      return {};
    }
  }
}
