import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/milestone.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Card for a milestone: number, status chip, deadline, portal row,
/// countdown and progress bar. Tap to open the detail sheet.
class MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback? onTap;

  /// Optional explicit portal date override (falls back to the milestone's own).
  final DateTime? portalOpenDate;

  /// Optional tracker number (1–9) shown in the leading badge.
  final int? number;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
    this.portalOpenDate,
    this.number,
  });

  String get _deadlineLabel {
    final d = milestone.deadline;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  DateTime? get effectivePortalDate =>
      portalOpenDate ?? milestone.portalOpenDate;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.milestoneStatusColor(milestone.status);
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.sm + 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: DesignTokens.subtle(isDark: isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (number != null) ...[
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: AppTypography.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _StatusChip(status: milestone.status, color: statusColor),
                const Spacer(),
                if (milestone.isConditional)
                  Icon(Icons.link_rounded,
                      size: 14, color: AppColors.textTertiary(context)),
                const SizedBox(width: 6),
                // Countdown chip
                Builder(builder: (context) {
                  final days = milestone.deadline.daysFromNow;
                  final label = days < 0
                      ? 'Passed'
                      : days == 0
                          ? 'Today'
                          : '${days}d';
                  final c = days < 0
                      ? AppColors.textTertiary(context)
                      : days <= 7
                          ? AppColors.deadline
                          : AppColors.primary;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.caption(context).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: c,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Text(milestone.title, style: AppTypography.cardTitle(context)),
            if (milestone.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                milestone.description,
                style: AppTypography.caption(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 13, color: AppColors.textTertiary(context)),
                const SizedBox(width: 5),
                Text(_deadlineLabel, style: AppTypography.caption(context)),
                const Spacer(),
                Text(
                  '${(milestone.percentageComplete * 100).round()}%',
                  style: AppTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            // Portal opening row — the preparation window start.
            if (effectivePortalDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.app_registration_rounded,
                      size: 13, color: AppColors.portalOpening),
                  const SizedBox(width: 5),
                  Text(
                    'Portal opens ${effectivePortalDate!.shortFormatted}',
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.portalOpening,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: milestone.percentageComplete,
                minHeight: 6,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final MilestoneStatus status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption(context).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
