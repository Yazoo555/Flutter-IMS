// supplier_detail_screen.dart
// Shows supplier info and their logistics tasks with full CRUD support.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'supplier_form_dialog.dart';
import 'task_form_dialog.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback? onDataChanged;

  const SupplierDetailScreen({
    super.key,
    required this.supplier,
    this.onDataChanged,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  late Supplier _supplier;
  List<LogisticsTask> _tasks = [];
  bool _isLoadingTasks = true;
  String? _taskError;

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
    _fetchTasks();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoadingTasks = true;
      _taskError = null;
    });

    try {
      final tasks =
          await LogisticsService.getTasksForSupplier(_supplier.id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskError = 'Failed to load tasks.';
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _editSupplier() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SupplierFormDialog(supplier: _supplier),
    );
    if (result == true) {
      _showSnack('Supplier updated.');
      widget.onDataChanged?.call();
      // Re-fetch supplier data
      try {
        final suppliers = await LogisticsService.getSuppliers();
        final updated = suppliers.firstWhere((s) => s.id == _supplier.id);
        if (!mounted) return;
        setState(() => _supplier = updated);
      } catch (_) {}
    }
  }

  Future<void> _createTask() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskFormDialog(supplierId: _supplier.id),
    );
    if (result == true) {
      _showSnack('Task created.');
      _fetchTasks();
    }
  }

  Future<void> _editTask(LogisticsTask task) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskFormDialog(supplierId: _supplier.id, task: task),
    );
    if (result == true) {
      _showSnack('Task updated.');
      _fetchTasks();
    }
  }

  Future<void> _deleteTask(LogisticsTask task) async {
    final confirmed = await _showDeleteDialog(task.title);
    if (!confirmed) return;

    try {
      await LogisticsService.deleteTask(task.id);
      if (!mounted) return;
      _showSnack('Task deleted.');
      _fetchTasks();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Delete failed.', error: true);
    }
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
            backgroundColor: AppTheme.getSurface(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Task',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            content: Text(
              'Are you sure you want to delete "$name"?',
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
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
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

  Color _statusColor(String status) => switch (status) {
        'pending' => const Color(0xFFF59E0B),
        'in_progress' => const Color(0xFF0EA5E9),
        'completed' => const Color(0xFF10B981),
        'cancelled' => const Color(0xFFEF4444),
        _ => AppTheme.textHint,
      };

  IconData _statusIcon(String status) => switch (status) {
        'pending' => Icons.schedule_rounded,
        'in_progress' => Icons.autorenew_rounded,
        'completed' => Icons.check_circle_rounded,
        'cancelled' => Icons.cancel_rounded,
        _ => Icons.help_outline_rounded,
      };

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final borderColor = AppTheme.getBorder(context);
    final bgColor = AppTheme.getBg(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: borderColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Supplier Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppTheme.primary),
            onPressed: _editSupplier,
            tooltip: 'Edit Supplier',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _fetchTasks,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Supplier Info Card ──────────────────────────────────────────
            _buildSupplierInfoCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // ── Tasks Header ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Logistics Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (!_isLoadingTasks)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkPrimaryLighter
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_tasks.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tasks List ──────────────────────────────────────────────────
            _buildTasksList(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              bgColor: bgColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierInfoCard({
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final textHint = AppTheme.getTextHint(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header with name and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkPrimaryLighter
                        : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _supplier.name.isNotEmpty
                          ? _supplier.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _supplier.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (_supplier.contactName != null &&
                          _supplier.contactName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _supplier.contactName!,
                            style:
                                TextStyle(fontSize: 13, color: textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _supplier.isActive
                        ? const Color(0xFF10B981).withAlpha(25)
                        : borderColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _supplier.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _supplier.isActive
                          ? const Color(0xFF10B981)
                          : textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Contact details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _supplier.email,
                  textSecondary: textSecondary,
                  textHint: textHint,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _supplier.phone,
                  textSecondary: textSecondary,
                  textHint: textHint,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _supplier.address,
                  textSecondary: textSecondary,
                  textHint: textHint,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Added',
                  value: DateFormat('MMM d, yyyy').format(_supplier.createdAt),
                  textSecondary: textSecondary,
                  textHint: textHint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textSecondary,
    required Color textHint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textHint),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList({
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color bgColor,
  }) {
    if (_isLoadingTasks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_taskError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40,
                  color: AppTheme.getTextHint(context)),
              const SizedBox(height: 8),
              Text(
                _taskError!,
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _fetchTasks,
                child: const Text('Retry',
                    style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkPrimaryLighter
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.task_outlined,
                  size: 28,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No Tasks Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "Add Task" to create a logistics task.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _tasks
          .map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  task: task,
                  bgColor: bgColor,
                  statusColor: _statusColor(task.status),
                  statusIcon: _statusIcon(task.status),
                  onEdit: () => _editTask(task),
                  onDelete: () => _deleteTask(task),
                ),
              ))
          .toList(),
    );
  }
}

// ── Task Tile ─────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  final LogisticsTask task;
  final Color bgColor;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.bgColor,
    required this.statusColor,
    required this.statusIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textHint = AppTheme.getTextHint(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final surfaceColor = AppTheme.getSurface(context);
    final borderColor = AppTheme.getBorder(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, size: 20, color: statusColor),
                ),
                const SizedBox(width: 12),
                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description!,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              task.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          if (task.scheduledDate != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.calendar_today_outlined,
                                size: 11, color: textHint),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(task.scheduledDate!),
                              style:
                                  TextStyle(fontSize: 11, color: textHint),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: textSecondary),
                  color: surfaceColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
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
          // Notes row
          if (task.notes != null && task.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, size: 13, color: textHint),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      task.notes!,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
