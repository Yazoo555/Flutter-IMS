// logistics_screen.dart
// Main Logistics screen with two tabs: Suppliers and Tasks.
// Uses LogisticsService caching — same pattern as Dashboard and Inventory:
//   • First load: show cached data instantly, fetch from network if stale.
//   • Pull-to-refresh: force network fetch silently (list stays visible).
//   • After mutations: invalidate cache then force-refresh.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'supplier_detail_screen.dart';
import 'supplier_form_dialog.dart';
import 'task_form_dialog.dart';
import 'task_detail_screen.dart';

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

    _loadSuppliers();
    _loadTasks();

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

  Future<void> _loadSuppliers({bool forceRefresh = false}) async {
    try {
      final suppliers =
          await LogisticsService.getSuppliers(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _isLoadingSuppliers = false;
        _supplierError = null;
      });
      _applySupplierFilter();

      // Background update if stale but we served cache
      if (!forceRefresh && LogisticsService.isSuppliersStale) {
        _refreshSuppliersInBackground();
      }
    } catch (e) {
      if (!mounted) return;
      if (_suppliers.isNotEmpty) {
        // Keep showing cached data, just show a snack
        setState(() => _isLoadingSuppliers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connect to wifi to update suppliers'),
            backgroundColor: AppTheme.errorColor.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _supplierError = 'Failed to load suppliers.';
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  Future<void> _refreshSuppliersInBackground() async {
    try {
      final suppliers =
          await LogisticsService.getSuppliers(forceRefresh: true);
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _supplierError = null;
        });
        _applySupplierFilter();
      }
    } catch (_) {
      // Fail silently — keep showing cached data
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

  Future<void> _loadTasks({bool forceRefresh = false}) async {
    try {
      final tasks = await LogisticsService.getAllTasksDetail(
        status: _taskFilterStatus,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
        _taskError = null;
      });
      _applyTaskFilter();

      // Background update if stale but we served cache (only for "all" view)
      final isFiltered = _taskFilterStatus != 'all';
      if (!forceRefresh && !isFiltered && LogisticsService.isTasksStale) {
        _refreshTasksInBackground();
      }
    } catch (e) {
      if (!mounted) return;
      if (_tasks.isNotEmpty) {
        // Keep showing cached data, just show a snack
        setState(() => _isLoadingTasks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connect to wifi to update tasks'),
            backgroundColor: AppTheme.errorColor.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _taskError = 'Failed to load tasks.';
          _isLoadingTasks = false;
        });
      }
    }
  }

  Future<void> _refreshTasksInBackground() async {
    try {
      final tasks = await LogisticsService.getAllTasksDetail(forceRefresh: true);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _taskError = null;
        });
        _applyTaskFilter();
      }
    } catch (_) {
      // Fail silently — keep showing cached data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            border: Border(bottom: BorderSide(color: AppTheme.getBorder(context))),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.getTextHint(context),
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
          _buildSuppliersTab(context),
          _buildTasksTab(context),
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

  Widget _buildSuppliersTab(BuildContext context) {
    return Column(
      children: [
        _buildSupplierSearchBar(context),
        Expanded(child: _buildSupplierList(context)),
      ],
    );
  }

  Widget _buildSupplierSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBg(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorder(context), width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _buildSearchBar(_supplierSearchController, 'Search suppliers...', context),
          const SizedBox(height: 12),
          _buildSupplierFilterChips(context),
        ],
      ),
    );
  }

  Widget _buildSupplierFilterChips(BuildContext context) {
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
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            selected: _supplierFilterStatus == 'active',
            onTap: () {
              setState(() => _supplierFilterStatus = 'active');
              _applySupplierFilter();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Inactive',
            selected: _supplierFilterStatus == 'inactive',
            onTap: () {
              setState(() => _supplierFilterStatus = 'inactive');
              _applySupplierFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(BuildContext context) {
    if (_isLoadingSuppliers) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_supplierError != null) {
      return _buildErrorState(_supplierError!, () => _loadSuppliers(forceRefresh: true), context);
    }
    if (_filteredSuppliers.isEmpty) {
      return _buildEmptyState('No suppliers found.', Icons.business_rounded, context);
    }
    return RefreshIndicator(
      onRefresh: () => _loadSuppliers(forceRefresh: true),
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredSuppliers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SupplierTile(
          supplier: _filteredSuppliers[i],
          onTap: () => _openSupplierDetail(_filteredSuppliers[i]),
          onEdit: () => _openEditSupplier(_filteredSuppliers[i]),
          onDelete: () => _deleteSupplier(_filteredSuppliers[i]),
        ),
      ),
    );
  }

  // ─── Tab 2: Tasks ──────────────────────────────────────────────────────────

  Widget _buildTasksTab(BuildContext context) {
    return Column(
      children: [
        _buildTaskSearchBar(context),
        Expanded(child: _buildTaskList(context)),
      ],
    );
  }

  Widget _buildTaskSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBg(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorder(context), width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _buildSearchBar(_taskSearchController, 'Search tasks, suppliers...', context),
          const SizedBox(height: 12),
          _buildTaskFilterChips(context),
        ],
      ),
    );
  }

  Widget _buildTaskFilterChips(BuildContext context) {
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
                setState(() {
                  _taskFilterStatus = s.$1;
                  // Show loading only when switching to a filtered view
                  // (bypasses cache, hits network)
                  if (s.$1 != 'all') _isLoadingTasks = true;
                });
                _loadTasks(forceRefresh: s.$1 != 'all');
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_taskError != null) {
      return _buildErrorState(_taskError!, () => _loadTasks(forceRefresh: true), context);
    }
    if (_filteredTasks.isEmpty) {
      return _buildEmptyState('No tasks found.', Icons.task_alt_rounded, context);
    }
    return RefreshIndicator(
      onRefresh: () => _loadTasks(forceRefresh: true),
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _filteredTasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TaskTile(
          task: _filteredTasks[i],
          onTap: () => _openTaskDetail(_filteredTasks[i]),
          onEdit: () => _openEditTask(_filteredTasks[i]),
          onDelete: () => _deleteTask(_filteredTasks[i]),
        ),
      ),
    );
  }

  // ─── Common Widgets ────────────────────────────────────────────────────────

  Widget _buildSearchBar(TextEditingController controller, String hint, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: AppTheme.getTextHint(context)),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.getTextHint(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.getTextHint(context)),
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.getTextHint(context)),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ],
      ),
    );
  }

  // ─── Action Handlers ───────────────────────────────────────────────────────

  void _openAddSupplier() async {
    final result = await showDialog<bool>(context: context, builder: (_) => const SupplierFormDialog());
    if (result == true) {
      _showSnack('Supplier added.');
      LogisticsService.invalidateSuppliers();
      _loadSuppliers(forceRefresh: true);
    }
  }

  void _openEditSupplier(Supplier s) async {
    final result = await showDialog<bool>(context: context, builder: (_) => SupplierFormDialog(supplier: s));
    if (result == true) {
      _showSnack('Supplier updated.');
      LogisticsService.invalidateSuppliers();
      _loadSuppliers(forceRefresh: true);
    }
  }

  void _deleteSupplier(Supplier s) async {
    final confirmed = await _showConfirmDialog('Delete Supplier', 'Delete "${s.name}"?');
    if (confirmed) {
      try {
        await LogisticsService.deleteSupplier(s.id);
        _showSnack('Supplier deleted.');
        LogisticsService.invalidateSuppliers();
        _loadSuppliers(forceRefresh: true);
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
          backgroundColor: AppTheme.getSurface(context),
          title: Text('Select Supplier', style: TextStyle(color: AppTheme.getTextPrimary(context))),
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
                  title: Text(s.name, style: TextStyle(color: AppTheme.getTextPrimary(context))),
                  subtitle: Text(s.email, style: TextStyle(color: AppTheme.getTextSecondary(context))),
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
        LogisticsService.invalidateTasks();
        _loadTasks(forceRefresh: true);
      }
    }
  }

  void _openEditTask(LogisticsTask t) async {
    final result = await showDialog<bool>(context: context, builder: (_) => TaskFormDialog(supplierId: t.supplierId, task: t));
    if (result == true) {
      _showSnack('Task updated.');
      LogisticsService.invalidateTasks();
      _loadTasks(forceRefresh: true);
    }
  }

  void _deleteTask(LogisticsTask t) async {
    final confirmed = await _showConfirmDialog('Delete Task', 'Delete "${t.title}"?');
    if (confirmed) {
      try {
        await LogisticsService.deleteTask(t.id);
        _showSnack('Task deleted.');
        LogisticsService.invalidateTasks();
        _loadTasks(forceRefresh: true);
      } catch (_) {
        _showSnack('Delete failed.', error: true);
      }
    }
  }

  void _openSupplierDetail(Supplier s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: s, onDataChanged: () {
      LogisticsService.invalidateSuppliers();
      _loadSuppliers(forceRefresh: true);
    }))).then((_) {
      // Also refresh tasks since supplier changes can affect them
      LogisticsService.invalidateTasks();
      _loadTasks(forceRefresh: true);
    });
  }

  void _openTaskDetail(LogisticsTask t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: t),
      ),
    ).then((_) {
      LogisticsService.invalidateTasks();
      _loadTasks(forceRefresh: true);
    });
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Text(title, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        content: Text(content, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: AppTheme.getTextSecondary(context)))),
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
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.getBorder(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SupplierTile({required this.supplier, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.getBorder(context))),
      leading: CircleAvatar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkPrimaryLighter
              : AppTheme.primaryLight,
          child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20)),
      title: Text(supplier.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getTextPrimary(context))),
      subtitle: Text(supplier.phone, style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
      trailing: PopupMenuButton(
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppTheme.getTextPrimary(context)))),
          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
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
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TaskTile({required this.task, required this.onTap, required this.onEdit, required this.onDelete});

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
      tileColor: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.getBorder(context))),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1), 
        child: Icon(Icons.task_alt_rounded, color: statusColor, size: 20)
      ),
      title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getTextPrimary(context))),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.supplierName ?? 'No Supplier', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(task.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppTheme.getTextPrimary(context)))),
          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
        onSelected: (val) {
          if (val == 'edit') onEdit();
          if (val == 'delete') onDelete();
        },
      ),
    );
  }
}