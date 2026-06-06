import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _storage = StorageService();
  List<Task> _tasks = [];
  bool _loading = true;
  bool _isKanbanView = true;
  String _searchQuery = '';
  TaskPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _storage.loadTasks();
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  List<Task> get _filteredTasks {
    var filtered = _tasks;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterPriority != null) {
      filtered =
          filtered.where((t) => t.priority == _filterPriority).toList();
    }
    return filtered;
  }

  List<Task> get _todoTasks =>
      _filteredTasks.where((t) => t.status == TaskStatus.todo).toList();
  List<Task> get _inProgressTasks =>
      _filteredTasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get _doneTasks =>
      _filteredTasks.where((t) => t.status == TaskStatus.done).toList();

  Future<void> _addTask() async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TaskEditSheet(),
    );
    if (result != null) {
      await _storage.addTask(result, _tasks);
      await _load();
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskEditSheet(task: task),
    );
    if (result != null) {
      await _storage.updateTask(result, _tasks);
      await _load();
    }
  }

  Future<void> _deleteTask(Task task) async {
    await _storage.deleteTask(task.id, _tasks);
    await _load();
  }

  Future<void> _toggleStatus(Task task) async {
    final newStatus = task.status == TaskStatus.done
        ? TaskStatus.todo
        : task.status == TaskStatus.todo
            ? TaskStatus.inProgress
            : TaskStatus.done;
    final updated = task.copyWith(
      status: newStatus,
      completed: newStatus == TaskStatus.done,
    );
    await _storage.updateTask(updated, _tasks);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 20, color: AppTheme.textPrimary(context)),
              const SizedBox(width: 10),
              Text(
                'Tasks',
                style: AppTypography.headingLarge.copyWith(
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggleBtn(
                      icon: Icons.view_kanban_rounded,
                      isSelected: _isKanbanView,
                      onTap: () => setState(() => _isKanbanView = true),
                    ),
                    _ViewToggleBtn(
                      icon: Icons.view_list_rounded,
                      isSelected: !_isKanbanView,
                      onTap: () => setState(() => _isKanbanView = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addTask,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                    boxShadow: DesignTokens.indigoGlow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Add Task',
                        style: AppTypography.smallBold
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTypography.body.copyWith(
                    color: AppTheme.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppTheme.textTertiary(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppTheme.textTertiary(context),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Priority filter
              PopupMenuButton<TaskPriority?>(
                onSelected: (p) => setState(() => _filterPriority = p),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  const PopupMenuItem(
                    value: TaskPriority.urgent,
                    child: Text('🔴 Urgent'),
                  ),
                  const PopupMenuItem(
                    value: TaskPriority.high,
                    child: Text('🟠 High'),
                  ),
                  const PopupMenuItem(
                    value: TaskPriority.medium,
                    child: Text('🟡 Medium'),
                  ),
                  const PopupMenuItem(
                    value: TaskPriority.low,
                    child: Text('🟢 Low'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Content
        Expanded(
          child: _filteredTasks.isEmpty
              ? _EmptyTasks(isDark: isDark, onAdd: _addTask)
              : _isKanbanView
                  ? _KanbanView(
                      todo: _todoTasks,
                      inProgress: _inProgressTasks,
                      done: _doneTasks,
                      onToggleStatus: _toggleStatus,
                      onEdit: _editTask,
                      onDelete: _deleteTask,
                    )
                  : _ListView(
                      tasks: _filteredTasks,
                      onToggleStatus: _toggleStatus,
                      onEdit: _editTask,
                      onDelete: _deleteTask,
                    ),
        ),
      ],
    );
  }
}

// ── View Toggle Button ──────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? AppColors.primary
              : AppTheme.textTertiary(context),
        ),
      ),
    );
  }
}

// ── Kanban View ─────────────────────────────────────────────────────────────

class _KanbanView extends StatelessWidget {
  final List<Task> todo;
  final List<Task> inProgress;
  final List<Task> done;
  final Future<void> Function(Task) onToggleStatus;
  final Future<void> Function(Task) onEdit;
  final Future<void> Function(Task) onDelete;

