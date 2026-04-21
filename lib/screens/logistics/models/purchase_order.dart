// purchase_order.dart
// Models for purchase_orders and purchase_order_items tables.

class PurchaseOrder {
  final String id;
  final String userId;
  final String supplierId;
  final String poNumber;
  final String status;
  final String? orderDate;
  final String? expectedDate;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined supplier info
  final Map<String, dynamic>? suppliers;

  // Joined line items
  final List<PurchaseOrderItem>? items;

  const PurchaseOrder({
    required this.id,
    required this.userId,
    required this.supplierId,
    required this.poNumber,
    required this.status,
    this.orderDate,
    this.expectedDate,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.suppliers,
    this.items,
  });

  String get supplierName => suppliers?['name'] as String? ?? 'Unknown';
  String? get supplierPhone => suppliers?['phone'] as String?;
  String? get supplierContact => suppliers?['contact_name'] as String?;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        supplierId: json['supplier_id'] as String? ?? '',
        poNumber: json['po_number'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        orderDate: json['order_date'] as String?,
        expectedDate: json['expected_date'] as String?,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        suppliers: json['suppliers'] as Map<String, dynamic>?,
        items: json['purchase_order_items'] != null
            ? (json['purchase_order_items'] as List)
                .map((e) =>
                    PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String itemId;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitPrice;
  final DateTime createdAt;

  // Joined item info
  final Map<String, dynamic>? items;

  const PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.itemId,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitPrice,
    required this.createdAt,
    this.items,
  });

  String get itemName => items?['name'] as String? ?? 'Unknown Item';
  String? get itemSku => items?['sku'] as String?;
  double get currentStock => (items?['current_stock'] as num?)?.toDouble() ?? 0;
  String get unitAbbreviation {
    final units = items?['units'] as Map<String, dynamic>?;
    return units?['abbreviation'] as String? ?? '';
  }

  double get lineTotal => quantityOrdered * unitPrice;
  double get remainingQty => quantityOrdered - quantityReceived;

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderItem(
        id: json['id'] as String,
        purchaseOrderId: json['purchase_order_id'] as String? ?? '',
        itemId: json['item_id'] as String? ?? '',
        quantityOrdered:
            (json['quantity_ordered'] as num?)?.toDouble() ?? 0,
        quantityReceived:
            (json['quantity_received'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        items: json['items'] as Map<String, dynamic>?,
      );
}
