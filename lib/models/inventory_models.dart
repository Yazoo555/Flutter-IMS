import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Models ────────────────────────────────────────────────────────────────────

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

  const ItemUnit(
      {required this.id, required this.name, required this.abbreviation});

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

  bool get isLowStock =>
      lowStockAlert != null && currentStock <= lowStockAlert!;

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
            ? ItemCategory.fromJson(
                json['categories'] as Map<String, dynamic>)
            : null,
        unit: json['units'] != null
            ? ItemUnit.fromJson(json['units'] as Map<String, dynamic>)
            : null,
      );
}

class MovementType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const MovementType(this.value, this.label, this.icon, this.color);

  static const List<MovementType> types = [
    MovementType('purchase', 'Purchase', Icons.add_shopping_cart_rounded,
        Color(0xFF10B981)),
    MovementType('sale', 'Sale', Icons.point_of_sale_rounded,
        Color(0xFF6366F1)),
    MovementType('adjustment', 'Adjustment', Icons.tune_rounded,
        Color(0xFFF59E0B)),
    MovementType('return', 'Return', Icons.keyboard_return_rounded,
        Color(0xFF0EA5E9)),
    MovementType('damage', 'Damage', Icons.warning_amber_rounded,
        Color(0xFFEF4444)),
  ];
}

class StockMovementReport {
  final String id;
  final String? itemId;
  final String type;
  final double quantity;
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;
  final String? itemName;

  const StockMovementReport({
    required this.id,
    this.itemId,
    required this.type,
    required this.quantity,
    this.referenceId,
    this.notes,
    required this.createdAt,
    this.itemName,
  });

  factory StockMovementReport.fromJson(Map<String, dynamic> json) =>
      StockMovementReport(
        id: json['id'] as String,
        itemId: json['item_id'] as String?,
        type: json['movement_type'] as String,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        referenceId: (json['reference_id'] ?? json['reference']) as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        itemName: json['items'] != null
            ? json['items']['name'] as String?
            : json['item_name'] as String?,
      );
}

class DailyStockSummary {
  final DateTime date;
  final double totalPurchased;
  final double totalSold;
  final double totalReturned;
  final double totalAdjusted;
  final double openingStock;
  final double closingStock;
  final double netChange;

  const DailyStockSummary({
    required this.date,
    required this.totalPurchased,
    required this.totalSold,
    required this.totalReturned,
    required this.totalAdjusted,
    required this.openingStock,
    required this.closingStock,
    required this.netChange,
  });

  factory DailyStockSummary.fromJson(Map<String, dynamic> json) =>
      DailyStockSummary(
        date: DateTime.parse(json['movement_date'] as String),
        totalPurchased: (json['total_purchased'] as num?)?.toDouble() ?? 0,
        totalSold: (json['total_sold'] as num?)?.toDouble() ?? 0,
        totalReturned: (json['total_returned'] as num?)?.toDouble() ?? 0,
        totalAdjusted: (json['total_adjusted'] as num?)?.toDouble() ?? 0,
        openingStock: (json['opening_stock'] as num?)?.toDouble() ?? 0,
        closingStock: (json['closing_stock'] as num?)?.toDouble() ?? 0,
        netChange: (json['net_change'] as num?)?.toDouble() ?? 0,
      );
}

class MonthlyStockReport {
  final int month;
  final double totalPurchases;
  final double totalSales;
  final double totalAdjustments;

  const MonthlyStockReport({
    required this.month,
    required this.totalPurchases,
    required this.totalSales,
    required this.totalAdjustments,
  });

  factory MonthlyStockReport.fromJson(Map<String, dynamic> json) =>
      MonthlyStockReport(
        month: (json['month'] as num).toInt(),
        totalPurchases: (json['total_purchases'] as num?)?.toDouble() ?? 0,
        totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
        totalAdjustments: (json['total_adjustments'] as num?)?.toDouble() ?? 0,
      );
}