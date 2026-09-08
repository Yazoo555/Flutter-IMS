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
/// milestone link and priority. Used on Home and Progress screens.
class NextDeadlineCard extends StatelessWidget {
  final FypEvent? event;
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
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined,
                size: 16, color: AppColors.statusCompleted),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: Text(
                urgencyStyle(context, urgency).$1,
                style: AppTypography.caption(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
              : AppTypography.sectionTitle(context),
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
                    size: 12, color: color),
                const SizedBox(width: 4),
                Text(e.category.label, style: AppTypography.caption(context)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppColors.textTertiary(context)),
                const SizedBox(width: 4),
                Text(e.date.formatted, style: AppTypography.caption(context)),
              ],
            ),
            if (milestone != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded,
                      size: 12, color: AppColors.milestone),
                  const SizedBox(width: 4),
                  Text(
                    milestone.title.split('—').first.trim(),
                    style: AppTypography.caption(context)
                        .copyWith(color: AppColors.milestone),
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
              style: AppTypography.countdownColored(
                  urgencyColor, context).copyWith(
                fontSize: compact ? 28 : 36,
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
        padding: EdgeInsets.all(compact ? 14 : 16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
            color: hot
                ? AppColors.deadline.withValues(alpha: 0.5)
                : AppColors.border(context),
            width: hot ? 1.5 : 1,
          ),
        ),
        child: content,
      ),
    );
  }
}
