import 'package:flutter/material.dart';

import '../data/fyp_warnings.dart';
import '../extensions/date_helpers.dart';
import '../models/checklist_item.dart';
import '../models/milestone.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Milestone detail bottom sheet: full info, status actions, related
/// preparation checklist and milestone-specific warnings.
class MilestoneDetailSheet extends StatefulWidget {
  final Milestone milestone;
  final List<ChecklistItem> checklist;
  final void Function(MilestoneStatus) onStatusChanged;
  final Future<void> Function(String title) onAddChecklistItem;
  final Future<void> Function(ChecklistItem) onToggleChecklistItem;
  final Future<void> Function(ChecklistItem) onDeleteChecklistItem;

  const MilestoneDetailSheet({
    super.key,
    required this.milestone,
    required this.checklist,
    required this.onStatusChanged,
    required this.onAddChecklistItem,
    required this.onToggleChecklistItem,
    required this.onDeleteChecklistItem,
  });

  @override
  State<MilestoneDetailSheet> createState() => _MilestoneDetailSheetState();
}

class _MilestoneDetailSheetState extends State<MilestoneDetailSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddChecklistItem(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final statusColor = AppColors.milestoneStatusColor(m.status);
    final days = m.deadline.daysFromNow;
    final warningId = warningForMilestone(m.id);
    final warning = warningId == null
        ? null
        : fypWarnings.where((w) => w.id == warningId).firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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

              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  m.status.label,
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.sm),

              Text(m.title, style: AppTypography.headingLarge(context)),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.xs),
                Text(m.description, style: AppTypography.body(context)),
              ],

              // Deadline / portal info rows
              const SizedBox(height: DesignTokens.md),
              _InfoRow(
                icon: Icons.flag_rounded,
                color: AppColors.deadline,
                label: 'Deadline',
                value: m.deadline.formatted,
              ),
              if (m.portalOpenDate != null)
                _InfoRow(
                  icon: Icons.app_registration_rounded,
                  color: AppColors.portalOpening,
                  label: 'Portal opens',
                  value: m.portalOpenDate!.formatted,
                ),
              _InfoRow(
                icon: Icons.timer_outlined,
                color: days < 0
                    ? AppColors.textTertiary(context)
                    : days <= 7
                        ? AppColors.deadline
                        : AppColors.primary,
                label: days < 0 ? 'Passed' : 'Days remaining',
                value: days < 0
                    ? '${-days} days ago'
                    : days == 0
                        ? 'Today!'
                        : '$days day${days == 1 ? '' : 's'}',
              ),

              // Progress bar
              const SizedBox(height: DesignTokens.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: AppTypography.caption(context)),
                  Text(
                    '${(m.percentageComplete * 100).round()}%',
                    style: AppTypography.caption(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.percentageComplete,
                  minHeight: 6,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),

              // Status actions
              const SizedBox(height: DesignTokens.lg),
              Row(
                children: [
                  Expanded(
                    child: _StatusButton(
                      label: 'In Progress',
                      icon: Icons.timelapse_rounded,
                      color: AppColors.statusInProgress,
                      selected: m.status == MilestoneStatus.inProgress,
                      onTap: () {
                        widget.onStatusChanged(MilestoneStatus.inProgress);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusButton(
                      label: 'Submitted',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.statusCompleted,
                      selected: m.status == MilestoneStatus.submitted,
                      onTap: () {
                        widget.onStatusChanged(MilestoneStatus.submitted);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusButton(
                      label: 'Reset',
                      icon: Icons.restart_alt_rounded,
                      color: AppColors.statusNotStarted,
                      selected: m.status == MilestoneStatus.notStarted,
                      onTap: () {
                        widget.onStatusChanged(MilestoneStatus.notStarted);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),

              // Milestone-specific official warning
              if (warning != null) ...[
                const SizedBox(height: DesignTokens.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.priorityHigh.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(
                        color:
                            AppColors.priorityHigh.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(warning.icon,
                          size: 16, color: AppColors.priorityHigh),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(warning.title,
                                style: AppTypography.bodyBold(context)
                                    .copyWith(
                                        color: AppColors.priorityHigh)),
                            const SizedBox(height: 2),
                            Text(warning.message,
                                style: AppTypography.caption(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Preparation checklist
              const SizedBox(height: DesignTokens.lg),
              Text('PREPARATION CHECKLIST',
                  style: AppTypography.overline(context)),
              const SizedBox(height: DesignTokens.sm),

              ...widget.checklist.map((item) => Dismissible(
                    key: Key('check-${item.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                    ),
                    onDismissed: (_) =>
                        widget.onDeleteChecklistItem(item),
                    child: InkWell(
                      onTap: () => widget.onToggleChecklistItem(item),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              item.done
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 20,
                              color: item.done
                                  ? AppColors.statusCompleted
                                  : AppColors.textTertiary(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.body(context)
                                    .copyWith(
                                  decoration: item.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),

              // Add-item input
              const SizedBox(height: DesignTokens.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _add(),
                      style: AppTypography.body(context),
                      decoration: InputDecoration(
                        hintText: 'Add a preparation step…',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.caption(context)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyBold(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Status button ────────────────────────────────────────────────────────────

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: selected ? color : AppColors.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18,
                color: selected ? color : AppColors.textTertiary(context)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    selected ? color : AppColors.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience: open the milestone detail sheet.
Future<void> showMilestoneDetail(
  BuildContext context, {
  required Milestone milestone,
  required List<ChecklistItem> checklist,
  required void Function(MilestoneStatus) onStatusChanged,
  required Future<void> Function(String) onAddChecklistItem,
  required Future<void> Function(ChecklistItem) onToggleChecklistItem,
  required Future<void> Function(ChecklistItem) onDeleteChecklistItem,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MilestoneDetailSheet(
      milestone: milestone,
      checklist: checklist,
      onStatusChanged: onStatusChanged,
      onAddChecklistItem: onAddChecklistItem,
      onToggleChecklistItem: onToggleChecklistItem,
      onDeleteChecklistItem: onDeleteChecklistItem,
    ),
  );
}
