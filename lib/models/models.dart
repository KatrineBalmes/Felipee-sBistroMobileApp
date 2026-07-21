/// Domain models — now backed by Cloud Firestore instead of SQLite.
/// Document IDs are Firestore's auto-generated String IDs (previously
/// SQLite's auto-increment int primary keys), so every `id` field below
/// is `String?` instead of `int?`. Nothing else about the shapes changed,
/// so screens that only ever pass `item.id` through to DBHelper calls
/// keep working without edits.
library models;

import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String? id;
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
    String? id,
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

  /// Firestore document fields (the doc ID itself is stored separately,
  /// so `id` is intentionally excluded here).
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'reorder_level': reorderLevel,
        'unit': unit,
        'is_available': isAvailable,
        'branchName': name,
      };

  factory MenuItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return MenuItem(
      id: doc.id,
      name: m['name'] as String,
      category: m['category'] as String,
      price: (m['price'] as num).toDouble(),
      stock: (m['stock'] as num).toInt(),
      reorderLevel: (m['reorder_level'] as num?)?.toInt() ?? 10,
      unit: m['unit'] as String? ?? 'pcs',
      isAvailable: m['is_available'] as bool? ?? true,
    );
  }

  String get status {
    if (stock <= 0) return 'Out';
    if (stock <= reorderLevel) return 'Low';
    return 'OK';
  }
}

class Ingredient {
  final String? id;
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
    String? id,
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

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'unit': unit,
        'on_hand': onHand,
        'reorder_level': reorderLevel,
        'unit_cost': unitCost,
      };

  factory Ingredient.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Ingredient(
      id: doc.id,
      name: m['name'] as String,
      unit: m['unit'] as String,
      onHand: (m['on_hand'] as num).toDouble(),
      reorderLevel: (m['reorder_level'] as num).toDouble(),
      unitCost: (m['unit_cost'] as num).toDouble(),
    );
  }

  String get status {
    if (onHand <= 0) return 'Out';
    if (onHand <= reorderLevel) return 'Low';
    return 'Good';
  }
}

class CartItem {
  final String menuItemId;
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
  final String? id;
  final String orderType;
  final double total;
  final String paymentMethod;
  final String createdAt; // 'yyyy-MM-dd HH:mm:ss', zero-padded so string
  // ordering/range queries on this field match chronological order.
  final List<CartItem> items;

  const SaleTransaction({
    this.id,
    required this.orderType,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toFirestore() => {
        'order_type': orderType,
        'total': total,
        'payment_method': paymentMethod,
        'created_at': createdAt,
        'items': items
            .map((i) => {'name': i.name, 'qty': i.qty, 'price': i.price})
            .toList(),
      };

  factory SaleTransaction.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    final rawItems = (m['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return CartItem(
        // The original menu item id isn't needed once a sale is recorded
        // (Dashboard/Sales/Forecast only read name/qty/price), so this
        // mirrors the placeholder the old SQLite version used.
        menuItemId: '',
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        qty: (map['qty'] as num).toInt(),
      );
    }).toList();

    return SaleTransaction(
      id: doc.id,
      orderType: m['order_type'] as String,
      total: (m['total'] as num).toDouble(),
      paymentMethod: m['payment_method'] as String,
      createdAt: m['created_at'] as String,
      items: items,
    );
  }
}

class AppUser {
  final String? id;
  final String username;
  final String password;
  final String role;
  final String fullName;
  final String? branchId;

  const AppUser({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    this.branchId,
  });

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'password': password,
        'role': role,
        'full_name': fullName,
        'branchId': branchId,
      };

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      username: m['username'] as String,
      password: m['password'] as String,
      role: m['role'] as String,
      fullName: m['full_name'] as String,
      branchId: m['branchId'] as String?,
    );
  }
}

/// A physical branch/outlet (mirrors the `branches` Firestore collection
/// in the ERD: branchId, branchName, location, contactNumber).
class Branch {
  final String? id;
  final String name;
  final String location;
  final String contactNumber;

  const Branch({
    this.id,
    required this.name,
    required this.location,
    required this.contactNumber,
  });

  Map<String, dynamic> toFirestore() => {
        'branchName': name,
        'location': location,
        'contactNumber': contactNumber,
      };

  factory Branch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Branch(
      id: doc.id,
      name: m['branchName'] as String? ?? '',
      location: m['location'] as String? ?? '',
      contactNumber: m['contactNumber']?.toString() ?? '',
    );
  }
}