  const _KanbanView({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: 'To Do',
            tasks: todo,
            color: AppColors.primary,
            icon: Icons.radio_button_unchecked,
            onToggleStatus: onToggleStatus,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          const SizedBox(width: 16),
          _KanbanColumn(
            title: 'In Progress',
            tasks: inProgress,
            color: AppColors.warning,
            icon: Icons.timelapse_rounded,
            onToggleStatus: onToggleStatus,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          const SizedBox(width: 16),
          _KanbanColumn(
            title: 'Done',
            tasks: done,
            color: AppColors.success,
            icon: Icons.check_circle_outline,
            onToggleStatus: onToggleStatus,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Kanban Column ───────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color color;
  final IconData icon;
  final Future<void> Function(Task) onToggleStatus;
  final Future<void> Function(Task) onEdit;
  final Future<void> Function(Task) onDelete;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.color,
    required this.icon,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final width = MediaQuery.of(context).size.width;
    final columnWidth = (width - 64).clamp(250.0, 350.0);

    return SizedBox(
      width: columnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppTypography.smallBold.copyWith(
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks
          ...tasks.map(
            (task) => _TaskCard(
              task: task,
              onToggleStatus: () => onToggleStatus(task),
              onEdit: () => onEdit(task),
              onDelete: () => onDelete(task),
            ).animate().fadeIn(duration: 250.ms),
          ),
        ],
      ),
    );
  }
}

// ── Task Card ───────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.error;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.primary;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded,
            color: AppColors.error, size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: AppTheme.cardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onToggleStatus,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: task.status == TaskStatus.done
                          ? AppColors.success.withOpacity(0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.status == TaskStatus.done
                            ? AppColors.success
                            : AppTheme.textTertiary(context),
                        width: 1.5,
                      ),
                    ),
                    child: task.status == TaskStatus.done
                        ? const Icon(Icons.check,
                            size: 12, color: AppColors.success)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.bodyBold.copyWith(
                      color: task.status == TaskStatus.done
                          ? AppTheme.textTertiary(context)
                          : AppTheme.textPrimary(context),
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: AppTypography.small.copyWith(
                  color: AppTheme.textTertiary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                // Priority dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  task.priority.name.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _priorityColor,
                  ),
                ),
                const Spacer(),
                if (task.dueDate != null)
                  Text(
                    task.dueDate!,
                    style: AppTypography.caption.copyWith(
                      color: AppTheme.textTertiary(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── List View ───────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<Task> tasks;
  final Future<void> Function(Task) onToggleStatus;
  final Future<void> Function(Task) onEdit;
  final Future<void> Function(Task) onDelete;

  const _ListView({
    required this.tasks,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          onToggleStatus: () => onToggleStatus(task),
          onEdit: () => onEdit(task),
          onDelete: () => onDelete(task),
        ).animate().fadeIn(
              delay: Duration(milliseconds: index * 40),
              duration: 250.ms,
            );
      },
    );
  }
}

// ── Empty Tasks ─────────────────────────────────────────────────────────────

class _EmptyTasks extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyTasks({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: AppTypography.headingMedium.copyWith(
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first task to stay organized',
            style: AppTypography.body.copyWith(
              color: AppTheme.textTertiary(context),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Edit Sheet ─────────────────────────────────────────────────────────

class _TaskEditSheet extends StatefulWidget {
  final Task? task;
  const _TaskEditSheet({this.task});

  @override
  State<_TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<_TaskEditSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = t.description;
      _priority = t.priority;
      _status = t.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      status: _status,
      completed: _status == TaskStatus.done,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.task != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusSheet),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary(context).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isEdit ? 'Edit Task' : 'New Task',
              style: AppTypography.headingLarge.copyWith(
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildField(
              controller: _titleController,
              label: 'Title',
              hint: 'What needs to be done?',
              icon: Icons.title_rounded,
              context: context,
            ),
            const SizedBox(height: 16),

            // Description
            _buildField(
              controller: _descController,
              label: 'Description',
              hint: 'Add details (optional)',
              icon: Icons.notes_rounded,
              context: context,
            ),
            const SizedBox(height: 18),

            // Priority
            Text(
              'Priority',
              style: AppTypography.smallBold.copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskPriority.values.map((p) {
                final sel = p == _priority;
                final colors = {
                  TaskPriority.low: AppColors.success,
                  TaskPriority.medium: AppColors.primary,
                  TaskPriority.high: AppColors.warning,
                  TaskPriority.urgent: AppColors.error,
                };
                final c = colors[p]!;
                return GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? c : c.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                      border: Border.all(
                        color: sel ? c : c.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      p.name.toUpperCase(),
                      style: AppTypography.smallBold.copyWith(
                        color: sel ? Colors.white : c,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Create Task',
                  style: AppTypography.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.smallBold.copyWith(
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.body.copyWith(
            color: AppTheme.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textTertiary(context)),
            filled: true,
            fillColor: AppTheme.isDark(context)
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
