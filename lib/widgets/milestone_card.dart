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
  final DateTime? portalOpenDate;
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.sm),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (number != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: AppTypography.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
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
                      size: 13, color: AppColors.textTertiary(context)),
                const SizedBox(width: 4),
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
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.caption(context).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(milestone.title, style: AppTypography.bodyEmphasized(context)),
            if (milestone.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                milestone.description,
                style: AppTypography.caption(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 12, color: AppColors.textTertiary(context)),
                const SizedBox(width: 4),
                Text(_deadlineLabel, style: AppTypography.caption(context)),
                const Spacer(),
                Text(
                  '${(milestone.percentageComplete * 100).round()}%',
                  style: AppTypography.captionPrimary(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (effectivePortalDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.app_registration_rounded,
                      size: 12, color: AppColors.portalOpening),
                  const SizedBox(width: 4),
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
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: milestone.percentageComplete,
                minHeight: 4,
                backgroundColor: statusColor.withValues(alpha: 0.10),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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
