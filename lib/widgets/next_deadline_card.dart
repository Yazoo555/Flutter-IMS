import 'package:flutter/material.dart';

import '../data/fyp_calendar_data.dart';
import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import 'event_detail_sheet.dart';
import 'event_visuals.dart';

/// Reusable "next important event" card: title, deadline, countdown,
/// milestone link and priority. Used on Home (hero variant) and in the
/// Progress analytics (compact variant) so the pattern stays consistent.
class NextDeadlineCard extends StatelessWidget {
  final FypEvent? event;

  /// Compact mode for secondary placements (analytics).
  final bool compact;
  final VoidCallback? onTap;

  const NextDeadlineCard({
    super.key,
    required this.event,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    if (e == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.md),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined,
                size: 18, color: AppColors.statusCompleted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No deadlines ahead — you are all clear.',
                style: AppTypography.body(context),
              ),
            ),
          ],
        ),
      );
    }

    final color = AppColors.categoryColor(e.category);
    final urgency = urgencyOf(e);
    final hot = urgency == Urgency.today ||
        urgency == Urgency.tomorrow ||
        (e.daysRemaining >= 0 && e.daysRemaining <= 3);
    final milestone =
        e.relatedMilestoneId == null ? null : FypCalendarData.milestoneById(e.relatedMilestoneId!);
    final urgencyColor = hot ? AppColors.deadline : color;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              compact ? 'NEXT DEADLINE' : 'NEXT IMPORTANT EVENT',
              style: AppTypography.overline(context),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: Text(
                urgencyStyle(context, urgency).$1,
                style: AppTypography.caption(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: urgencyColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          e.title,
          style: compact
              ? AppTypography.cardTitle(context)
              : AppTypography.pageTitle(context),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(EventVisuals.categoryIcon(e.category),
                    size: 13, color: color),
                const SizedBox(width: 5),
                Text(e.category.label, style: AppTypography.caption(context)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.textTertiary(context)),
                const SizedBox(width: 5),
                Text(e.date.formatted, style: AppTypography.caption(context)),
              ],
            ),
            if (milestone != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded,
                      size: 13, color: AppColors.milestone),
                  const SizedBox(width: 5),
                  Text(
                    milestone.title.split('—').first.trim(),
                    style: AppTypography.caption(context)
                        .copyWith(color: AppColors.milestone),
                  ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.priorityColor(e.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  EventVisuals.priorityLabel(e.category, e.priority),
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              e.isCompleted
                  ? '✓'
                  : e.hasEnded
                      ? 'Passed'
                      : '${e.daysRemaining}',
              style: AppTypography.displayLarge(context).copyWith(
                fontSize: compact ? 28 : 36,
                color: urgencyColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              e.isCompleted
                  ? 'Completed'
                  : e.hasEnded
                      ? ''
                      : e.daysRemaining == 0
                          ? 'due today'
                          : 'day${e.daysRemaining == 1 ? '' : 's'} remaining',
              style: AppTypography.body(context),
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap ?? () => showEventDetail(context, e),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
            color: hot
                ? AppColors.deadline.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.35),
            width: hot ? 1.6 : 1,
          ),
          boxShadow: hot
              ? DesignTokens.raised(isDark: AppColors.isDark(context))
              : DesignTokens.subtle(isDark: AppColors.isDark(context)),
        ),
        child: content,
      ),
    );
  }
}
