// shipment.dart
// Model for the shipments table.

class Shipment {
  final String id;
  final String userId;
  final String? purchaseOrderId;
  final String status;
  final String? carrier;
  final String? trackingNumber;
  final String? shippedDate;
  final String? estimatedArrival;
  final String? actualArrival;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined PO + supplier info
  final Map<String, dynamic>? purchaseOrders;

  const Shipment({
    required this.id,
    required this.userId,
    this.purchaseOrderId,
    required this.status,
    this.carrier,
    this.trackingNumber,
    this.shippedDate,
    this.estimatedArrival,
    this.actualArrival,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.purchaseOrders,
  });

  String get poNumber =>
      purchaseOrders?['po_number'] as String? ?? 'N/A';
  String? get expectedDate =>
      purchaseOrders?['expected_date'] as String?;
  String get supplierName {
    final suppliers =
        purchaseOrders?['suppliers'] as Map<String, dynamic>?;
    return suppliers?['name'] as String? ?? 'Unknown';
  }

  String? get supplierPhone {
    final suppliers =
        purchaseOrders?['suppliers'] as Map<String, dynamic>?;
    return suppliers?['phone'] as String?;
  }

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        purchaseOrderId: json['purchase_order_id'] as String?,
        status: json['status'] as String? ?? 'pending',
        carrier: json['carrier'] as String?,
        trackingNumber: json['tracking_number'] as String?,
        shippedDate: json['shipped_date'] as String?,
        estimatedArrival: json['estimated_arrival'] as String?,
        actualArrival: json['actual_arrival'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        purchaseOrders:
            json['purchase_orders'] as Map<String, dynamic>?,
      );
}
