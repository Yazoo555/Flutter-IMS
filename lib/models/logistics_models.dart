// logistics_models.dart
// Data models for the Logistics feature — Suppliers and Tasks.

class Supplier {
  final String id;
  final String userId;
  final String name;
  final String? contactName;
  final String phone;
  final String email;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.userId,
    required this.name,
    this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String? ?? '',
        contactName: json['contact_name'] as String?,
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toCreateJson(String userId) => {
        'user_id': userId,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class LogisticsTask {
  final String id;
  final String userId;
  final String supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final String title;
  final String? description;
  final String status; // pending, in_progress, completed, cancelled
  final DateTime? scheduledDate;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> items;

  const LogisticsTask({
    required this.id,
    required this.userId,
    required this.supplierId,
    this.supplierName,
    this.supplierPhone,
    required this.title,
    this.description,
    required this.status,
    this.scheduledDate,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory LogisticsTask.fromJson(Map<String, dynamic> json) => LogisticsTask(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        supplierId: json['supplier_id'] as String,
        supplierName: json['supplier_name'] as String?,
        supplierPhone: json['supplier_phone'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'pending',
        scheduledDate: json['scheduled_date'] != null
            ? DateTime.tryParse(json['scheduled_date'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        items: json['items'] != null
            ? List<Map<String, dynamic>>.from(json['items'] as List)
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'supplier_phone': supplierPhone,
        'title': title,
        'description': description,
        'status': status,
        'scheduled_date': scheduledDate?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'items': items,
      };

  /// Status display label
  String get statusLabel => switch (status) {
        'pending' => 'Pending',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => status,
      };
}
