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
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        paid TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
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
        date Date NOT NULL,
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

  Future<int> insertPurchase(Map<String, dynamic> purchase) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    purchase['created_at'] = now; // Add created_at field

    // First check if the product already exists
    final existingProduct = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [purchase['name']],
      limit: 1,
    );

    int productId;
    int result;

    if (existingProduct.isNotEmpty) {
      // Product exists - update quantity and price according to rules
      final existing = existingProduct.first;
      productId = existing['id'] as int;
      final newQuantity =
          (existing['quantity'] as int) + (purchase['quantity'] as int);
      final newPrice = purchase['unit_price'] > existing['unit_price']
          ? purchase['unit_price']
          : existing['unit_price'];

      result = await db.update(
        'products',
        {'quantity': newQuantity, 'unit_price': newPrice, 'created_at': now},
        where: 'name = ?',
        whereArgs: [purchase['name']],
      );
    } else {
      // Product doesn't exist - insert new record
      result = await db.insert(
        'products',
        purchase,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      productId = result; // For SQLite, the insert returns the new row id
    }

    // Insert into history table regardless of whether it was an update or insert
    await db.insert('products_history', {
      'product_id': productId,
      'unit_price': purchase['unit_price'],
      'quantity': purchase['quantity'],
      'created_at': now,
    });

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
      // Filter by date range
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(price * quantity) AS total_sales FROM sales WHERE DATE(created_at) BETWEEN ? AND ?",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_sales'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date
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
      // Filter by date range
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
      // Default to today's date
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
      // Filter by date range
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      final result = await db.rawQuery(
        "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date) BETWEEN ? AND ?",
        [startDateStr, endDateStr],
      );
      return result.isNotEmpty
          ? (result.first['total_spents'] as double?) ?? 0
          : 0;
    } else {
      // Default to today's date
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final result = await db.rawQuery(
        "SELECT SUM(spent_amount) AS total_spents FROM spents WHERE DATE(date) LIKE ?",
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
      // Filter by date range
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
      // Default to today's date
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
}
