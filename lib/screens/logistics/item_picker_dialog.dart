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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

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
                  fillColor: isDark ? AppTheme.darkInputBackground : AppTheme.inputBackground,
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
                                          color: isExcluded ? Colors.grey : textPrimary,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      'SKU: ${item['sku'] ?? 'N/A'} • Stock: ${item['current_stock']}',
                                      style: const TextStyle(fontSize: 12)),
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
                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
