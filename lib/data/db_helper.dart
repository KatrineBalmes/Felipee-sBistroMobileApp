import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

/// Local SQLite persistence layer for the mobile app.
/// Table structure intentionally mirrors the original
/// `filipees_bistro.db` used by the CustomTkinter desktop version:
/// menu_items, ingredients, transactions, users.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'filipees_bistro.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        price REAL,
        stock INTEGER DEFAULT 0,
        reorder_level INTEGER DEFAULT 10,
        unit TEXT DEFAULT 'pcs',
        is_available INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT,
        on_hand REAL,
        reorder_level REAL,
        unit_cost REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_type TEXT,
        total REAL,
        payment_method TEXT,
        created_at TEXT,
        items_json TEXT
      )
    ''');
    await db.execute('''
  CREATE INDEX idx_transactions_created_at
  ON transactions(created_at)
''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT
      )
    ''');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    // Same accounts as the original desktop app.
    batch.insert('users', {
      'username': 'owner',
      'password': 'owner123',
      'role': 'owner',
      'full_name': 'Filipina S.'
    });
    batch.insert('users', {
      'username': 'cashier',
      'password': 'cashier123',
      'role': 'cashier',
      'full_name': 'Cashier 1'
    });

    const menu = [
      ['Lomi Special', 'Lomi', 85.0, 45, 10],
      ['Lomi Regular', 'Lomi', 65.0, 31, 10],
      ['Goto', 'Others', 60.0, 0, 5],
      ['Fried Rice', 'Others', 35.0, 60, 10],
      ['Iced Tea', 'Drinks', 35.0, 12, 5],
      ['Softdrinks', 'Drinks', 30.0, 24, 5],
      ['Rice', 'Others', 15.0, 60, 20],
      ['Extra Mami', 'Lomi', 40.0, 15, 5],
    ];
    for (final m in menu) {
      batch.insert('menu_items', {
        'name': m[0],
        'category': m[1],
        'price': m[2],
        'stock': m[3],
        'reorder_level': m[4],
        'unit': 'pcs',
        'is_available': 1,
      });
    }

    const ingredients = [
      ['Pork Shoulder', 'kg', 12.5, 8.0, 280.0],
      ['Egg Noodles', 'kg', 3.2, 5.0, 120.0],
      ['Bihon Noodles', 'kg', 8.0, 4.0, 100.0],
      ['Tripe (Goto)', 'kg', 0.0, 3.0, 180.0],
      ['Pork Liver', 'pcs', 24.0, 10.0, 45.0],
      ['Singkamas', 'pcs', 4.0, 6.0, 12.0],
      ['Eggs', 'pcs', 60.0, 20.0, 10.0],
      ['Garlic', 'kg', 1.2, 0.5, 90.0],
    ];
    for (final i in ingredients) {
      batch.insert('ingredients', {
        'name': i[0],
        'unit': i[1],
        'on_hand': i[2],
        'reorder_level': i[3],
        'unit_cost': i[4],
      });
    }

    // Seed 14 days of sample sales so the Dashboard / Sales Monitor /
    // AI Forecast pages have something meaningful to show immediately.
    final now = DateTime.now();
    final rnd = [36, 34, 40, 16, 39, 28, 45, 30, 22, 48, 33, 19, 41, 26];
    for (int d = 0; d < 14; d++) {
      final date = now.subtract(Duration(days: 13 - d));
      final qty = rnd[d];
      final total = qty * 85.0;
      final items = jsonEncode([
        {'name': 'Lomi Special', 'qty': qty, 'price': 85}
      ]);
      batch.insert('transactions', {
        'order_type': 'Dine-in',
        'total': total,
        'payment_method': 'Cash',
        'created_at':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 12:00:00',
        'items_json': items,
      });
    }

    await batch.commit(noResult: true);
  }

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<AppUser?> verifyLogin(String username, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'role DESC, username');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<int> addUser(AppUser u) async {
    final db = await database;
    return db.insert('users', u.toMap());
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateUserPassword(int id, String newPassword) async {
    final db = await database;
    await db.update('users', {'password': newPassword},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Menu items ────────────────────────────────────────────────────────
  Future<List<MenuItem>> getMenuItems({String? category}) async {
    final db = await database;
    final rows = (category == null || category == 'All')
        ? await db.query('menu_items', orderBy: 'category, name')
        : await db.query('menu_items',
            where: 'category = ?', whereArgs: [category], orderBy: 'name');
    return rows.map(MenuItem.fromMap).toList();
  }

  Future<int> addMenuItem(MenuItem item) async {
    final db = await database;
    return db.insert('menu_items', item.toMap());
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final db = await database;
    await db.update('menu_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteMenuItem(int id) async {
    final db = await database;
    await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deductStock(int id, int qty) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE menu_items SET stock = MAX(0, stock - ?) WHERE id = ?',
        [qty, id]);
  }

  // ── Ingredients ───────────────────────────────────────────────────────
  Future<List<Ingredient>> getIngredients() async {
    final db = await database;
    final rows = await db.query('ingredients', orderBy: 'name');
    return rows.map(Ingredient.fromMap).toList();
  }

  Future<List<String>> getLowStockIngredientNames() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT name FROM ingredients WHERE on_hand <= reorder_level');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<int> addIngredient(Ingredient ing) async {
    final db = await database;
    return db.insert('ingredients', ing.toMap());
  }

  Future<void> updateIngredient(Ingredient ing) async {
    final db = await database;
    await db.update('ingredients', ing.toMap(),
        where: 'id = ?', whereArgs: [ing.id]);
  }

  Future<void> deleteIngredient(int id) async {
    final db = await database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  // ── Transactions ──────────────────────────────────────────────────────
  Future<int> recordTransaction({
    required String orderType,
    required double total,
    required String paymentMethod,
    required List<CartItem> items,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final createdAt =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final id = await db.insert('transactions', {
      'order_type': orderType,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'items_json': jsonEncode(items
          .map((i) => {'name': i.name, 'qty': i.qty, 'price': i.price})
          .toList()),
    });

    for (final item in items) {
      await deductStock(item.menuItemId, item.qty);
    }
    return id;
  }

  Future<List<SaleTransaction>> getTransactions({int limit = 50}) async {
  final db = await database;

  final rows = await db.query(
    'transactions',
    orderBy: 'id DESC',
    limit: limit,
  );

  return rows.map((m) {
    final rawItems = jsonDecode(m['items_json'] as String) as List;

    final items = rawItems.map((e) {
      return CartItem(
        menuItemId: 0,
        name: e['name'],
        price: (e['price'] as num).toDouble(),
        qty: e['qty'],
      );
    }).toList();

    return SaleTransaction(
      id: m['id'] as int,
      orderType: m['order_type'] as String,
      total: (m['total'] as num).toDouble(),
      paymentMethod: m['payment_method'] as String,
      createdAt: m['created_at'] as String,
      items: items,
    );
  }).toList();
}

  Future<int> getTodayOrderCount() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final db = await database;
    final rows = await db.rawQuery(
        "SELECT COUNT(*) as c FROM transactions WHERE created_at LIKE ?",
        ['$todayStr%']);
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
