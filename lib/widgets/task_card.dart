import 'package:flutter/material.dart';

import '../data/fyp_calendar_data.dart';
import '../extensions/date_helpers.dart';
import '../models/fyp_task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Card for a personal FYP task: status circle, due-date urgency,
/// category + milestone chips, priority dot.
class TaskCard extends StatelessWidget {
  final FypTask task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
  });

  (String, Color) _dueInfo(BuildContext context) {
    final due = task.dueDate;
    if (due == null) return ('No due date', AppColors.textTertiary(context));
    final days = due.daysFromNow;
    if (task.isComplete) {
      return ('Due ${due.shortFormatted}', AppColors.textTertiary(context));
    }
    if (days < 0) return ('Overdue ${-days}d', AppColors.error);
    if (days == 0) return ('Due today', AppColors.deadline);
    if (days == 1) return ('Due tomorrow', AppColors.priorityHigh);
    if (days <= 7) return ('In ${days}d', AppColors.priorityHigh);
    return (due.shortFormatted, AppColors.textTertiary(context));
  }

  @override
  Widget build(BuildContext context) {
    final done = task.isComplete;
    final priorityColor = AppColors.taskPriorityColor(task.priority);
    final (dueLabel, dueColor) = _dueInfo(context);
    final milestone = task.relatedMilestoneId == null
        ? null
        : FypCalendarData.milestoneById(task.relatedMilestoneId!);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.sm),
      child: Dismissible(
        key: Key('task-${task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        onDismissed: (_) => onDelete?.call(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: !done && dueLabel.startsWith('Overdue')
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.border(context),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggleStatus,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.statusCompleted.withValues(alpha: 0.12)
                          : task.status == TaskStatus.inProgress
                              ? AppColors.statusInProgress
                                  .withValues(alpha: 0.12)
                              : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? AppColors.statusCompleted
                            : task.status == TaskStatus.inProgress
                                ? AppColors.statusInProgress
                                : AppColors.border(context),
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 12, color: AppColors.statusCompleted)
                        : task.status == TaskStatus.inProgress
                            ? const Icon(Icons.timelapse_rounded,
                                size: 11, color: AppColors.statusInProgress)
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.bodyEmphasized(context).copyWith(
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusPill),
                            ),
                            child:                          Text(
                            task.category.label,
                            style: AppTypography.captionPrimary(context)
                                .copyWith(fontSize: 9),
                          ),
                          ),
                          if (milestone != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.milestone
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusPill),
                              ),
                              child: Text(
                                milestone.title.split('—').first.trim(),
                                style: AppTypography.captionPrimary(context)
                                    .copyWith(
                                        fontSize: 9,
                                        color: AppColors.milestone),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            dueLabel,
                            style: AppTypography.caption(context).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: dueColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
