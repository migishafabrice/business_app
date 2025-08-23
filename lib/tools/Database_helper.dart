import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'MyShop.db';
  static const _databaseVersion = 1;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get device directory for databases
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    // Open the database
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL to create the database tables
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopname TEXT,
        shopaddress TEXT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CHECK (email LIKE '%@%.%'),
        CHECK (length(phone) >= 10)
      )
    ''');

    // You can create more tables here
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE products_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        date_at DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        paid TEXT NOT NULL,
        date_at DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        sale_quantity INTEGER NOT NULL,
        unit_sale_price REAL NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE debt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        names TEXT NOT NULL,
        email TEXT,
        phone TEXT NOT NULL,
        address TEXT,
        debt_amount REAL NOT NULL,
        proposed_refund_date DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE paid_debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        refund_amount REAL NOT NULL,
        mode TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (debt_id) REFERENCES debt (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE spents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reason TEXT NOT NULL,
        reason_description TEXT,
        spent_amount REAL NOT NULL,
        date_at Date NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Generic transaction method
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction) action,
  ) async {
    final db = await database;
    return await db.transaction<T>(action);
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      user['created_at'] = now;
      return await txn.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<bool> hasAnyuser() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM users");
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<bool> authenticateUser(String username, String password) async {
    return await executeTransaction((txn) async {
      final result = await txn.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty;
    });
  }

  // Product operations
  Future<int> insertPurchase(List<Map<String, dynamic>> purchases) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      int result = 0;

      for (final purchase in purchases) {
        final updatedPurchase = {...purchase, 'created_at': now};

        final existingProduct = await txn.query(
          'products',
          where: 'name = ?',
          whereArgs: [updatedPurchase['name']],
          limit: 1,
        );

        int productId;

        if (existingProduct.isNotEmpty) {
          // Product exists - update quantity and price
          final existing = existingProduct.first;
          productId = existing['id'] as int;
          final newQuantity =
              (existing['quantity'] as int) +
              (updatedPurchase['quantity'] as int);
          final newPrice =
              updatedPurchase['unit_price'] > existing['unit_price']
              ? updatedPurchase['unit_price']
              : existing['unit_price'];

          result = await txn.update(
            'products',
            {
              'quantity': newQuantity,
              'unit_price': newPrice,
              'created_at': now,
            },
            where: 'id = ?',
            whereArgs: [productId],
          );
        } else {
          // Product doesn't exist - insert new record
          final date = updatedPurchase['date_at'];
          updatedPurchase.remove('date_at');
          productId = await txn.insert(
            'products',
            updatedPurchase,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          updatedPurchase['date_at'] = date;
          result = productId;
        }

        // Insert into history table
        await txn.insert('products_history', {
          'product_id': productId,
          'unit_price': updatedPurchase['unit_price'],
          'quantity': updatedPurchase['quantity'],
          'date_at': updatedPurchase['date_at'],
          'created_at': now,
        });
      }

      return result;
    });
  }

  Future<List<Map<String, dynamic>>> loadItems() async {
    return await executeTransaction((txn) async {
      return await txn.query('products');
    });
  }

  Future<int> updateProductQuantity(int productId, int newQuantity) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      return await txn.update(
        'products',
        {'quantity': newQuantity, 'created_at': now},
        where: 'id = ?',
        whereArgs: [productId],
      );
    });
  }

  // Method to update product quantity with existing database connection
  Future<int> updateProductQuantityWithDb(
    Transaction txn,
    int productId,
    int newQuantity,
  ) async {
    final now = DateTime.now().toIso8601String();
    return await txn.update(
      'products',
      {'quantity': newQuantity, 'created_at': now},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Invoice operations
  Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      invoice['created_at'] = now;
      return await txn.insert(
        'invoices',
        invoice,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Method to insert invoice with existing database connection
  Future<int> insertInvoiceWithDb(
    Transaction txn,
    Map<String, dynamic> invoice,
  ) async {
    final now = DateTime.now().toIso8601String();
    invoice['created_at'] = now;
    return await txn.insert(
      'invoices',
      invoice,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Sale operations
  Future<int> insertSaleRecord(Map<String, dynamic> saleRecord) async {
    return await executeTransaction((txn) async {
      return await txn.insert(
        'sales',
        saleRecord,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Method to insert sale record with existing database connection
  Future<int> insertSaleRecordWithDb(
    Transaction txn,
    Map<String, dynamic> saleRecord,
  ) async {
    return await txn.insert(
      'sales',
      saleRecord,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Spent operations
  Future<int> insertSpent(Map<String, dynamic> spentData) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      spentData['created_at'] = now;
      return await txn.insert(
        'spents',
        spentData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Method to insert spent with existing database connection
  Future<int> insertSpentWithDb(
    Transaction txn,
    Map<String, dynamic> spentData,
  ) async {
    final now = DateTime.now().toIso8601String();
    spentData['created_at'] = now;
    return await txn.insert(
      'spents',
      spentData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Debt operations
  Future<int> insertDebt(Map<String, dynamic> debtData) async {
    return await executeTransaction((txn) async {
      final now = DateTime.now().toIso8601String();
      debtData['created_at'] = now;
      return await txn.insert(
        'debt',
        debtData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Method to insert debt with existing database connection
  Future<int> insertDebtWithDb(
    Transaction txn,
    Map<String, dynamic> debtData,
  ) async {
    final now = DateTime.now().toIso8601String();
    debtData['created_at'] = now;
    return await txn.insert(
      'debt',
      debtData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to insert purchase with existing database connection
  Future<int> insertPurchaseWithDb(
    Transaction txn,
    Map<String, dynamic> purchaseData,
  ) async {
    final now = DateTime.now().toIso8601String();
    purchaseData['created_at'] = now;
    return await txn.insert(
      'products',
      purchaseData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Report operations
  Future<double> getSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      if (startDate != null && endDate != null) {
        final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
        final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
        final result = await txn.rawQuery(
          "SELECT SUM(s.unit_sale_price * s.sale_quantity) AS total_sales "
          "FROM sales s JOIN invoices i ON s.invoice_id = i.id "
          "WHERE DATE(i.date_at) BETWEEN ? AND ?",
          [startDateStr, endDateStr],
        );
        return result.isNotEmpty
            ? (result.first['total_sales'] as double?) ?? 0
            : 0;
      } else {
        final String formattedDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
        final result = await txn.rawQuery(
          "SELECT SUM(unit_sale_price * sale_quantity) AS total_sales FROM sales WHERE created_at LIKE ?",
          ['%$formattedDate%'],
        );
        return result.isNotEmpty
            ? (result.first['total_sales'] as double?) ?? 0
            : 0;
      }
    });
  }

  Future<double> getPurchasesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      if (startDate != null && endDate != null) {
        final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
        final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
        final result = await txn.rawQuery(
          "SELECT SUM(unit_price * quantity) AS total_purchases FROM products_history WHERE DATE(date_at) BETWEEN ? AND ?",
          [startDateStr, endDateStr],
        );
        return result.isNotEmpty
            ? (result.first['total_purchases'] as double?) ?? 0
            : 0;
      } else {
        final String formattedDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
        final result = await txn.rawQuery(
          "SELECT SUM(unit_price * quantity) AS total_purchases FROM products_history WHERE date_at LIKE ?",
          ['%$formattedDate%'],
        );
        return result.isNotEmpty
            ? (result.first['total_purchases'] as double?) ?? 0
            : 0;
      }
    });
  }

  Future<double> getSpentsAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      if (startDate != null && endDate != null) {
        final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
        final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
        final result = await txn.rawQuery(
          "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date_at) BETWEEN ? AND ?",
          [startDateStr, endDateStr],
        );
        return result.isNotEmpty
            ? (result.first['total_spents'] as double?) ?? 0
            : 0;
      } else {
        final String formattedDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
        final result = await txn.rawQuery(
          "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date_at) LIKE ?",
          ['%$formattedDate%'],
        );
        return result.isNotEmpty
            ? (result.first['total_spents'] as double?) ?? 0
            : 0;
      }
    });
  }

  Future<double> getDebtsAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      if (startDate != null && endDate != null) {
        final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
        final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
        final result = await txn.rawQuery(
          "SELECT SUM(debt_amount) AS total_debts FROM debt WHERE DATE(created_at) BETWEEN ? AND ?",
          [startDateStr, endDateStr],
        );
        return result.isNotEmpty
            ? (result.first['total_debts'] as double?) ?? 0
            : 0;
      } else {
        final String formattedDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
        final result = await txn.rawQuery(
          "SELECT SUM(debt_amount) AS total_debts FROM debt WHERE created_at LIKE ?",
          ['%$formattedDate%'],
        );
        return result.isNotEmpty
            ? (result.first['total_debts'] as double?) ?? 0
            : 0;
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllDebts() async {
    return await executeTransaction((txn) async {
      // Single query to get all debts with their total refunded amounts
      final query = """
      SELECT 
        d.*,
        COALESCE(SUM(pd.refund_amount), 0) as total_refunded,
        (d.debt_amount - COALESCE(SUM(pd.refund_amount), 0)) as rest_amount,
        CASE 
          WHEN COALESCE(SUM(pd.refund_amount), 0) < d.debt_amount THEN 1 
          ELSE 0 
        END as is_unpaid_or_partial
      FROM debt d
      LEFT JOIN paid_debts pd ON d.id = pd.debt_id
      GROUP BY d.id
      HAVING is_unpaid_or_partial = 1
    """;

      final debts = await txn.rawQuery(query);
      if (debts.isEmpty) return [];

      // Get all invoice IDs for batch query
      final invoiceIds = debts
          .map((debt) => debt['invoice_id'] as int)
          .where((id) => id != 0)
          .toSet() // Remove duplicates
          .toList();

      if (invoiceIds.isEmpty) return [];

      // Single query to get all sales products for all relevant invoices
      final placeholders = List.generate(
        invoiceIds.length,
        (_) => '?',
      ).join(',');
      final salesQuery =
          """
      SELECT 
        s.*, 
        p.name as name,
        s.unit_sale_price,
        s.sale_quantity,
        s.invoice_id,
        (s.unit_sale_price * s.sale_quantity) as product_total
      FROM sales s 
      JOIN products p ON s.product_id = p.id 
      WHERE s.invoice_id IN ($placeholders)
      ORDER BY s.invoice_id, p.name
    """;

      final allSales = await txn.rawQuery(salesQuery, invoiceIds);

      // Group sales by invoice_id for easy lookup
      final salesByInvoice = <int, List<Map<String, dynamic>>>{};
      for (var sale in allSales) {
        final invoiceId = sale['invoice_id'] as int;

        salesByInvoice.putIfAbsent(invoiceId, () => []).add(sale);
      }

      // Build result with pre-filtered data
      final result = <Map<String, dynamic>>[];
      for (var debt in debts) {
        final invoiceId = debt['invoice_id'] as int?;
        if (invoiceId == null) continue;

        final salesProducts = salesByInvoice[invoiceId] ?? [];

        // Calculate total sale for this invoice
        double totalSale = 0;
        for (var sale in salesProducts) {
          totalSale +=
              (sale['unit_sale_price'] as num) * (sale['sale_quantity'] as num);
        }

        result.add({
          'id': debt['id'],
          'names': debt['names'],
          'email': debt['email'],
          'phone': debt['phone'],
          'address': debt['address'],
          'total_sale': totalSale,
          'debt_amount': debt['debt_amount'],
          'proposed_refund_date': debt['proposed_refund_date'],
          'total_refunded': debt['total_refunded'],
          'rest_amount': debt['rest_amount'],
          'salesProducts': salesProducts,
        });
      }

      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchaseReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        if (startDate == endDate) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(startDate);
          whereClause = 'ph.date_at like ?';
          whereArgs = ['%$formattedDate%'];
        } else {
          whereClause = 'ph.date_at >= ? AND ph.date_at <= ?';
          whereArgs = [
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
          ];
        }
      }

      String query = '''
        SELECT 
          p.name as name,
          ph.unit_price as unit_price,
          ph.quantity as quantity,
          (ph.unit_price * ph.quantity) AS total,
          ph.date_at
        FROM products_history ph 
        JOIN products p ON ph.product_id = p.id
      ''';

      if (whereClause.isNotEmpty) {
        query += ' WHERE $whereClause';
      }

      query += ' ORDER BY ph.date_at DESC';

      return await txn.rawQuery(query, whereArgs);
    });
  }

  Future<List<Map<String, dynamic>>> getSaleReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        if (startDate == endDate) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(startDate);
          whereClause = 'inv.date_at like ?';
          whereArgs = ['%$formattedDate%'];
        } else {
          whereClause = 'inv.date_at >= ? AND inv.date_at <= ?';
          whereArgs = [
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
          ];
        }
      }

      String query = '''
        SELECT 
  p.name as name,
  s.unit_sale_price as unit_price, 
  s.sale_quantity as quantity, 
  (unit_sale_price * s.sale_quantity) AS total, 
  inv.date_at as date_at
