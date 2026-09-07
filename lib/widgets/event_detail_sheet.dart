import 'package:flutter/material.dart';

import '../data/fyp_calendar_data.dart';
import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import 'event_visuals.dart';

/// Detail bottom sheet for a selected event: title, date, category,
/// priority, description, related milestone, portal/deadline relationship,
/// countdown and completion state.
class EventDetailSheet extends StatelessWidget {
  final FypEvent event;
  final VoidCallback? onToggleComplete;

  const EventDetailSheet({
    super.key,
    required this.event,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(event.category);
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
              // Handle
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

              // Category + priority row
              Row(
                children: [
                  _Chip(
                    icon: EventVisuals.categoryIcon(event.category),
                    label: event.category.label,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.priority_high_rounded,
                    label: EventVisuals.priorityLabel(
                        event.category, event.priority),
                    color: AppColors.priorityColor(event.priority),
                  ),
                  if (event.isConditional) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.link_rounded,
                      label: 'Conditional',
                      color: AppColors.textTertiary(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: DesignTokens.md),

              // Title
              Text(
                event.title,
                style: AppTypography.headingLarge(context).copyWith(
                  decoration: event.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: DesignTokens.sm),

              // Date + week
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textTertiary(context)),
                  const SizedBox(width: 6),
                  Text(
                    event.isSingleDay
                        ? event.date.formatted
                        : '${event.date.formatted} – ${event.endDate!.formatted}',
                    style: AppTypography.body(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Text(
                      event.weekLabel,
                      style: AppTypography.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              // Countdown banner
              if (!event.isSingleDay || event.category != FypEventCategory.holiday)
                _CountdownBanner(event: event),

              // Description
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.md),
                Text(event.description, style: AppTypography.body(context)),
              ],

              // Related milestone
              if (event.relatedMilestoneId != null)
                _RelatedMilestone(event: event),

              // Portal → Deadline relationship
              if (event.category == FypEventCategory.portalOpening &&
                  event.relatedMilestoneId != null)
                _RelationshipStrip(milestoneId: event.relatedMilestoneId!),
              if (event.category == FypEventCategory.deadline &&
                  event.relatedMilestoneId != null)
                _RelationshipStrip(milestoneId: event.relatedMilestoneId!),

              // Notes
              if (event.notes.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(event.notes,
                            style: AppTypography.caption(context)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: DesignTokens.lg),

              // Completion toggle
              if (onToggleComplete != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      onToggleComplete!();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: event.isCompleted
                          ? AppColors.border(context)
                          : color,
                      foregroundColor: event.isCompleted
                          ? AppColors.textSecondary(context)
                          : Colors.white,
                    ),
                    icon: Icon(event.isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_rounded),
                    label: Text(event.isCompleted
                        ? 'Mark as Not Done'
                        : 'Mark as Done'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Countdown banner ─────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final FypEvent event;
  const _CountdownBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(event.category);

    String label;
    Color banner;
    if (event.isCompleted) {
      label = '✓ Completed';
      banner = AppColors.statusCompleted;
    } else if (event.hasEnded) {
      label = 'Passed';
      banner = AppColors.textTertiary(context);
    } else if (event.isToday) {
      label = 'Today!';
      banner = AppColors.deadline;
    } else {
      final days = event.daysRemaining;
      label = '$days day${days == 1 ? '' : 's'} remaining';
      banner = days <= 7 ? AppColors.deadline : color;
    }

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.md),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: banner.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: banner.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: banner),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodyBold(context).copyWith(color: banner),
          ),
        ],
      ),
    );
  }
}

// ── Portal → Preparation → Deadline relationship ─────────────────────────────

class _RelationshipStrip extends StatelessWidget {
  final String milestoneId;
  const _RelationshipStrip({required this.milestoneId});

  @override
  Widget build(BuildContext context) {
    final milestone = FypCalendarData.milestoneById(milestoneId);
    if (milestone == null) return const SizedBox.shrink();
    final portal = milestone.portalOpenDate;
    if (portal == null) return const SizedBox.shrink();

    final portalColor = AppColors.portalOpening;
    final deadlineColor = AppColors.deadline;

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.cardDarkAlt
            : AppColors.surfaceLightAlt,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUBMISSION WINDOW', style: AppTypography.overline(context)),
          const SizedBox(height: 10),
          Row(
            children: [
              _Node(color: portalColor, label: portal.shortFormatted, title: 'Portal opens'),
              _Connector(),
              _Node(
                color: AppColors.primary,
                label:
                    '${milestone.deadline.difference(portal).inDays}d window',
                title: 'Prepare',
              ),
              _Connector(),
              _Node(
                color: deadlineColor,
                label: milestone.deadline.shortFormatted,
                title: 'Deadline',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final Color color;
  final String label;
  final String title;
  const _Node({required this.color, required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(title,
              style:
                  AppTypography.caption(context).copyWith(fontSize: 9)),
          Text(
            label,
            style: AppTypography.caption(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 26),
      color: AppColors.border(context),
    );
  }
}

// ── Related milestone ────────────────────────────────────────────────────────

class _RelatedMilestone extends StatelessWidget {
  final FypEvent event;
  const _RelatedMilestone({required this.event});

  @override
  Widget build(BuildContext context) {
    final milestone = FypCalendarData.milestoneById(event.relatedMilestoneId!);
    if (milestone == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.milestone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.milestone.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 16, color: AppColors.milestone),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RELATED MILESTONE',
                    style: AppTypography.overline(context)
                        .copyWith(fontSize: 9)),
                Text(milestone.title, style: AppTypography.bodyBold(context)),
              ],
            ),
          ),
          if (milestone.portalOpenDate != null)
            Text(
              'Portal: ${milestone.portalOpenDate!.shortFormatted}',
              style: AppTypography.caption(context),
            ),
        ],
      ),
    );
  }
}

// ── Generic chip ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience: show the detail sheet for [event].
Future<void> showEventDetail(BuildContext context, FypEvent event,
    {VoidCallback? onToggleComplete}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EventDetailSheet(
      event: event,
      onToggleComplete: onToggleComplete,
    ),
  );
}
