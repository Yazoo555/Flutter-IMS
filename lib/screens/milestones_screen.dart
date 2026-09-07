import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/milestone.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/milestone_card.dart';
import '../widgets/milestone_detail_sheet.dart';

/// Milestone tracker — all official Cohort 11 gates and milestones with
/// status cycling, countdowns, portal rows and preparation checklists.
class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  final _repo = FypRepository();
  List<Milestone> _milestones = [];
  Map<String, List<ChecklistItem>> _checklists = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final milestones = await _repo.loadMilestones();
    final items = await _repo.loadChecklistItems();
    if (!mounted) return;
    setState(() {
      _milestones = milestones;
      _checklists = {
        for (final m in milestones)
          m.id: items.where((i) => i.milestoneId == m.id).toList(),
      };
      _loading = false;
    });
  }

  Future<void> _changeStatus(Milestone m, MilestoneStatus status) async {
    await _repo.saveMilestoneProgress(
      m.id,
      status: status,
      percentageComplete: switch (status) {
        MilestoneStatus.notStarted => 0.0,
        MilestoneStatus.inProgress => 0.5,
        MilestoneStatus.submitted => 1.0,
      },
    );
    await _load();
  }

  Future<void> _openDetail(Milestone m) async {
    await showMilestoneDetail(
      context,
      milestone: m,
      checklist: _checklists[m.id] ?? [],
      onStatusChanged: (status) => _changeStatus(m, status),
      onAddChecklistItem: (title) async {
        await _repo.addChecklistItem(m.id, title);
        await _load();
      },
      onToggleChecklistItem: (item) async {
        await _repo.toggleChecklistItem(item);
        await _load();
      },
      onDeleteChecklistItem: (item) async {
        await _repo.deleteChecklistItem(item);
        await _load();
      },
    );
    // Refresh after the sheet closes (status may have changed).
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final done = _milestones.where((m) => m.isComplete).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, DesignTokens.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Milestones',
                        style: AppTypography.headingLarge(context)),
                    Text(
                      'Official Cohort 11 checkpoints • $done of ${_milestones.length} submitted',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Summary progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:
                  _milestones.isEmpty ? 0 : done / _milestones.length,
              minHeight: 6,
              backgroundColor: AppColors.milestone.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.milestone),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, DesignTokens.xxl,
            ),
            itemCount: _milestones.length,
            itemBuilder: (context, i) {
              final m = _milestones[i];
              return MilestoneCard(
                milestone: m,
                number: i + 1,
                onTap: () => _openDetail(m),
              );
            },
          ),
        ),
      ],
    );
  }
}
