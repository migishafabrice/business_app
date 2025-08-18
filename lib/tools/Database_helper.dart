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
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE paid_debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        refund_amount REAL NOT NULL,
        mode TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    user['created_at'] = now; // Add created_at field
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertPurchase(List<Map<String, dynamic>> purchases) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    int result = 0;

    for (final purchase in purchases) {
      final updatedPurchase = {
        ...purchase,
        'created_at': now, // Add created_at field
      };

      final existingProduct = await db.query(
        'products',
        where: 'name = ?',
        whereArgs: [updatedPurchase['name']],
        limit: 1,
      );

      int productId;

      if (existingProduct.isNotEmpty) {
        // Product exists - update quantity and price according to rules
        final existing = existingProduct.first;
        productId = existing['id'] as int;
        final newQuantity =
            (existing['quantity'] as int) + (updatedPurchase['quantity'])
                as int;
        final newPrice = updatedPurchase['unit_price'] > existing['unit_price']
            ? updatedPurchase['unit_price']
            : existing['unit_price'];

        result = await db.update(
          'products',
          {'quantity': newQuantity, 'unit_price': newPrice, 'created_at': now},
          where: 'id = ?',
          whereArgs: [productId],
        );
      } else {
        // Product doesn't exist - insert new record
        final date = updatedPurchase['date_at'];
        updatedPurchase.remove('date_at'); // Remove date_at from purchase data
        productId = await db.insert(
          'products',
          updatedPurchase,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        updatedPurchase['date_at'] = date;
        result = productId; // For SQLite, the insert returns the new row id
      }

      // Insert into history table regardless of whether it was an update or insert
      await db.insert('products_history', {
        'product_id': productId,
        'unit_price': updatedPurchase['unit_price'],
        'quantity': updatedPurchase['quantity'],
        'date_at': updatedPurchase['date_at'],
        'created_at': now,
      });
    }

    return result;
  }

  Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    invoice['created_at'] = now; // Add created_at field
    final int resultInsertInvoiceId = await db.insert(
      'invoices',
      invoice,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return resultInsertInvoiceId;
  }

  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final invoiceId = await insertInvoice({
      'mode': sale['mode'],
      'paid': sale['paid'],
    });
    sale['created_at'] = now;
    sale['invoice_id'] = invoiceId;
    sale['created_at'] = now; // Add created_at field
    return await db.insert(
      'sales',
      sale,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // New method to insert sale record with proper structure
  Future<int> insertSaleRecord(Map<String, dynamic> saleRecord) async {
    final db = await database;
    return await db.insert(
      'sales',
      saleRecord,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // New method to update product quantity
  Future<int> updateProductQuantity(int productId, int newQuantity) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'products',
      {'quantity': newQuantity, 'created_at': now},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Method to insert spent records
  Future<int> insertSpent(Map<String, dynamic> spentData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    spentData['created_at'] = now;
    return await db.insert(
      'spents',
      spentData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to insert debt records
  Future<int> insertDebt(Map<String, dynamic> debtData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    debtData['created_at'] = now;
    return await db.insert(
      'debt',
      debtData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to execute database operations in a transaction
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction) action,
  ) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Method to insert invoice with existing database connection
  Future<int> insertInvoiceWithDb(
    Transaction db,
    Map<String, dynamic> invoice,
  ) async {
    final now = DateTime.now().toIso8601String();
    invoice['created_at'] = now;
    return await db.insert(
      'invoices',
      invoice,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to insert sale record with existing database connection
  Future<int> insertSaleRecordWithDb(
    Transaction db,
    Map<String, dynamic> saleRecord,
  ) async {
    return await db.insert(
      'sales',
      saleRecord,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to update product quantity with existing database connection
  Future<int> updateProductQuantityWithDb(
    Transaction db,
    int productId,
    int newQuantity,
  ) async {
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'products',
      {'quantity': newQuantity, 'created_at': now},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Method to insert debt with existing database connection
  Future<int> insertDebtWithDb(
    Transaction db,
    Map<String, dynamic> debtData,
  ) async {
    final now = DateTime.now().toIso8601String();
    debtData['created_at'] = now;
    return await db.insert(
      'debt',
      debtData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to insert purchase with existing database connection
  Future<int> insertPurchaseWithDb(
    Transaction db,
    Map<String, dynamic> purchaseData,
  ) async {
    final now = DateTime.now().toIso8601String();
    purchaseData['created_at'] = now;
    return await db.insert(
      'products',
      purchaseData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Method to insert spent with existing database connection
  Future<int> insertSpentWithDb(
    Transaction db,
    Map<String, dynamic> spentData,
  ) async {
    final now = DateTime.now().toIso8601String();
    spentData['created_at'] = now;
    return await db.insert(
      'spents',
      spentData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasAnyuser() async {
    final db = await database;
    final result = await db.rawQuery("select count(*) as count from users");
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<bool> authenticateUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isEmpty ? false : true;
  }

  Future<List<Map<String, dynamic>>> loadItems() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('products');
    return result;
  }

  Future<double> getSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (startDate != null && endDate != null) {
      // Filter by date_at range

      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(s.unit_sale_price * s.sale_quantity) AS total_sales,"
        "s.invoice_id,i.date_at,i.id FROM sales s JOIN  invoices i ON s.invoice_id = i.id "
        "WHERE DATE(i.date_at) BETWEEN ? AND ? GROUP BY s.invoice_id, i.date_at, i.id",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_sales'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date_at
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final result = await db.rawQuery(
        "SELECT SUM(price * quantity) AS total_sales FROM sales WHERE created_at LIKE ?",
        ['%$formattedDate%'],
      );
      return result.isNotEmpty
          ? (result.first['total_sales'] as double?) ?? 0
          : 0;
    }
  }

  Future<double> getPurchasesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (startDate != null && endDate != null) {
      // Filter by date_at range
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(unit_price * quantity) AS total_purchases FROM products_history WHERE DATE(created_at) BETWEEN ? AND ?",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_purchases'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date_at
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final result = await db.rawQuery(
        "SELECT SUM(unit_price * quantity) AS total_purchases FROM products_history WHERE created_at LIKE ?",
        ['%$formattedDate%'],
      );
      return result.isNotEmpty
          ? (result.first['total_purchases'] as double?) ?? 0
          : 0;
    }
  }

  Future<double> getSpentsAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (startDate != null && endDate != null) {
      // Filter by date_at range
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date_at) BETWEEN ? AND ?",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_spents'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date_at
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final result = await db.rawQuery(
        "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date_at) LIKE ?",
        ['%$formattedDate%'],
      );
      return result.isNotEmpty
          ? (result.first['total_spents'] as double?) ?? 0
          : 0;
    }
  }

  Future<double> getDebtsAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (startDate != null && endDate != null) {
      // Filter by date_at range
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(debt_amount) AS total_debts FROM debt WHERE DATE(created_at) BETWEEN ? AND ?",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_debts'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date_at
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final result = await db.rawQuery(
        "SELECT SUM(debt_amount) AS total_debts FROM debt WHERE created_at LIKE ?",
        ['%$formattedDate%'],
      );
      return result.isNotEmpty
          ? (result.first['total_debts'] as double?) ?? 0
          : 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllDebts() async {
    final List<Map<String, dynamic>> result = [];
    final db = await database;
    final getDebtInfo = await db.rawQuery("SELECT * FROM debt");
    if (getDebtInfo.isNotEmpty) {
      print("Fetched debts from DB: $getDebtInfo");
      for (var debt in getDebtInfo) {
        final debtId = debt['id'] as int;
        final paidDebts = await db.rawQuery(
          "SELECT sum(refund_amount) as total_refunded FROM paid_debts WHERE debt_id = ?",
          [debtId],
        );
        double totalRefunded = paidDebts.isNotEmpty
            ? (paidDebts.first['total_refunded'] as double?) ?? 0
            : 0;
        double debtAmount = debt['debt_amount'] as double? ?? 0;
        if (paidDebts.isEmpty || totalRefunded < debtAmount) {
          final getSalesInfo = await db.rawQuery(
            "SELECT * FROM sales join "
            "products on sales.product_id = products.id WHERE sales.invoice_id = ?",
            [debt['invoice_id']],
          );
          if (getSalesInfo.isNotEmpty) {
            result.add({'salesProducts': getSalesInfo});
          }
          result.add({
            'names': debt['names'],
            'email': debt['email'],
            'phone': debt['phone'],
            'address': debt['address'],
            'debt_amount': debt['debt_amount'],
            'proposed_refund_date': debt['proposed_refund_date'],
            'total_refunded': paidDebts.first['total_refunded'] ?? 0,
            'rest_amount': debtAmount - totalRefunded,
          });
        }
      }
    }
    return result;
  }

  Future<bool> deletAndecreateTables() async {
    final db = await database;
    try {
      await db.execute("DROP TABLE IF EXISTS users");
      await db.execute("DROP TABLE IF EXISTS products");
      await db.execute("DROP TABLE IF EXISTS products_history");
      await db.execute("DROP TABLE IF EXISTS invoices");
      await db.execute("DROP TABLE IF EXISTS sales");
      await db.execute("DROP TABLE IF EXISTS debt");
      await db.execute("DROP TABLE IF EXISTS paid_debts");
      await db.execute("DROP TABLE IF EXISTS spents");
      // Recreate tables
      await _onCreate(db, _databaseVersion);
      return true;
    } catch (e) {
      print("Error recreating tables: $e");
      return false;
    }
  }
}
