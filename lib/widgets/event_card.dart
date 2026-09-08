import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import 'event_visuals.dart';

/// Card for a single FYP event. Used on Home and Calendar day lists.
/// Shows category chip, countdown/status, multi-day span and completion.
class EventCard extends StatelessWidget {
  final FypEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final Widget? trailing;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onToggleComplete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(event.category);
    final done = event.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: DesignTokens.durationFast,
        opacity: done ? 0.5 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.sm),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: event.isImportant && !done
                  ? color.withValues(alpha: 0.35)
                  : AppColors.border(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(category: event.category),
                    const Spacer(),
                    if (trailing != null) ...[
                      trailing!,
                      const SizedBox(width: 8),
                    ] else ...[
                      _StatusChip(event: event),
                      const SizedBox(width: 8),
                    ],
                    if (onToggleComplete != null)
                      _CheckDot(done: done, onTap: onToggleComplete!),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: AppTypography.bodyEmphasized(context).copyWith(
                    decoration:
                        done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.description,
                    style: AppTypography.caption(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!event.isSingleDay) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 11, color: AppColors.textTertiary(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${event.date.shortFormatted} – ${event.endDate!.shortFormatted}',
                        style: AppTypography.caption(context)
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final FypEventCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EventVisuals.categoryIcon(category), size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: AppTypography.caption(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FypEvent event;
  const _StatusChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _stateInfo(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.captionPrimary(context).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _stateInfo(BuildContext context) {
    if (event.isCompleted) return ('Done', AppColors.statusCompleted);
    if (event.hasEnded) return ('Passed', AppColors.textTertiary(context));
    if (event.isToday) return ('Today', AppColors.deadline);
    final days = event.daysRemaining;
    final color = event.category == FypEventCategory.deadline
        ? (days <= 7 ? AppColors.deadline : AppColors.primary)
        : AppColors.primary;
    return ('$days day${days == 1 ? '' : 's'}', color);
  }
}

class _CheckDot extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _CheckDot({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? AppColors.statusCompleted.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color:
                done ? AppColors.statusCompleted : AppColors.border(context),
            width: 1.5,
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded,
                size: 12, color: AppColors.statusCompleted)
            : null,
      ),
    );
  }
}
