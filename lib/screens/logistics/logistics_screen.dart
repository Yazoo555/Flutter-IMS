// logistics_screen.dart
// Main Logistics screen with two tabs: Suppliers and Tasks.
// Lists all suppliers and all logistics tasks with search, filter, and CRUD.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'supplier_detail_screen.dart';
import 'supplier_form_dialog.dart';
import 'task_form_dialog.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Suppliers State
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoadingSuppliers = true;
  String? _supplierError;
  final _supplierSearchController = TextEditingController();
  String _supplierFilterStatus = 'all';

  // Tasks State
  List<LogisticsTask> _tasks = [];
  List<LogisticsTask> _filteredTasks = [];
  bool _isLoadingTasks = true;
  String? _taskError;
  final _taskSearchController = TextEditingController();
  String _taskFilterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB and other tab-specific UI
    });

    _fetchSuppliers();
    _fetchTasks();

    _supplierSearchController.addListener(_applySupplierFilter);
    _taskSearchController.addListener(_applyTaskFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supplierSearchController.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  // ─── Suppliers Data ────────────────────────────────────────────────────────

  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
      _supplierError = null;
    });
    try {
      final suppliers = await LogisticsService.getSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _isLoadingSuppliers = false;
      });
      _applySupplierFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _supplierError = 'Failed to load suppliers.';
        _isLoadingSuppliers = false;
      });
    }
  }

  void _applySupplierFilter() {
    final query = _supplierSearchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _suppliers.where((s) {
        final matchesSearch = query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.phone.contains(query);
        final matchesStatus = switch (_supplierFilterStatus) {
          'active' => s.isActive,
          'inactive' => !s.isActive,
          _ => true,
        };
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ─── Tasks Data ────────────────────────────────────────────────────────────

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoadingTasks = true;
      _taskError = null;
    });
    try {
      final tasks = await LogisticsService.getAllTasksDetail(
          status: _taskFilterStatus);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
      _applyTaskFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskError = 'Failed to load tasks.';
        _isLoadingTasks = false;
      });
    }
  }

  void _applyTaskFilter() {
    final query = _taskSearchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((t) {
        final matchesSearch = query.isEmpty ||
            t.title.toLowerCase().contains(query) ||
            (t.supplierName?.toLowerCase().contains(query) ?? false) ||
            (t.description?.toLowerCase().contains(query) ?? false);
        return matchesSearch;
      }).toList();
    });
  }

  // ─── Shared Actions ────────────────────────────────────────────────────────

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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: isDark ? AppTheme.darkTextHint : AppTheme.textHint,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Suppliers'),
              Tab(text: 'All Tasks'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuppliersTab(isDark),
          _buildTasksTab(isDark),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _openAddSupplier,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Add Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: _openAddTask,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }
  }

  // ─── Tab 1: Suppliers ──────────────────────────────────────────────────────

  Widget _buildSuppliersTab(bool isDark) {
    return Column(
      children: [
        _buildSupplierSearchBar(isDark),
        Expanded(child: _buildSupplierList(isDark)),
      ],
    );
  }

  Widget _buildSupplierSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _buildSearchBar(_supplierSearchController, 'Search suppliers...', isDark),
          const SizedBox(height: 10),
          _buildSupplierFilterChips(isDark),
        ],
      ),
    );
  }

  Widget _buildSupplierFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _supplierFilterStatus == 'all',
            onTap: () {
              setState(() => _supplierFilterStatus = 'all');
              _applySupplierFilter();
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            selected: _supplierFilterStatus == 'active',
            onTap: () {
              setState(() => _supplierFilterStatus = 'active');
              _applySupplierFilter();
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Inactive',
            selected: _supplierFilterStatus == 'inactive',
            onTap: () {
              setState(() => _supplierFilterStatus = 'inactive');
              _applySupplierFilter();
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(bool isDark) {
    if (_isLoadingSuppliers) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_supplierError != null) {
      return _buildErrorState(_supplierError!, _fetchSuppliers, isDark);
    }
    if (_filteredSuppliers.isEmpty) {
      return _buildEmptyState('No suppliers found.', Icons.business_rounded, isDark);
    }
    return RefreshIndicator(
      onRefresh: _fetchSuppliers,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredSuppliers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SupplierTile(
          supplier: _filteredSuppliers[i],
          isDark: isDark,
          onTap: () => _openSupplierDetail(_filteredSuppliers[i]),
          onEdit: () => _openEditSupplier(_filteredSuppliers[i]),
          onDelete: () => _deleteSupplier(_filteredSuppliers[i]),
        ),
      ),
    );
  }

  // ─── Tab 2: Tasks ──────────────────────────────────────────────────────────

  Widget _buildTasksTab(bool isDark) {
    return Column(
      children: [
        _buildTaskSearchBar(isDark),
        Expanded(child: _buildTaskList(isDark)),
      ],
    );
  }

  Widget _buildTaskSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _buildSearchBar(_taskSearchController, 'Search tasks, suppliers...', isDark),
          const SizedBox(height: 10),
          _buildTaskFilterChips(isDark),
        ],
      ),
    );
  }

  Widget _buildTaskFilterChips(bool isDark) {
    final statuses = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('in_progress', 'In Progress'),
      ('completed', 'Completed'),
      ('cancelled', 'Cancelled'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: s.$2,
              selected: _taskFilterStatus == s.$1,
              onTap: () {
                setState(() => _taskFilterStatus = s.$1);
                _fetchTasks();
              },
              isDark: isDark,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList(bool isDark) {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_taskError != null) {
      return _buildErrorState(_taskError!, _fetchTasks, isDark);
    }
    if (_filteredTasks.isEmpty) {
      return _buildEmptyState('No tasks found.', Icons.task_alt_rounded, isDark);
    }
    return RefreshIndicator(
      onRefresh: _fetchTasks,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredTasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TaskTile(
          task: _filteredTasks[i],
          isDark: isDark,
          onTap: () => _openTaskDetail(_filteredTasks[i]),
          onEdit: () => _openEditTask(_filteredTasks[i]),
          onDelete: () => _deleteTask(_filteredTasks[i]),
        ),
      ),
    );
  }

  // ─── Common Widgets ────────────────────────────────────────────────────────

  Widget _buildSearchBar(TextEditingController controller, String hint, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ─── Action Handlers ───────────────────────────────────────────────────────

  void _openAddSupplier() async {
    final result = await showDialog<bool>(context: context, builder: (_) => const SupplierFormDialog());
    if (result == true) {
      _showSnack('Supplier added.');
      _fetchSuppliers();
    }
  }

  void _openEditSupplier(Supplier s) async {
    final result = await showDialog<bool>(context: context, builder: (_) => SupplierFormDialog(supplier: s));
    if (result == true) {
      _showSnack('Supplier updated.');
      _fetchSuppliers();
    }
  }

  void _deleteSupplier(Supplier s) async {
    final confirmed = await _showConfirmDialog('Delete Supplier', 'Delete "${s.name}"?');
    if (confirmed) {
      try {
        await LogisticsService.deleteSupplier(s.id);
        _showSnack('Supplier deleted.');
        _fetchSuppliers();
      } catch (_) {
        _showSnack('Delete failed.', error: true);
      }
    }
  }

  void _openAddTask() async {
    if (_suppliers.isEmpty) {
      _showSnack('Please add a supplier first.');
      return;
    }

    final selectedSupplier = await showDialog<Supplier>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Supplier'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suppliers.length,
              itemBuilder: (context, index) {
                final s = _suppliers[index];
                return ListTile(
                  leading: const Icon(Icons.business_rounded,
                      color: AppTheme.primary),
                  title: Text(s.name),
                  subtitle: Text(s.email),
                  onTap: () => Navigator.pop(ctx, s),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedSupplier != null) {
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => TaskFormDialog(supplierId: selectedSupplier.id),
      );
      if (result == true) {
        _showSnack('Task created.');
        _fetchTasks();
      }
    }
  }

  void _openEditTask(LogisticsTask t) async {
    final result = await showDialog<bool>(context: context, builder: (_) => TaskFormDialog(supplierId: t.supplierId, task: t));
    if (result == true) {
      _showSnack('Task updated.');
      _fetchTasks();
    }
  }

  void _deleteTask(LogisticsTask t) async {
    final confirmed = await _showConfirmDialog('Delete Task', 'Delete "${t.title}"?');
    if (confirmed) {
      try {
        await LogisticsService.deleteTask(t.id);
        _showSnack('Task deleted.');
        _fetchTasks();
      } catch (_) {
        _showSnack('Delete failed.', error: true);
      }
    }
  }

  void _openSupplierDetail(Supplier s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: s, onDataChanged: _fetchSuppliers)));
  }

  void _openTaskDetail(LogisticsTask t) {
    // Could navigate to a specific task detail if needed, but usually supplier detail is enough.
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    ) ?? false;
  }
}

