import 'package:flutter/material.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'unit_id': unitId,
        'name': name,
        'sku': sku,
        'description': description,
        'opening_stock': openingStock,
        'current_stock': currentStock,
        'low_stock_alert': lowStockAlert,
        'purchase_price': purchasePrice,
        'sales_price': salesPrice,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'categories': category != null
            ? {'id': category!.id, 'name': category!.name}
            : null,
        'units': unit != null
            ? {
                'id': unit!.id,
                'name': unit!.name,
                'abbreviation': unit!.abbreviation
              }
            : null,
      };

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

class RecentMovement {
  final DateTime createdAt;
  final String itemName;
  final String movementType;
  final double quantity;
  final double purchasePrice;
  final double salesPrice;
  final double transactionValue;
  final String? reference;
  final String? notes;

  const RecentMovement({
    required this.createdAt,
    required this.itemName,
    required this.movementType,
    required this.quantity,
    required this.purchasePrice,
    required this.salesPrice,
    required this.transactionValue,
    this.reference,
    this.notes,
  });

  factory RecentMovement.fromJson(Map<String, dynamic> json) => RecentMovement(
        createdAt: DateTime.parse(json['created_at'] as String),
        itemName: json['item_name'] as String? ?? 'Unknown Item',
        movementType: json['movement_type'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
        salesPrice: (json['sales_price'] as num?)?.toDouble() ?? 0,
        transactionValue: (json['transaction_value'] as num?)?.toDouble() ?? 0,
        reference: json['reference'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'item_name': itemName,
        'movement_type': movementType,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'sales_price': salesPrice,
        'transaction_value': transactionValue,
        'reference': reference,
        'notes': notes,
      };
}

// Legacy model kept for item_movements_report_screen (uses old stock_movements RPC)
class StockMovementReport {
  final String? itemId;
  final String type;
  final double quantity;
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;
  final String? itemName;

  const StockMovementReport({
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
        itemId: json['item_id'] as String?,
        type: (json['movement_type'] ?? json['type']) as String,
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
  final double totalPurchasedQty;
  final double totalSoldQty;
  final double purchaseValue;
  final double salesValue;
  final double grossProfit;
  final double closingStockQty;
  final double closingStockValue;

  const DailyStockSummary({
    required this.date,
    required this.totalPurchasedQty,
    required this.totalSoldQty,
    required this.purchaseValue,
    required this.salesValue,
    required this.grossProfit,
    required this.closingStockQty,
    required this.closingStockValue,
  });

  factory DailyStockSummary.fromJson(Map<String, dynamic> json) =>
      DailyStockSummary(
        date: DateTime.parse(json['movement_date'] as String),
        totalPurchasedQty:
            (json['total_purchased_qty'] as num?)?.toDouble() ?? 0,
        totalSoldQty: (json['total_sold_qty'] as num?)?.toDouble() ?? 0,
        purchaseValue: (json['purchase_value'] as num?)?.toDouble() ?? 0,
        salesValue: (json['sales_value'] as num?)?.toDouble() ?? 0,
        grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0,
        closingStockQty: (json['closing_stock_qty'] as num?)?.toDouble() ?? 0,
        closingStockValue:
            (json['closing_stock_value'] as num?)?.toDouble() ?? 0,
      );
}

class MonthlyStockReport {
  final int month;
  final String monthName;
  final double totalPurchasesQty;
  final double totalSalesQty;
  final double totalPurchaseValue;
  final double totalSalesValue;
  final double grossProfit;
  final double grossMarginPercentage;
  final int totalItemsSold;

  const MonthlyStockReport({
    required this.month,
    required this.monthName,
    required this.totalPurchasesQty,
    required this.totalSalesQty,
    required this.totalPurchaseValue,
    required this.totalSalesValue,
    required this.grossProfit,
    required this.grossMarginPercentage,
    required this.totalItemsSold,
  });

  Map<String, dynamic> toJson() => {
        'month': month,
        'month_name': monthName,
        'total_purchases_qty': totalPurchasesQty,
        'total_sales_qty': totalSalesQty,
        'total_purchase_value': totalPurchaseValue,
        'total_sales_value': totalSalesValue,
        'gross_profit': grossProfit,
        'gross_margin_percentage': grossMarginPercentage,
        'total_items_sold': totalItemsSold,
      };

  factory MonthlyStockReport.fromJson(Map<String, dynamic> json) =>
      MonthlyStockReport(
        month: (json['month'] as num).toInt(),
        monthName: (json['month_name'] as String?)?.trim() ?? '',
        totalPurchasesQty:
            (json['total_purchases_qty'] as num?)?.toDouble() ?? 0,
        totalSalesQty: (json['total_sales_qty'] as num?)?.toDouble() ?? 0,
        totalPurchaseValue:
            (json['total_purchase_value'] as num?)?.toDouble() ?? 0,
        totalSalesValue: (json['total_sales_value'] as num?)?.toDouble() ?? 0,
        grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0,
        grossMarginPercentage:
            (json['gross_margin_percentage'] as num?)?.toDouble() ?? 0,
        totalItemsSold: (json['total_items_sold'] as num?)?.toInt() ?? 0,
      );
}