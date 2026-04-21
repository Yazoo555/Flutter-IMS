// logistics_screen.dart
// Main Logistics screen with Suppliers tab — lists all suppliers with search,
// filter, create, edit, delete, and navigation to supplier detail.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'supplier_detail_screen.dart';
import 'supplier_form_dialog.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _filterStatus = 'all'; // all | active | inactive

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suppliers = await LogisticsService.getSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load suppliers. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _suppliers.where((s) {
        final matchesSearch = query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.phone.contains(query) ||
            (s.contactName?.toLowerCase().contains(query) ?? false);

        final matchesStatus = switch (_filterStatus) {
          'active' => s.isActive,
          'inactive' => !s.isActive,
          _ => true,
        };

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _createSupplier() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SupplierFormDialog(),
    );
    if (result == true) {
      _showSnack('Supplier created successfully.');
      _fetchSuppliers();
    }
  }

  Future<void> _editSupplier(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SupplierFormDialog(supplier: supplier),
    );
    if (result == true) {
      _showSnack('Supplier updated successfully.');
      _fetchSuppliers();
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirmed = await _showDeleteDialog(supplier.name);
    if (!confirmed) return;

    try {
      await LogisticsService.deleteSupplier(supplier.id);
      if (!mounted) return;
      _showSnack('${supplier.name} deleted.');
      _fetchSuppliers();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed. Please try again.', error: true);
    }
  }

  Future<void> _toggleActive(Supplier supplier) async {
    try {
      await LogisticsService.updateSupplier(
        supplier.id,
        {'is_active': !supplier.isActive},
      );
      if (!mounted) return;
      _showSnack(
          supplier.isActive ? 'Supplier deactivated.' : 'Supplier activated.');
      _fetchSuppliers();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Update failed. Please try again.', error: true);
    }
  }

  void _openSupplierDetail(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailScreen(
          supplier: supplier,
          onDataChanged: _fetchSuppliers,
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<bool> _showDeleteDialog(String name) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? AppTheme.darkSurface : AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Supplier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "$name"? This cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSupplier,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Supplier',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _buildSearchField(isDark),
          const SizedBox(height: 10),
          _buildFilterChips(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search suppliers...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.darkTextHint : AppTheme.textHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? AppTheme.darkTextHint : AppTheme.textHint,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: isDark ? AppTheme.darkTextHint : AppTheme.textHint,
                  ),
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

  Widget _buildFilterChips(bool isDark) {
    void setFilter(String value) {
      setState(() => _filterStatus = value);
      _applyFilter();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filterStatus == 'all',
            onTap: () => setFilter('all'),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            selected: _filterStatus == 'active',
            onTap: () => setFilter('active'),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Inactive',
            selected: _filterStatus == 'inactive',
            onTap: () => setFilter('inactive'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark ? AppTheme.darkTextHint : AppTheme.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchSuppliers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _suppliers.isEmpty ? 'No Suppliers Yet' : 'No Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _suppliers.isEmpty
                  ? 'Tap "Add Supplier" to add your first supplier.'
                  : 'Try adjusting your search or filters.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchSuppliers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredSuppliers.length,
        separatorBuilder: (_, _2) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SupplierTile(
          supplier: _filteredSuppliers[i],
          isDark: isDark,
          onTap: () => _openSupplierDetail(_filteredSuppliers[i]),
          onEdit: () => _editSupplier(_filteredSuppliers[i]),
          onDelete: () => _deleteSupplier(_filteredSuppliers[i]),
          onToggleActive: () => _toggleActive(_filteredSuppliers[i]),
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : (isDark ? AppTheme.darkSurface : AppTheme.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : (isDark ? AppTheme.darkBorder : AppTheme.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Supplier Tile ─────────────────────────────────────────────────────────────

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _SupplierTile({
    required this.supplier,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textHint = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: supplier.isActive
                          ? (isDark
                              ? AppTheme.darkPrimaryLight
                              : AppTheme.primaryLight)
                          : borderColor.withAlpha(76),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      size: 24,
                      color:
                          supplier.isActive ? AppTheme.primary : textHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                supplier.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: supplier.isActive
                                      ? textPrimary
                                      : textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!supplier.isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: borderColor.withAlpha(127),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: textHint,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (supplier.contactName != null &&
                            supplier.contactName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            supplier.contactName!,
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: textSecondary,
                    ),
                    color: surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'toggle') onToggleActive();
                      if (val == 'delete') onDelete();
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
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(children: [
                          Icon(
                            supplier.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            supplier.isActive ? 'Deactivate' : 'Activate',
                            style: TextStyle(fontSize: 14, color: textPrimary),
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
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.errorColor)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom bar with contact info
            Container(
              decoration: BoxDecoration(
                color: bgColor.withAlpha(127),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (supplier.phone.isNotEmpty) ...[
                    Icon(Icons.phone_outlined,
                        size: 13, color: textHint),
                    const SizedBox(width: 4),
                    Text(
                      supplier.phone,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (supplier.email.isNotEmpty) ...[
                    Icon(Icons.email_outlined,
                        size: 13, color: textHint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        supplier.email,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: textHint,
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