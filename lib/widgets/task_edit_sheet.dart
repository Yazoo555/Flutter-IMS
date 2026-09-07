import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/fyp_task.dart';
import '../models/milestone.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Add / edit a task. Allows linking to an official milestone
/// ("Complete literature review draft" → Milestone 2).
class TaskEditSheet extends StatefulWidget {
  final FypTask? task;

  const TaskEditSheet({super.key, this.task});

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _repo = FypRepository();

  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  TaskCategory _category = TaskCategory.other;
  String? _milestoneId;
  List<Milestone> _milestones = [];

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = t.description;
      _dueDate = t.dueDate;
      _priority = t.priority;
      _status = t.status;
      _category = t.category;
      _milestoneId = t.relatedMilestoneId;
    }
    _repo.loadMilestones().then((list) {
      if (!mounted) return;
      setState(() => _milestones = list);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2026),
      lastDate: DateTime(2028),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }
    final task = FypTask(
      id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      relatedMilestoneId: _milestoneId,
      category: _category,
      completed: _status == TaskStatus.done,
      createdAt: widget.task?.createdAt,
      completedAt: _status == TaskStatus.done
          ? (widget.task?.completedAt ??
              (_isEdit ? DateTime.now() : null))
          : null,
    );
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.lg, DesignTokens.sm, DesignTokens.lg, DesignTokens.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary(context)
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.lg),
              Text(_isEdit ? 'Edit Task' : 'New Task',
                  style: AppTypography.headingLarge(context)),
              const SizedBox(height: DesignTokens.lg),

              // Title
              TextField(
                controller: _titleController,
                autofocus: !_isEdit,
                style: AppTypography.body(context),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.title_rounded, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),

              // Description
              TextField(
                controller: _descController,
                style: AppTypography.body(context),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add details (optional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),

              // Due date
              _PickerTile(
                icon: Icons.event_outlined,
                label: _dueDate == null
                    ? 'Due date (optional)'
                    : 'Due ${_dueDate!.formatted}',
                onTap: _pickDate,
                onClear: _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: DesignTokens.md),

              // Priority
              _Label('PRIORITY'),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskPriority.values.map((p) {
                  final sel = p == _priority;
                  final c = AppColors.taskPriorityColor(p);
                  return GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? c : c.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(
                            color: sel ? c : c.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        p.name.toUpperCase(),
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : c,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.md),

              // Status
              _Label('STATUS'),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskStatus.values.map((s) {
                  final sel = s == _status;
                  final c = AppColors.taskStatusColor(s);
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? c : c.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(
                            color: sel ? c : c.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        switch (s) {
                          TaskStatus.todo => 'TO DO',
                          TaskStatus.inProgress => 'IN PROGRESS',
                          TaskStatus.done => 'DONE',
                        },
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : c,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.md),

              // Category
              _Label('CATEGORY'),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskCategory.values.map((c) {
                  final sel = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        c.label,
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white
                              : AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.md),

              // Related milestone
              _Label('RELATED MILESTONE (OPTIONAL)'),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _milestoneId = null),
                    child: _MilestoneChip(
                      label: 'None',
                      selected: _milestoneId == null,
                    ),
                  ),
                  ..._milestones.map((m) => GestureDetector(
                        onTap: () => setState(() => _milestoneId = m.id),
                        child: _MilestoneChip(
                          label: m.title.split('—').first.trim(),
                          selected: _milestoneId == m.id,
                        ),
                      )),
                ],
              ),

              const SizedBox(height: DesignTokens.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Save Changes' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.overline(context));
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: AppTypography.body(context)),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textTertiary(context)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _MilestoneChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.milestone
            : AppColors.milestone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: selected
              ? AppColors.milestone
              : AppColors.milestone.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

/// Convenience: open the task editor and return the saved task.
Future<FypTask?> showTaskEditor(BuildContext context, {FypTask? task}) {
  return showModalBottomSheet<FypTask>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskEditSheet(task: task),
  );
}
