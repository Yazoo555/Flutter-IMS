// inventory_screen.dart
// The main Inventory listing screen with search, filters, and item management.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'inventory_models.dart';
import 'inventory_widgets.dart';
import 'add_edit_item_screen.dart';
// import 'stock_adjust_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> _items = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _filterStatus = 'all'; // all | active | inactive | low_stock

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('items')
          .select('*,categories(*),units(*)')
          .order('name', ascending: true);

      if (!mounted) return;
      final items = (data as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _items = items;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load items. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesSearch = query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            (item.sku?.toLowerCase().contains(query) ?? false) ||
            (item.description?.toLowerCase().contains(query) ?? false);

        final matchesStatus = switch (_filterStatus) {
          'active' => item.isActive,
          'inactive' => !item.isActive,
          'low_stock' => item.isLowStock && item.isActive,
          _ => true,
        };

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final confirmed = await _showDeleteDialog(item.name);
    if (!confirmed) return;

    try {
      await supabase.from('items').delete().eq('id', item.id);
      if (!mounted) return;
      _showSnack('${item.name} deleted.');
      _fetchItems();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.code == '23503'
          ? 'Cannot delete: item has stock movements.'
          : e.message;
      _showSnack(msg, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Delete failed. Please try again.', error: true);
    }
  }

  Future<void> _toggleActive(InventoryItem item) async {
    try {
      await supabase
          .from('items')
          .update({'is_active': !item.isActive}).eq('id', item.id);
      if (!mounted) return;
      _showSnack(item.isActive ? 'Item deactivated.' : 'Item activated.');
      _fetchItems();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Update failed. Please try again.', error: true);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  Future<bool> _showDeleteDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Item',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            content: Text(
              'Are you sure you want to delete "$name"? This cannot be undone.',
              style:
                  const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openAddItem() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
    );
    if (created == true) _fetchItems();
  }

  Future<void> _openEditItem(InventoryItem item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemScreen(item: item)),
    );
    if (updated == true) _fetchItems();
  }

  Future<void> _openStockAdjust(InventoryItem item) async {
    final adjusted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StockAdjustScreen(item: item)),
    );
    if (adjusted == true) _fetchItems();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItem,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search items, SKU...',
          hintStyle:
              const TextStyle(fontSize: 14, color: AppTheme.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppTheme.textHint),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: AppTheme.textHint),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    void setFilter(String value) {
      setState(() => _filterStatus = value);
      _applyFilter();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InventoryFilterChip(
              label: 'All',
              value: 'all',
              selected: _filterStatus == 'all',
              onTap: () => setFilter('all')),
          const SizedBox(width: 8),
          InventoryFilterChip(
              label: 'Active',
              value: 'active',
              selected: _filterStatus == 'active',
              onTap: () => setFilter('active')),
          const SizedBox(width: 8),
          InventoryFilterChip(
              label: 'Inactive',
              value: 'inactive',
              selected: _filterStatus == 'inactive',
              onTap: () => setFilter('inactive')),
          const SizedBox(width: 8),
          InventoryFilterChip(
              label: '⚠ Low Stock',
              value: 'low_stock',
              selected: _filterStatus == 'low_stock',
              onTap: () => setFilter('low_stock'),
              warningColor: true),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.textHint),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              _items.isEmpty ? 'No Items Yet' : 'No Results Found',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _items.isEmpty
                  ? 'Tap "Add Item" to add your first inventory item.'
                  : 'Try adjusting your search or filters.',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchItems,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ItemTile(
          item: _filteredItems[i],
          onEdit: () => _openEditItem(_filteredItems[i]),
          onDelete: () => _deleteItem(_filteredItems[i]),
          onAdjustStock: () => _openStockAdjust(_filteredItems[i]),
          onToggleActive: () => _toggleActive(_filteredItems[i]),
        ),
      ),
    );
  }
}