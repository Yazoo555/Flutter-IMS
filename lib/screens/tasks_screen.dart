import 'package:flutter/material.dart';

import '../models/fyp_task.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';
import '../widgets/task_edit_sheet.dart';

enum _TasksView { list, kanban }

enum _SortMode { dueDate, priority, milestone, status }

/// FYP task manager: List + Kanban views, sorting by due date / priority /
/// milestone / status, and quick-add. Status changes happen via the card's
/// status circle (drag-and-drop is never required).
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repo = FypRepository();
  List<FypTask> _tasks = [];
  bool _loading = true;
  _TasksView _view = _TasksView.list;
  _SortMode _sort = _SortMode.dueDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _repo.loadTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  List<FypTask> get _sorted {
    final list = [..._tasks];
    switch (_sort) {
      case _SortMode.dueDate:
        list.sort((a, b) {
          final ad = a.dueDate, bd = b.dueDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case _SortMode.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case _SortMode.milestone:
        list.sort((a, b) =>
            (a.relatedMilestoneId ?? 'zz').compareTo(b.relatedMilestoneId ?? 'zz'));
      case _SortMode.status:
        list.sort((a, b) => a.status.index.compareTo(b.status.index));
    }
    return list;
  }

  Future<void> _toggleStatus(FypTask task) async {
    final next = switch (task.status) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
    await _repo.updateTask(
      task.copyWith(
        status: next,
        completed: next == TaskStatus.done,
        completedAt: next == TaskStatus.done ? DateTime.now() : null,
        clearCompletedAt: next != TaskStatus.done,
      ),
    );
    await _load();
  }

  Future<void> _delete(FypTask task) async {
    await _repo.deleteTask(task.id);
    await _load();
  }

  Future<void> _addOrEdit([FypTask? task]) async {
    final result = await showTaskEditor(context, task: task);
    if (result == null) return;
    if (task == null) {
      await _repo.addTask(result);
    } else {
      await _repo.updateTask(result);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final open = _tasks.where((t) => !t.isComplete).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOrEdit,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Task',
            style: AppTypography.button(context).copyWith(fontSize: 14)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, DesignTokens.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks', style: AppTypography.pageTitle(context)),
                      Text(
                        '$open open • ${_tasks.length - open} done',
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                // View toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Row(
                    children: [
                      _ViewToggle(
                        icon: Icons.view_list_rounded,
                        selected: _view == _TasksView.list,
                        onTap: () =>
                            setState(() => _view = _TasksView.list),
                      ),
                      _ViewToggle(
                        icon: Icons.view_kanban_rounded,
                        selected: _view == _TasksView.kanban,
                        onTap: () =>
                            setState(() => _view = _TasksView.kanban),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, 0, DesignTokens.lg, DesignTokens.sm,
            ),
            child: Row(
              children: [
                Text('SORT', style: AppTypography.overline(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _SortMode.values.map((s) {
                        final selected = s == _sort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _sort = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusPill),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border(context),
                                ),
                              ),
                              child: Text(
                                switch (s) {
                                  _SortMode.dueDate => 'Due date',
                                  _SortMode.priority => 'Priority',
                                  _SortMode.milestone => 'Milestone',
                                  _SortMode.status => 'Status',
                                },
                                style:
                                    AppTypography.caption(context).copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textTertiary(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _tasks.isEmpty
                ? EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No tasks yet',
                    message: 'Break your FYP into smaller steps.',
                    actionLabel: 'Add Task',
                    onAction: _addOrEdit,
                  )
                : _view == _TasksView.list
                    ? _buildList()
                    : _buildKanban(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final sorted = _sorted;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.lg, 0, DesignTokens.lg, 96,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final task = sorted[i];
        return TaskCard(
          task: task,
          onToggleStatus: () => _toggleStatus(task),
          onDelete: () => _delete(task),
          onTap: () => _addOrEdit(task),
        );
      },
    );
  }

  Widget _buildKanban() {
    final sorted = _sorted;
    Widget column(String title, TaskStatus status, Color color) {
      final tasks = sorted
          .where((t) =>
              t.status == status ||
              (status == TaskStatus.done && t.isComplete))
          .toList();
      return SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.sm),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(title,
                      style: AppTypography.bodyEmphasized(context)
                          .copyWith(color: color)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: AppTypography.caption(context).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(right: DesignTokens.sm),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.border(context)),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          'Nothing here',
                          style: AppTypography.caption(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        return TaskCard(
                          task: task,
                          onToggleStatus: () => _toggleStatus(task),
                          onDelete: () => _delete(task),
                          onTap: () => _addOrEdit(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          column('To Do', TaskStatus.todo, AppColors.statusInProgress),
          const SizedBox(width: DesignTokens.sm),
          column(
              'In Progress', TaskStatus.inProgress, AppColors.priorityHigh),
          const SizedBox(width: DesignTokens.sm),
          column('Done', TaskStatus.done, AppColors.statusCompleted),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Icon(icon,
            size: 18,
            color: selected
                ? AppColors.primary
                : AppColors.textTertiary(context)),
      ),
    );
  }
}
