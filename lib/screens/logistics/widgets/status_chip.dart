// status_chip.dart
// Reusable color-coded status chip for PO and Shipment statuses.

import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final StatusChipType type;

  const StatusChip({
    super.key,
    required this.status,
    this.type = StatusChipType.purchaseOrder,
  });

  @override
  Widget build(BuildContext context) {
    final config = type == StatusChipType.purchaseOrder
        ? _poStatusConfig(status)
        : _shipmentStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.color,
        ),
      ),
    );
  }

  static _StatusConfig _poStatusConfig(String status) {
    switch (status) {
      case 'draft':
        return _StatusConfig('Draft', const Color(0xFF9CA3AF));
      case 'confirmed':
        return _StatusConfig('Confirmed', const Color(0xFF3B82F6));
      case 'partially_received':
        return _StatusConfig('Partial', const Color(0xFFF59E0B));
      case 'received':
        return _StatusConfig('Received', const Color(0xFF10B981));
      case 'cancelled':
        return _StatusConfig('Cancelled', const Color(0xFFEF4444));
      default:
        return _StatusConfig(status, const Color(0xFF9CA3AF));
    }
  }

  static _StatusConfig _shipmentStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return _StatusConfig('Pending', const Color(0xFF9CA3AF));
      case 'in_transit':
        return _StatusConfig('In Transit', const Color(0xFF3B82F6));
      case 'delivered':
        return _StatusConfig('Delivered', const Color(0xFF10B981));
      case 'failed':
        return _StatusConfig('Failed', const Color(0xFFEF4444));
      default:
        return _StatusConfig(status, const Color(0xFF9CA3AF));
    }
  }
}

enum StatusChipType { purchaseOrder, shipment }

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig(this.label, this.color);
}
