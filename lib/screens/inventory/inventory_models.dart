// inventory_models.dart
// Data models for the Inventory feature.

class ItemCategory {
  final String id;
  final String name;

  const ItemCategory({required this.id, required this.name});

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class ItemUnit {
  final String id;
  final String name;
  final String abbreviation;

  const ItemUnit({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  factory ItemUnit.fromJson(Map<String, dynamic> json) => ItemUnit(
        id: json['id'] as String,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
      );
}

class InventoryItem {
  final String id;
  final String userId;
  final String categoryId;
  final String unitId;
  final String name;
  final String? sku;
  final String? description;
  final double openingStock;
  final double currentStock;
  final double? lowStockAlert;
  final double purchasePrice;
  final double salesPrice;
  final bool isActive;
  final DateTime createdAt;
  final ItemCategory? category;
  final ItemUnit? unit;

  const InventoryItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.unitId,
    required this.name,
    this.sku,
    this.description,
    required this.openingStock,
    required this.currentStock,
    this.lowStockAlert,
    required this.purchasePrice,
    required this.salesPrice,
    required this.isActive,
    required this.createdAt,
    this.category,
    this.unit,
  });

  bool get isLowStock => lowStockAlert != null && currentStock <= lowStockAlert!;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        categoryId: json['category_id'] as String,
        unitId: json['unit_id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String?,
        description: json['description'] as String?,
        openingStock: (json['opening_stock'] as num?)?.toDouble() ?? 0,
        currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0,
        lowStockAlert: (json['low_stock_alert'] as num?)?.toDouble(),
        purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
        salesPrice: (json['sales_price'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        category: json['categories'] != null
            ? ItemCategory.fromJson(json['categories'] as Map<String, dynamic>)
            : null,
        unit: json['units'] != null
            ? ItemUnit.fromJson(json['units'] as Map<String, dynamic>)
            : null,
      );
}