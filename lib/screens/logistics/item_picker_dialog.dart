// item_picker_dialog.dart
// A dialog to search and select inventory items for a logistics task.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/logistics_service.dart';

class ItemPickerDialog extends StatefulWidget {
  final Set<String> excludedIds;

  const ItemPickerDialog({super.key, this.excludedIds = const {}});

  @override
  State<ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<ItemPickerDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search if needed, for now just fetch
    _fetchItems(search: _searchController.text);
  }

  Future<void> _fetchItems({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final items = await LogisticsService.getAvailableItems(search: search);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load items.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final borderColor = AppTheme.getBorder(context);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Select Items',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppTheme.getInputBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _items.isEmpty
                          ? const Center(child: Text('No items found.'))
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final id = item['id'] as String;
                                final isExcluded = widget.excludedIds.contains(id);
                                final isSelected = _selectedIds.contains(id);

                                return CheckboxListTile(
                                  value: isSelected || isExcluded,
                                  onChanged: isExcluded
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.add(id);
                                            } else {
                                              _selectedIds.remove(id);
                                            }
                                          });
                                        },
                                  title: Text(item['name'] ?? '',
                                      style: TextStyle(
                                          color: isExcluded ? AppTheme.getTextHint(context) : textPrimary,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SKU: ${item['sku'] ?? 'N/A'} • Stock: ${item['current_stock']}',
                                        style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                                      ),
                                      if (item['expiry_date'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: _ExpirySubtitle(expiryDateStr: item['expiry_date'] as String),
                                        ),
                                    ],
                                  ),
                                  activeColor: AppTheme.primary,
                                );
                              },
                            ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${_selectedIds.length} selected',
                      style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            final selectedItems = _items
                                .where((i) => _selectedIds.contains(i['id']))
                                .toList();
                            Navigator.pop(context, selectedItems);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add Selected', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays expiry status for an item in the picker list.
class _ExpirySubtitle extends StatelessWidget {
  final String expiryDateStr;
  const _ExpirySubtitle({required this.expiryDateStr});

  @override
  Widget build(BuildContext context) {
    final expiryDate = DateTime.tryParse(expiryDateStr);
    if (expiryDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    String label;
    Color color;

    if (diff < 0) {
      label = 'Expired ${-diff}d ago';
      color = const Color(0xFFEF4444);
    } else if (diff == 0) {
      label = 'Expires today';
      color = const Color(0xFFF97316);
    } else if (diff <= 30) {
      label = 'Expires in ${diff}d';
      color = const Color(0xFFF97316);
    } else {
      label = 'Exp: ${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
      color = AppTheme.getTextHint(context);
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
