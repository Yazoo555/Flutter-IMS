import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_edit_todo_sheet.dart';

class TodoScreen extends StatefulWidget {
  final bool isDarkMode;

  const TodoScreen({super.key, required this.isDarkMode});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _storage = StorageService();
  List<TodoItem> _todos = [];
  bool _loading = true;

  // Filter state
  String _filterCategory =
      'All'; // All / Assignment / Tutorial / Workshop / Other
  String _filterStatus = 'Pending'; // All / Pending / Completed
  String _sortBy = 'Priority'; // Priority / Due Date / Created

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await _storage.loadTodos();
    setState(() {
      _todos = todos;
      _loading = false;
    });
  }

  // ── Derived list ──────────────────────────────────────────────────────────

  List<TodoItem> get _filtered {
    var list = [..._todos];

    // Category filter
    if (_filterCategory != 'All') {
      final cat = TodoCategory.values.firstWhere(
        (c) => c.label == _filterCategory,
      );
      list = list.where((t) => t.category == cat).toList();
    }

    // Status filter
    if (_filterStatus == 'Pending') {
      list = list.where((t) => !t.isCompleted).toList();
    } else if (_filterStatus == 'Completed') {
      list = list.where((t) => t.isCompleted).toList();
    }

    // Sort
    list.sort((a, b) {
      if (_sortBy == 'Due Date') {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (_sortBy == 'Priority') {
        // High → Medium → Low
        return b.priority.index.compareTo(a.priority.index);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  }

  // Stats
  int get _totalPending => _todos.where((t) => !t.isCompleted).length;
  int get _totalCompleted => _todos.where((t) => t.isCompleted).length;
  int get _overdueCount => _todos
      .where(
        (t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isBefore(DateTime.now()),
      )
      .length;
  int get _dueTodayCount {
    final now = DateTime.now();
    return _todos.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTodoSheet(),
    );
    if (result != null) {
      await _storage.addTodo(result, _todos);
      await _load();
    }
  }

  Future<void> _openEditSheet(TodoItem todo) async {
    final result = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTodoSheet(todo: todo),
    );
    if (result != null) {
      await _storage.updateTodo(result, _todos);
      await _load();
    }
  }

  Future<void> _toggleTodo(String id) async {
    await _storage.toggleTodo(id, _todos);
    await _load();
  }

  Future<void> _deleteTodo(TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Remove "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.deleteTodo(todo.id, _todos);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${todo.title}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filtered;

    return Scaffold(
      body: isDesktop
          ? _buildDesktop(isDark, filtered)
          : _buildMobile(isDark, filtered),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _buildDesktop(bool isDark, List<TodoItem> filtered) {
    return Row(
      children: [
        // Left panel: stats + filters
        Container(
          width: 260,
          color: isDark ? const Color(0xFF0F0F18) : const Color(0xFFEEEEF8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _StatsGrid(
                      pending: _totalPending,
                      completed: _totalCompleted,
                      overdue: _overdueCount,
                      dueToday: _dueTodayCount,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),

              // Category filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),
              ...['All', ...TodoCategory.values.map((c) => c.label)].map((cat) {
                final count = cat == 'All'
                    ? _todos.length
                    : _todos.where((t) => t.category.label == cat).length;
                return _SidebarFilterTile(
                  label: cat,
                  count: count,
                  isSelected: _filterCategory == cat,
                  color: cat == 'All'
                      ? AppColors.accent
                      : TodoCategory.values
                            .firstWhere((c) => c.label == cat)
                            .color,
                  onTap: () => setState(() => _filterCategory = cat),
                  isDark: isDark,
                );
              }),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Divider(height: 1),
              ),

              // Status filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),
              ...['All', 'Pending', 'Completed'].map((s) {
                final count = s == 'All'
                    ? _todos.length
                    : s == 'Pending'
                    ? _totalPending
                    : _totalCompleted;
                return _SidebarFilterTile(
                  label: s,
                  count: count,
                  isSelected: _filterStatus == s,
                  color: s == 'Completed'
                      ? const Color(0xFF22C55E)
                      : AppColors.accent,
                  onTap: () => setState(() => _filterStatus = s),
                  isDark: isDark,
                );
              }),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openAddSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right: task list
        Expanded(
          child: _TaskListView(
            todos: filtered,
            isEmpty: filtered.isEmpty,
            filterStatus: _filterStatus,
            sortBy: _sortBy,
            onSortChange: (s) => setState(() => _sortBy = s),
            onToggle: _toggleTodo,
            onEdit: _openEditSheet,
            onDelete: _deleteTodo,
            isDark: isDark,
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _buildMobile(bool isDark, List<TodoItem> filtered) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 100,
          collapsedHeight: 60,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '$_totalPending pending  •  $_overdueCount overdue',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _StatsGrid(
              pending: _totalPending,
              completed: _totalCompleted,
              overdue: _overdueCount,
              dueToday: _dueTodayCount,
              isDark: isDark,
            ),
          ),
        ),

        // Filters bar
        SliverToBoxAdapter(
          child: _FilterBar(
            filterCategory: _filterCategory,
            filterStatus: _filterStatus,
            sortBy: _sortBy,
            onCategory: (c) => setState(() => _filterCategory = c),
            onStatus: (s) => setState(() => _filterStatus = s),
            onSort: (s) => setState(() => _sortBy = s),
          ),
        ),

        // List
        filtered.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 52,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus == 'Completed'
                            ? 'No completed tasks yet'
                            : 'No tasks here 🎉',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TodoCard(
                      todo: filtered[i],
                      onToggle: () => _toggleTodo(filtered[i].id),
                      onEdit: () => _openEditSheet(filtered[i]),
                      onDelete: () => _deleteTodo(filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Task list view (desktop) ──────────────────────────────────────────────────

class _TaskListView extends StatelessWidget {
  final List<TodoItem> todos;
  final bool isEmpty;
  final String filterStatus;
  final String sortBy;
  final void Function(String) onSortChange;
  final Future<void> Function(String) onToggle;
  final Future<void> Function(TodoItem) onEdit;
  final Future<void> Function(TodoItem) onDelete;
  final bool isDark;
  final EdgeInsets padding;

  const _TaskListView({
    required this.todos,
    required this.isEmpty,
    required this.filterStatus,
    required this.sortBy,
    required this.onSortChange,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort row
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            16,
          ),
          child: Row(
            children: [
              Text(
                '${todos.length} task${todos.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                'Sort:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(width: 8),
              ...['Priority', 'Due Date', 'Created'].map((s) {
                final sel = s == sortBy;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => onSortChange(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent
                            : (isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.black.withOpacity(0.06)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sel
                              ? Colors.white
                              : isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 60,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        filterStatus == 'Completed'
                            ? 'No completed tasks'
                            : 'No tasks here 🎉',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    0,
                    padding.right,
                    padding.bottom,
                  ),
                  itemCount: todos.length,
                  itemBuilder: (_, i) => TodoCard(
                    todo: todos[i],
                    onToggle: () => onToggle(todos[i].id),
                    onEdit: () => onEdit(todos[i]),
                    onDelete: () => onDelete(todos[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int pending;
  final int completed;
  final int overdue;
  final int dueToday;
  final bool isDark;

  const _StatsGrid({
    required this.pending,
    required this.completed,
    required this.overdue,
    required this.dueToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _StatTile(
          value: '$pending',
          label: 'Pending',
          color: AppColors.accent,
          isDark: isDark,
        ),
        _StatTile(
          value: '$completed',
          label: 'Done',
          color: const Color(0xFF22C55E),
          isDark: isDark,
        ),
        _StatTile(
          value: '$overdue',
          label: 'Overdue',
          color: const Color(0xFFEF4444),
          isDark: isDark,
        ),
        _StatTile(
          value: '$dueToday',
          label: 'Due Today',
          color: const Color(0xFFFFB347),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar filter tile ───────────────────────────────────────────────────────

class _SidebarFilterTile extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarFilterTile({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? color
                      : isDark
                      ? Colors.white60
                      : Colors.black54,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? color
                      : isDark
                      ? Colors.white38
                      : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile filter bar ─────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String filterCategory;
  final String filterStatus;
  final String sortBy;
  final void Function(String) onCategory;
  final void Function(String) onStatus;
  final void Function(String) onSort;

  const _FilterBar({
    required this.filterCategory,
    required this.filterStatus,
    required this.sortBy,
    required this.onCategory,
    required this.onStatus,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Category scroll
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: ['All', ...TodoCategory.values.map((c) => c.label)].map((
              cat,
            ) {
              final sel = filterCategory == cat;
              final color = cat == 'All'
                  ? AppColors.accent
                  : TodoCategory.values.firstWhere((c) => c.label == cat).color;
              return GestureDetector(
                onTap: () => onCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? color
                        : isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sel
                          ? Colors.white
                          : isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Status + sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Status toggle
              ...['Pending', 'Completed', 'All'].map((s) {
                final sel = filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onStatus(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: sel
                            ? Border.all(
                                color: AppColors.accent.withOpacity(0.4),
                              )
                            : Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sel
                              ? AppColors.accent
                              : isDark
                              ? Colors.white38
                              : Colors.black38,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Sort dropdown
              PopupMenuButton<String>(
                onSelected: onSort,
                itemBuilder: (_) => [
                  'Priority',
                  'Due Date',
                  'Created',
                ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 15,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sortBy,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
