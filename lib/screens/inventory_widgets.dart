// inventory_widgets.dart
// Reusable UI widgets shared across the Inventory feature screens.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'inventory_models.dart';

// ── Filter Chip ───────────────────────────────────────────────────────────────

class InventoryFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final bool warningColor;

  const InventoryFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.warningColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warningColor ? const Color(0xFFF59E0B) : AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Item Tile ─────────────────────────────────────────────────────────────────

class ItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdjustStock;
  final VoidCallback onToggleActive;

  const ItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustStock,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isLowStock
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          _buildMainRow(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMainRow() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildIconBadge(),
          const SizedBox(width: 12),
          Expanded(child: _buildItemInfo()),
          _buildPopupMenu(),
        ],
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.isActive
            ? AppTheme.primaryLight
            : AppTheme.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: 24,
        color: item.isActive ? AppTheme.primary : AppTheme.textHint,
      ),
    );
  }

  Widget _buildItemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: item.isActive ? AppTheme.textPrimary : AppTheme.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!item.isActive) ...[
              const SizedBox(width: 6),
              _StatusBadge(label: 'Inactive', color: AppTheme.border.withOpacity(0.5), textColor: AppTheme.textHint),
            ],
            if (item.isLowStock) ...[
              const SizedBox(width: 6),
              _StatusBadge(
                label: 'Low Stock',
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                textColor: const Color(0xFFF59E0B),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        _buildSubtitle(),
      ],
    );
  }

  Widget _buildSubtitle() {
    final hasSku = item.sku != null && item.sku!.isNotEmpty;
    final hasCategory = item.category != null;

    return Row(
      children: [
        if (hasSku)
          Text('SKU: ${item.sku}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        if (hasSku && hasCategory)
          const Text(' · ',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
        if (hasCategory)
          Text(item.category!.name,
              style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppTheme.textSecondary),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'toggle') onToggleActive();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
            SizedBox(width: 10),
            Text('Edit',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(children: [
            Icon(
              item.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              item.isActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                size: 18, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            Text('Delete',
                style: TextStyle(fontSize: 14, color: AppTheme.errorColor)),
          ]),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final stockValue =
        '${item.currentStock.toStringAsFixed(item.currentStock % 1 == 0 ? 0 : 1)} ${item.unit?.abbreviation ?? ''}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          StatBadge(
            label: 'Stock',
            value: stockValue,
            color: item.isLowStock
                ? const Color(0xFFF59E0B)
                : AppTheme.primary,
          ),
          const SizedBox(width: 10),
          StatBadge(
            label: 'Buy',
            value: '₹${item.purchasePrice.toStringAsFixed(2)}',
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 10),
          StatBadge(
            label: 'Sell',
            value: '₹${item.salesPrice.toStringAsFixed(2)}',
            color: const Color(0xFF10B981),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdjustStock,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 14, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text('Adjust',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────

class StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatBadge({
    super.key,
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

// ── Section Label ─────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────

class FormFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? prefix;

  const FormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 14, color: AppTheme.textHint),
            prefixText: prefix,
            prefixStyle: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dropdown Field ────────────────────────────────────────────────────────────

class DropdownFieldWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  const DropdownFieldWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(hint,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textHint)),
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textPrimary),
          dropdownColor: AppTheme.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}