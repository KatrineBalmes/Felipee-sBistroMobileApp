/// Domain models — mirror the original SQLite schema used by the
/// CustomTkinter desktop app (menu_items, ingredients, transactions, users)
/// so the Flutter rebuild is a drop-in replacement.
library models;

class MenuItem {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final int reorderLevel;
  final String unit;
  final bool isAvailable;

  const MenuItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.reorderLevel = 10,
    this.unit = 'pcs',
    this.isAvailable = true,
  });

  MenuItem copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    int? reorderLevel,
    String? unit,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'reorder_level': reorderLevel,
        'unit': unit,
        'is_available': isAvailable ? 1 : 0,
      };

  factory MenuItem.fromMap(Map<String, dynamic> m) => MenuItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        price: (m['price'] as num).toDouble(),
        stock: m['stock'] as int,
        reorderLevel: m['reorder_level'] as int,
        unit: m['unit'] as String,
        isAvailable: (m['is_available'] as int) == 1,
      );

  String get status {
    if (stock <= 0) return 'Out';
    if (stock <= reorderLevel) return 'Low';
    return 'OK';
  }
}

class Ingredient {
  final int? id;
  final String name;
  final String unit;
  final double onHand;
  final double reorderLevel;
  final double unitCost;

  const Ingredient({
    this.id,
    required this.name,
    required this.unit,
    required this.onHand,
    required this.reorderLevel,
    required this.unitCost,
  });

  Ingredient copyWith({
    int? id,
    String? name,
    String? unit,
    double? onHand,
    double? reorderLevel,
    double? unitCost,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      onHand: onHand ?? this.onHand,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'unit': unit,
        'on_hand': onHand,
        'reorder_level': reorderLevel,
        'unit_cost': unitCost,
      };

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        id: m['id'] as int?,
        name: m['name'] as String,
        unit: m['unit'] as String,
        onHand: (m['on_hand'] as num).toDouble(),
        reorderLevel: (m['reorder_level'] as num).toDouble(),
        unitCost: (m['unit_cost'] as num).toDouble(),
      );

  String get status {
    if (onHand <= 0) return 'Out';
    if (onHand <= reorderLevel) return 'Low';
    return 'Good';
  }
}

class CartItem {
  final int menuItemId;
  final String name;
  final double price;
  int qty;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get subtotal => price * qty;
}

class SaleTransaction {
  final int? id;
  final String orderType;
  final double total;
  final String paymentMethod;
  final String createdAt; // ISO-ish string, same format as original app
  final List<CartItem> items;

  const SaleTransaction({
    this.id,
    required this.orderType,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });
}

class AppUser {
  final int? id;
  final String username;
  final String password;
  final String role; // 'owner' | 'cashier'
  final String fullName;

  const AppUser({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password': password,
        'role': role,
        'full_name': fullName,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        username: m['username'] as String,
        password: m['password'] as String,
        role: m['role'] as String,
        fullName: m['full_name'] as String,
      );
}
