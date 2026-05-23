import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_models.dart';
import 'add_edit_item_screen.dart';
import 'stock_adjust_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback onDataChanged;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onDataChanged,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  void _openEditItem() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemScreen(item: widget.item)),
    );
    if (updated == true) {
      widget.onDataChanged();
      Navigator.pop(context, true); // Pop back to inventory to refresh
    }
  }

  void _openStockAdjust() async {
    final adjusted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StockAdjustScreen(item: widget.item)),
    );
    if (adjusted == true) {
      widget.onDataChanged();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.getTextSecondary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Item Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            onPressed: _openEditItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isLowStock
                      ? const Color(0xFFF59E0B).withOpacity(0.5)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: item.isActive 
                        ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPrimaryLighter : AppTheme.primaryLight)
                        : AppTheme.getBorder(context).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 28,
                      color: item.isActive ? AppTheme.primary : AppTheme.getTextHint(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: item.isActive ? AppTheme.getTextPrimary(context) : AppTheme.getTextHint(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (!item.isActive) ...[
                              _StatusBadge(
                                  label: 'Inactive',
                                  color: AppTheme.getBorder(context)
                                      .withOpacity(0.5),
                                  textColor: AppTheme.getTextHint(context)),
                              const SizedBox(width: 8),
                            ],
                            if (item.isLowStock)
                              _StatusBadge(
                                label: 'Low Stock',
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                textColor: const Color(0xFFF59E0B),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info Section
            _SectionTitle('Description'),
            Text(
              item.description?.isNotEmpty == true ? item.description! : 'No description provided.',
              style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Key Information'),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                children: [
                  _InfoRow('SKU', item.sku?.isNotEmpty == true ? item.sku! : 'N/A'),
                  Divider(height: 1, color: AppTheme.getBorder(context)),
                  _InfoRow('Category', item.category?.name ?? 'Uncategorized'),
                  Divider(height: 1, color: AppTheme.getBorder(context)),
                  _InfoRow('Unit', '${item.unit?.name ?? 'N/A'} (${item.unit?.abbreviation ?? ''})'),
                  if (item.expiryDate != null) ...[
                    Divider(height: 1, color: AppTheme.getBorder(context)),
                    _InfoRow('Expiry Date', _formatExpiryDate(item.expiryDate!),
                        highlight: item.isExpired || item.isExpiringSoon()),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Stock Details'),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                children: [
                  _InfoRow('Current Stock', '${item.currentStock.toStringAsFixed(item.currentStock % 1 == 0 ? 0 : 2)} ${item.unit?.abbreviation ?? ''}', highlight: true),
                  Divider(height: 1, color: AppTheme.getBorder(context)),
                  _InfoRow('Opening Stock', item.openingStock.toStringAsFixed(item.openingStock % 1 == 0 ? 0 : 2)),
                  Divider(height: 1, color: AppTheme.getBorder(context)),
                  _InfoRow('Low Stock Alert', item.lowStockAlert != null ? item.lowStockAlert!.toStringAsFixed(item.lowStockAlert! % 1 == 0 ? 0 : 2) : 'None'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Pricing Details'),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                children: [
                  _InfoRow('Purchase Price', 'Rs. ${item.purchasePrice.toStringAsFixed(2)}'),
                  Divider(height: 1, color: AppTheme.getBorder(context)),
                  _InfoRow('Sales Price', 'Rs. ${item.salesPrice.toStringAsFixed(2)}'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Adjust Stock Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openStockAdjust,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.swap_vert_rounded, color: Colors.white),
                label: const Text('Adjust Stock', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _formatExpiryDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) {
      return 'Expired ${DateFormat('MMM d, yyyy').format(date)}';
    } else if (diff == 0) {
      return 'Expires today (${DateFormat('MMM d, yyyy').format(date)})';
    } else if (diff <= 30) {
      return '${DateFormat('MMM d, yyyy').format(date)} (${diff} days)';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.getTextHint(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppTheme.primary : AppTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusBadge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
