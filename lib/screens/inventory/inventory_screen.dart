// inventory_screen.dart
// The main Inventory listing screen with search, filters, and item management.
// Uses InventoryService for in-memory + disk caching — mirrors the Dashboard pattern:
//   • First load: show cached data instantly if fresh, else fetch from network.
//   • Pull-to-refresh: force network fetch silently (no loading spinner if data exists).
//   • After add/edit/delete: invalidate cache then refresh.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_models.dart';
import 'inventory_widgets.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';
import '../../services/inventory_service.dart';

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
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      // 1. Fetch (returns cache immediately if fresh, else hits network)
      final items = await InventoryService.fetchItems(forceRefresh: forceRefresh);

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
        _error = null;
      });
      _applyFilter();

      // 2. If cache was stale but we didn't force-refresh, trigger background update
      if (!forceRefresh && InventoryService.isCacheStale) {
        _refreshInBackground();
      }
    } catch (e) {
      if (!mounted) return;

      // If we already have data, keep showing it and show a snack instead
      if (_items.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connect to wifi to update inventory'),
            backgroundColor: AppTheme.errorColor.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to load items. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final items = await InventoryService.fetchItems(forceRefresh: true);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
        _applyFilter();
      }
    } catch (_) {
      // Fail silently — keep showing current (cached) data
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
      InventoryService.invalidate();
      _loadData(forceRefresh: true);
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
      InventoryService.invalidate();
      _loadData(forceRefresh: true);
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
            backgroundColor: AppTheme.getSurface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            content: Text(
              'Are you sure you want to delete "$name"? This cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    if (created == true) {
      InventoryService.invalidate();
      _loadData(forceRefresh: true);
    }
  }

  Future<void> _openEditItem(InventoryItem item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemScreen(item: item)),
    );
    if (updated == true) {
      InventoryService.invalidate();
      _loadData(forceRefresh: true);
    }
  }

  Future<void> _openItemDetail(InventoryItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          item: item,
          onDataChanged: () {
            InventoryService.invalidate();
            _loadData(forceRefresh: true);
          },
        ),
      ),
    );
    if (result == true) {
      InventoryService.invalidate();
      _loadData(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
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
      color: AppTheme.getBg(context),
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
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search items, SKU...',
          hintStyle:
              TextStyle(fontSize: 14, color: AppTheme.getTextHint(context)),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: AppTheme.getTextHint(context)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18, color: AppTheme.getTextHint(context)),
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
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.getTextHint(context)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry'),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkPrimaryLight
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.inventory_2_rounded,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
              Text(
                _items.isEmpty ? 'No Items Yet' : 'No Results Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              Text(
                _items.isEmpty
                    ? 'Tap "Add Item" to add your first inventory item.'
                    : 'Try adjusting your search or filters.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.getTextSecondary(context)),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      // Pull-to-refresh: force a network fetch, but never show full loading
      // spinner — existing list stays visible while the indicator spins.
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ItemTile(
          item: _filteredItems[i],
          onTap: () => _openItemDetail(_filteredItems[i]),
          onEdit: () => _openEditItem(_filteredItems[i]),
          onDelete: () => _deleteItem(_filteredItems[i]),
          onToggleActive: () => _toggleActive(_filteredItems[i]),
        ),
      ),
    );
  }
}