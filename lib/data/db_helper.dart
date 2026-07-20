import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Cloud Firestore persistence layer for the mobile app.
/// Collections mirror the original SQLite tables:
///   menu_items, ingredients, transactions, users
///
/// Kept as the same `DBHelper.instance` singleton with the same method
/// names as the old SQLite version, so PosPage / InventoryPage /
/// UsersPage / DashboardPage / SalesPage / ForecastPage / LandingScreen /
/// LoginScreen don't need any changes — only the `id` fields switched
/// from `int?` to `String?` (Firestore document IDs), which those screens
/// already handle transparently since they just pass `.id` straight
/// through without assuming it's an int.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _db.collection('menu_items');
  CollectionReference<Map<String, dynamic>> get _ingredients =>
      _db.collection('ingredients');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _branches =>
      _db.collection('branches');

  // Runs once per app session: seeds default accounts/menu/ingredients/
  // sample sales the first time the Firestore project is empty, mirroring
  // what `_onCreate` + `_seed` did for a brand-new SQLite file.
  Future<void>? _seedFuture;
  Future<void> _ensureSeeded() => _seedFuture ??= _seedIfEmpty();

  Future<void> _seedIfEmpty() async {
    final branchesSnap = await _branches.limit(1).get();
    if (branchesSnap.docs.isEmpty) {
      await _seedBranches();
    }
    final usersSnap = await _users.limit(1).get();
    if (usersSnap.docs.isEmpty) {
      await _seedUsers();
    }
    final menuSnap = await _menuItems.limit(1).get();
    if (menuSnap.docs.isEmpty) {
      await _seedMenuIngredientsAndSales();
    }
  }

  // Fixed, well-known doc IDs so seeded users can reference a branch
  // deterministically without needing to look up its generated ID first.
  static const _poblacionBranchId = 'B001';
  static const _sanRoqueBranchId = 'B002';

  Future<void> _seedBranches() async {
    final batch = _db.batch();
    batch.set(_branches.doc(_poblacionBranchId), {
      'name': 'Poblacion Branch',
      'location': 'Poblacion, Bauan, Batangas',
      'contact_number': '0956 544 5021',
    });
    batch.set(_branches.doc(_sanRoqueBranchId), {
      'name': 'San Roque Branch',
      'location': 'San Roque, Bauan, Batangas',
      'contact_number': '0956 544 5021',
    });
    await batch.commit();
  }

  Future<void> _seedUsers() async {
    final batch = _db.batch();
    batch.set(_users.doc(), {
      'username': 'owner',
      'password': 'owner123',
      'role': 'owner',
      'full_name': 'Filipina S.',
      'branch_id': _poblacionBranchId,
    });
    batch.set(_users.doc(), {
      'username': 'cashier',
      'password': 'cashier123',
      'role': 'cashier',
      'full_name': 'Cashier 1',
      'branch_id': _poblacionBranchId,
    });
    batch.set(_users.doc(), {
      'username': 'cashier2',
      'password': 'cashier123',
      'role': 'cashier',
      'full_name': 'Cashier 2',
      'branch_id': _sanRoqueBranchId,
    });
    await batch.commit();
  }

  Future<void> _seedMenuIngredientsAndSales() async {
    final batch = _db.batch();

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
      batch.set(_menuItems.doc(), {
        'name': m[0],
        'category': m[1],
        'price': m[2],
        'stock': m[3],
        'reorder_level': m[4],
        'unit': 'pcs',
        'is_available': true,
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
      batch.set(_ingredients.doc(), {
        'name': i[0],
        'unit': i[1],
        'on_hand': i[2],
        'reorder_level': i[3],
        'unit_cost': i[4],
      });
    }

    // Seed 14 days of sample sales so Dashboard / Sales Monitor /
    // AI Forecast have something meaningful to show immediately.
    final now = DateTime.now();
    final rnd = [36, 34, 40, 16, 39, 28, 45, 30, 22, 48, 33, 19, 41, 26];
    for (int d = 0; d < 14; d++) {
      final date = now.subtract(Duration(days: 13 - d));
      final qty = rnd[d];
      final total = qty * 85.0;
      batch.set(_transactions.doc(), {
        'order_type': 'Dine-in',
        'total': total,
        'payment_method': 'Cash',
        'created_at':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 12:00:00',
        'items': [
          {'name': 'Lomi Special', 'qty': qty, 'price': 85},
        ],
      });
    }

    await batch.commit();
  }

  // ── Branches ──────────────────────────────────────────────────────────
  Future<List<Branch>> getBranches() async {
    await _ensureSeeded();
    final snap = await _branches.get();
    final list = snap.docs.map(Branch.fromFirestore).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<AppUser?> verifyLogin(String username, String password) async {
    await _ensureSeeded();
    final snap = await _users
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromFirestore(snap.docs.first);
  }

  Future<List<AppUser>> getUsers() async {
    await _ensureSeeded();
    final snap = await _users.get();
    final list = snap.docs.map(AppUser.fromFirestore).toList();
    // role DESC, username ASC — same ordering as the old SQL query,
    // done client-side to avoid needing a composite index.
    list.sort((a, b) {
      final roleCmp = b.role.compareTo(a.role);
      return roleCmp != 0 ? roleCmp : a.username.compareTo(b.username);
    });
    return list;
  }

  Future<String> addUser(AppUser u) async {
    await _ensureSeeded();
    final existing =
        await _users.where('username', isEqualTo: u.username).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Username "${u.username}" already exists.');
    }
    final ref = await _users.add(u.toFirestore());
    return ref.id;
  }

  Future<void> deleteUser(String id) async {
    await _users.doc(id).delete();
  }

  Future<void> updateUserPassword(String id, String newPassword) async {
    await _users.doc(id).update({'password': newPassword});
  }

  // ── Menu items ────────────────────────────────────────────────────────
  Future<List<MenuItem>> getMenuItems({String? category}) async {
    await _ensureSeeded();
    Query<Map<String, dynamic>> q = _menuItems;
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    final snap = await q.get();
    final items = snap.docs.map(MenuItem.fromFirestore).toList();
    items.sort((a, b) {
      final c = a.category.compareTo(b.category);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return items;
  }

  Future<String> addMenuItem(MenuItem item) async {
    final ref = await _menuItems.add(item.toFirestore());
    return ref.id;
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _menuItems.doc(item.id).update(item.toFirestore());
  }

  Future<void> deleteMenuItem(String id) async {
    await _menuItems.doc(id).delete();
  }

  Future<void> deductStock(String id, int qty) async {
    final ref = _menuItems.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
      final updated = current - qty;
      tx.update(ref, {'stock': updated < 0 ? 0 : updated});
    });
  }

  // ── Ingredients ───────────────────────────────────────────────────────
  Future<List<Ingredient>> getIngredients() async {
    await _ensureSeeded();
    final snap = await _ingredients.get();
    final list = snap.docs.map(Ingredient.fromFirestore).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<String>> getLowStockIngredientNames() async {
    await _ensureSeeded();
    // Firestore can't compare two fields (on_hand <= reorder_level) in a
    // query, so this filters client-side — fine at this data scale.
    final snap = await _ingredients.get();
    return snap.docs
        .map(Ingredient.fromFirestore)
        .where((i) => i.onHand <= i.reorderLevel)
        .map((i) => i.name)
        .toList();
  }

  Future<String> addIngredient(Ingredient ing) async {
    final ref = await _ingredients.add(ing.toFirestore());
    return ref.id;
  }

  Future<void> updateIngredient(Ingredient ing) async {
    await _ingredients.doc(ing.id).update(ing.toFirestore());
  }

  Future<void> deleteIngredient(String id) async {
    await _ingredients.doc(id).delete();
  }

  // ── Transactions ──────────────────────────────────────────────────────
  Future<String> recordTransaction({
    required String orderType,
    required double total,
    required String paymentMethod,
    required List<CartItem> items,
  }) async {
    await _ensureSeeded();
    final now = DateTime.now();
    final createdAt =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final ref = await _transactions.add({
      'order_type': orderType,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'items': items
          .map((i) => {'name': i.name, 'qty': i.qty, 'price': i.price})
          .toList(),
    });

    for (final item in items) {
      await deductStock(item.menuItemId, item.qty);
    }
    return ref.id;
  }

  Future<List<SaleTransaction>> getTransactions({int limit = 50}) async {
    await _ensureSeeded();
    final snap = await _transactions
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(SaleTransaction.fromFirestore).toList();
  }

  Future<int> getTodayOrderCount() async {
    await _ensureSeeded();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    String ymd(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Single-field range query (both clauses on created_at), so no
    // composite index is needed.
    final snap = await _transactions
        .where('created_at', isGreaterThanOrEqualTo: '${ymd(now)} 00:00:00')
        .where('created_at', isLessThan: '${ymd(tomorrow)} 00:00:00')
        .get();
    return snap.docs.length;
  }
}