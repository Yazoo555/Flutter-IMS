// inventory_widgets.dart
// Reusable UI widgets shared across the Inventory feature screens.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
    final c = context.colors;
    final color = warningColor ? const Color(0xFFF59E0B) : AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Item Tile ─────────────────────────────────────────────────────────────────

class ItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const ItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isLowStock
                ? const Color(0xFFF59E0B).withOpacity(0.5)
                : c.border,
          ),
        ),
        child: Column(
          children: [
            _buildMainRow(context),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildIconBadge(context),
          const SizedBox(width: 12),
          Expanded(child: _buildItemInfo(context)),
          _buildPopupMenu(context),
        ],
      ),
    );
  }

  Widget _buildIconBadge(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.isActive
            ? c.primaryLight
            : c.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: 24,
        color: item.isActive ? AppTheme.primary : c.textHint,
      ),
    );
  }

  Widget _buildItemInfo(BuildContext context) {
    final c = context.colors;
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
                  color: item.isActive ? c.textPrimary : c.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!item.isActive) ...[
              const SizedBox(width: 6),
              _StatusBadge(label: 'Inactive', color: c.border.withOpacity(0.5), textColor: c.textHint),
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
        _buildSubtitle(context),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final c = context.colors;
    final hasSku = item.sku != null && item.sku!.isNotEmpty;

    return Row(
      children: [
        if (hasSku)
          Text('SKU: ${item.sku}',
              style: TextStyle(fontSize: 11, color: c.textHint)),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 20, color: c.textSecondary),
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'toggle') onToggleActive();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18, color: c.textSecondary),
            const SizedBox(width: 10),
            Text('Edit',
                style: TextStyle(fontSize: 14, color: c.textPrimary)),
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
              color: c.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              item.isActive ? 'Deactivate' : 'Activate',
              style: TextStyle(fontSize: 14, color: c.textPrimary),
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

  Widget _buildBottomBar(BuildContext context) {
    final c = context.colors;
    final stockValue =
        '${item.currentStock.toStringAsFixed(item.currentStock % 1 == 0 ? 0 : 1)} ${item.unit?.abbreviation ?? ''}';

    return Container(
      decoration: BoxDecoration(
        color: c.background.withOpacity(0.5),
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
            value: 'Rs. ${item.purchasePrice.toStringAsFixed(2)}',
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 10),
          StatBadge(
            label: 'Sell',
            value: 'Rs. ${item.salesPrice.toStringAsFixed(2)}',
            color: const Color(0xFF10B981),
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: c.textHint)),
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.textHint,
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: c.textHint),
            prefixText: prefix,
            prefixStyle: TextStyle(
                fontSize: 14, color: c.textSecondary),
            filled: true,
            fillColor: c.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 14, color: c.textHint)),
          style: TextStyle(
              fontSize: 14, color: c.textPrimary),
          dropdownColor: c.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
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