FROM sales s
JOIN invoices inv ON s.invoice_id = inv.id
JOIN products p ON s.product_id = p.id

      ''';

      if (whereClause.isNotEmpty) {
        query += ' WHERE $whereClause';
      }

      query += ' ORDER BY inv.date_at DESC, p.name';

      return await txn.rawQuery(query, whereArgs);
    });
  }

  Future<List<Map<String, dynamic>>> getExpenseReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        if (startDate == endDate) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(startDate);
          whereClause = 'date_at like ?';
          whereArgs = ['%$formattedDate%'];
        } else {
          whereClause = 'date_at >= ? AND date_at <= ?';
          whereArgs = [
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
          ];
        }
      }

      String query = '''
        SELECT reason,reason_description, spent_amount, date_at
        FROM spents
      ''';

      if (whereClause.isNotEmpty) {
        query += ' WHERE $whereClause';
      }

      query += ' ORDER BY date_at DESC';

      return await txn.rawQuery(query, whereArgs);
    });
  }

  Future<List<Map<String, dynamic>>> getDebtReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeTransaction((txn) async {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        if (startDate == endDate) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(startDate);
          whereClause = 'inv.date_at like ?';
          whereArgs = ['%$formattedDate%'];
        } else {
          whereClause = 'inv.date_at >= ? AND inv.date_at <= ?';
          whereArgs = [
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
          ];
        }
      }

      String query = '''
