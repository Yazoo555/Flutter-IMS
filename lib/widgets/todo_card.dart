import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isOverdue =>
      !todo.isCompleted &&
      todo.dueDate != null &&
      todo.dueDate!.isBefore(DateTime.now());

  bool get _isDueToday {
    if (todo.dueDate == null || todo.isCompleted) return false;
    final now = DateTime.now();
    final d = todo.dueDate!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDue() {
    if (todo.dueDate == null) return '';
    final d = todo.dueDate!;
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff == -1) return 'Due yesterday';
    if (diff < 0) return 'Overdue ${-diff}d';
    if (diff < 7) return 'Due in ${diff}d';
    return 'Due ${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = todo.category;
    final pri = todo.priority;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? (isDark
                  ? const Color(0xFF1A1A2E).withOpacity(0.5)
                  : Colors.white.withOpacity(0.6))
            : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: _isOverdue
            ? Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.4),
                width: 1.5,
              )
            : _isDueToday
            ? Border.all(
                color: const Color(0xFFFFB347).withOpacity(0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: todo.isCompleted
                    ? cat.color.withOpacity(0.3)
                    : cat.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: todo.isCompleted ? cat.color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.isCompleted
                          ? cat.color
                          : isDark
                          ? Colors.white30
                          : Colors.black26,
                      width: 1.8,
                    ),
                  ),
                  child: todo.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: todo.isCompleted
                                  ? (isDark ? Colors.white30 : Colors.black38)
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E)),
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: isDark
                                  ? Colors.white30
                                  : Colors.black38,
                            ),
                          ),
                        ),
                        // Priority badge
                        if (!todo.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pri.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(pri.icon, size: 10, color: pri.color),
                                const SizedBox(width: 3),
                                Text(
                                  pri.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: pri.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Description
                    if (todo.description != null &&
                        todo.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 7),

                    // Meta row: category + subject + due
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Category chip
                        _MetaChip(
                          icon: cat.icon,
                          label: cat.label,
                          color: cat.color,
                        ),

                        // Subject chip
                        if (todo.subject != null)
                          _MetaChip(
                            icon: Icons.book_outlined,
                            label: todo.subject!,
                            color: isDark ? Colors.white24 : Colors.black12,
                            textColor: isDark ? Colors.white54 : Colors.black45,
                          ),

                        // Due date chip
                        if (todo.dueDate != null)
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            label: _formatDue(),
                            color: _isOverdue
                                ? const Color(0xFFEF4444).withOpacity(0.15)
                                : _isDueToday
                                ? const Color(0xFFFFB347).withOpacity(0.15)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.black.withOpacity(0.05)),
                            textColor: _isOverdue
                                ? const Color(0xFFEF4444)
                                : _isDueToday
                                ? const Color(0xFFFFB347)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF6C63FF),
                  onTap: onEdit,
                ),
                const SizedBox(height: 4),
                _MiniBtn(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF6D6D),
                  onTap: onDelete,
                ),
              ],
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: tc),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tc,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