// ── Shared Sub-widgets ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _FilterChip({required this.label, required this.selected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary.withAlpha(50),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(color: selected ? AppTheme.primary : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary), fontSize: 12),
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? AppTheme.primary : (isDark ? AppTheme.darkBorder : AppTheme.border))),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SupplierTile({required this.supplier, required this.isDark, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
      leading: CircleAvatar(backgroundColor: AppTheme.primary.withAlpha(30), child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20)),
      title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(supplier.phone, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary, fontSize: 13)),
      trailing: PopupMenuButton(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (val) {
          if (val == 'edit') onEdit();
          if (val == 'delete') onDelete();
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final LogisticsTask task;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TaskTile({required this.task, required this.isDark, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      'pending' => const Color(0xFFF59E0B),
      'in_progress' => const Color(0xFF0EA5E9),
      'completed' => const Color(0xFF10B981),
      'cancelled' => const Color(0xFFEF4444),
      _ => AppTheme.textHint,
    };

    return ListTile(
      onTap: onTap,
      tileColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
      leading: CircleAvatar(backgroundColor: statusColor.withAlpha(30), child: Icon(Icons.task_alt_rounded, color: statusColor, size: 20)),
      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.supplierName ?? 'No Supplier', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(task.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (val) {
          if (val == 'edit') onEdit();
          if (val == 'delete') onDelete();
        },
      ),
    );
  }
}