SELECT 
  d.names as names,
  d.email as email,
  d.phone as phone,
  d.address as address,
  d.debt_amount as debt_amount,
  d.proposed_refund_date as proposed_refund_date,
  COALESCE(SUM(pd.refund_amount), 0.0) AS total_refunded,
  (d.debt_amount - COALESCE(SUM(pd.refund_amount), 0.0)) AS rest_amount,
  inv.date_at as date_at
FROM debt d
JOIN invoices inv ON d.invoice_id = inv.id
LEFT JOIN paid_debts pd ON d.id = pd.debt_id
''';

      // Add WHERE clause before GROUP BY
      if (whereClause.isNotEmpty) {
        query += ' WHERE $whereClause';
      }

      // Add GROUP BY and ORDER BY
      query += ' GROUP BY d.id, inv.date_at';
      query += ' ORDER BY inv.date_at DESC';

      return await txn.rawQuery(query, whereArgs);
    });
  }

  Future<bool> deleteAndRecreateTables() async {
    return await executeTransaction((txn) async {
      try {
        await txn.execute("DROP TABLE IF EXISTS users");
        await txn.execute("DROP TABLE IF EXISTS products");
        await txn.execute("DROP TABLE IF EXISTS products_history");
        await txn.execute("DROP TABLE IF EXISTS invoices");
        await txn.execute("DROP TABLE IF EXISTS sales");
        await txn.execute("DROP TABLE IF EXISTS debt");
        await txn.execute("DROP TABLE IF EXISTS paid_debts");
        await txn.execute("DROP TABLE IF EXISTS spents");
        // Recreate tables
        await _onCreate(txn as Database, _databaseVersion);
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  Future<int> payDebtRecord(Map<String, dynamic> payDebtRecord) async {
    return await executeTransaction((txn) async {
      return await txn.insert(
        'paid_debts',
        payDebtRecord,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
