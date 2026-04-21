// po_line_item_card.dart
// Card widget for displaying a purchase order line item.

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/purchase_order.dart';

class POLineItemCard extends StatelessWidget {
  final PurchaseOrderItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const POLineItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkPrimaryLight
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.itemSku != null && item.itemSku!.isNotEmpty)
                      Text(
                        'SKU: ${item.itemSku}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                  ],
                ),
              ),
              if (showActions)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: textSecondary),
                  color: surfaceColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') onEdit?.call();
                    if (val == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: textSecondary),
                        const SizedBox(width: 10),
                        Text('Edit',
                            style: TextStyle(
                                fontSize: 14, color: textPrimary)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.errorColor)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _StatItem(
                  label: 'Ordered',
                  value: item.quantityOrdered.toStringAsFixed(
                      item.quantityOrdered % 1 == 0 ? 0 : 1),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 16),
                _StatItem(
                  label: 'Received',
                  value: item.quantityReceived.toStringAsFixed(
                      item.quantityReceived % 1 == 0 ? 0 : 1),
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 16),
                _StatItem(
                  label: 'Price',
                  value: 'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                  color: const Color(0xFF6366F1),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontSize: 10, color: textSecondary)),
                    Text(
                      'Rs. ${item.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
