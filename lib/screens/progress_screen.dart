import 'package:flutter/material.dart';

import '../data/deadline_health.dart';
import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../models/project_progress.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/next_deadline_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/section_header.dart';

/// Progress screen — the student-controlled estimation layer.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repo = FypRepository();
  List<FypEvent> _events = [];
  ProjectProgress _progress = ProjectProgress();
  ({int done, int total}) _milestoneStats = (done: 0, total: 0);
  ({int done, int total, int overdue}) _taskStats =
      (done: 0, total: 0, overdue: 0);
  DeadlineHealth _health = const DeadlineHealth(
    status: DeadlineHealthStatus.onTrack,
    upcomingCount: 0,
    overdueCount: 0,
    completedCount: 0,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.loadAllEvents(),
      _repo.loadProjectProgress(),
      _repo.milestoneStats(),
      _repo.taskStats(),
    ]);
    if (!mounted) return;
    setState(() {
      _events = results[0] as List<FypEvent>;
      _progress = results[1] as ProjectProgress;
      final ms = results[2] as (int, int, double);
      _milestoneStats = (done: ms.$1, total: ms.$2);
      final ts = results[3] as (int, int, int);
      _taskStats = (done: ts.$1, total: ts.$2, overdue: ts.$3);
      _health = computeDeadlineHealth(_events);
      _loading = false;
    });
  }

  Future<void> _saveProgress(ProjectProgress p) async {
    setState(() => _progress = p);
    await _repo.saveProjectProgress(p);
  }

  FypEvent? get _nextDeadline {
    final candidates = _events
        .where((e) =>
            !e.isCompleted &&
            !e.hasEnded &&
            (e.category == FypEventCategory.deadline ||
                e.category == FypEventCategory.assessment))
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.date.compareTo(b.date));
    return candidates.first;
  }

  double get _timelineProgress {
    final now = DateTime.now();
    if (now.isBefore(fypTimelineStart)) return 0;
    if (now.isAfter(fypTimelineEnd)) return 1;
    final total = fypTimelineEnd.difference(fypTimelineStart).inMinutes;
    final elapsed = now.difference(fypTimelineStart).inMinutes;
    return elapsed / total;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timelinePct = (_timelineProgress * 100).round();
    final overall = _progress.overallPercent;
    final defense = _progress.defenseStatus();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, DesignTokens.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: AppTypography.pageTitle(context)),
                Text(
                  'Self-reported — you control these numbers',
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
        ),

        // Timeline position
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
            child: ProgressCard(
              title: 'FYP Timeline',
              detail:
                  'Official calendar position • ${_events.where((e) => e.isCompleted).length} of ${_events.length} events marked done',
              value: _timelineProgress,
              centerLabel: '$timelinePct%',
              color: AppColors.primary,
            ),
          ),
        ),

        // Analytics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: SectionHeader(title: 'ANALYTICS'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
            child: _StatsGrid(
              milestoneStats: _milestoneStats,
              taskStats: _taskStats,
              health: _health,
            ),
          ),
        ),

        // Next deadline
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: NextDeadlineCard(
              event: _nextDeadline,
              compact: true,
            ),
          ),
        ),

        // Self-reported overall
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: _OverallProgressCard(
              percent: overall,
              updatedAt: _progress.updatedAt,
              onChanged: (v) => _saveProgress(
                _progress.copyWith(overallPercent: v),
              ),
            ),
          ),
        ),

        // Defense target
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: _DefenseTargetCard(
              current: overall,
              status: defense,
            ),
          ),
        ),

        // Breakdown
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: SectionHeader(title: 'AREA BREAKDOWN'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
            child: _BreakdownCard(
              breakdown: _progress.breakdown,
              onChanged: (key, v) {
                final bd = {..._progress.breakdown, key: v};
                _saveProgress(_progress.copyWith(breakdown: bd));
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: DesignTokens.xxl),
        ),
      ],
    );
  }
}

// ── Stats grid ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final ({int done, int total}) milestoneStats;
  final ({int done, int total, int overdue}) taskStats;
  final DeadlineHealth health;

  const _StatsGrid({
    required this.milestoneStats,
    required this.taskStats,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final milestonesRemaining = milestoneStats.total - milestoneStats.done;
    return Column(
      children: [
        Row(
          children: [
            _StatTile(
              icon: Icons.flag_rounded,
              value: '${milestoneStats.done}/${milestoneStats.total}',
              label: 'Milestones done',
              tooltip: 'Official milestones marked Submitted',
              color: AppColors.milestone,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.flag_outlined,
              value: '$milestonesRemaining',
              label: 'Milestones left',
              tooltip: 'Official milestones not yet Submitted',
              color: AppColors.textTertiary(context).withValues(alpha: 0.7),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatTile(
              icon: Icons.check_circle_rounded,
              value: '${taskStats.done}/${taskStats.total}',
              label: 'Tasks done',
              tooltip: 'Your personal FYP tasks marked Done',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.error_outline_rounded,
              value: '${taskStats.overdue}',
              label: 'Overdue tasks',
              tooltip: 'Personal tasks past their due date and not done',
              color: taskStats.overdue > 0
                  ? AppColors.deadline
                  : AppColors.textTertiary(context).withValues(alpha: 0.7),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatTile(
              icon: Icons.event_available_rounded,
              value: '${health.upcomingCount}',
              label: 'Upcoming events',
              tooltip: 'Official events still ahead of you',
              color: AppColors.priorityHigh,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.favorite_rounded,
              value: health.labelAndHint.$1,
              label: 'Deadline health',
              tooltip: health.labelAndHint.$2,
              color: switch (health.status) {
                DeadlineHealthStatus.onTrack => AppColors.session,
                DeadlineHealthStatus.needsAttention => AppColors.priorityHigh,
                DeadlineHealthStatus.overdue => AppColors.deadline,
              },
              smallValue: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String tooltip;
  final Color color;
  final bool smallValue;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tooltip,
    required this.color,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: smallValue
                      ? AppTypography.cardTitle(context)
                          .copyWith(color: color)
                      : AppTypography.statValueColored(color, context),
                ),
              ),
              Text(
                label,
                style: AppTypography.caption(context).copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overall self-reported progress ───────────────────────────────────────────

class _OverallProgressCard extends StatelessWidget {
  final int percent;
  final DateTime updatedAt;
  final void Function(int) onChanged;

  const _OverallProgressCard({
    required this.percent,
    required this.updatedAt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('OVERALL PROJECT COMPLETION',
                  style: AppTypography.overline(context)),
              const Spacer(),
              Text(
                'Self-reported',
                style: AppTypography.caption(context).copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$percent',
                style: AppTypography.countdownColored(
                    AppColors.session, context).copyWith(
                    fontSize: 40,
                    height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text('%',
                  style: AppTypography.sectionTitle(context)
                      .copyWith(color: AppColors.session)),
              const Spacer(),
              Text(
                'Updated ${updatedAt.shortFormatted}',
                style: AppTypography.caption(context),
              ),
            ],
          ),
          Slider(
            value: percent.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: AppColors.session,
            label: '$percent%',
            onChanged: (v) => onChanged(v.round()),
          ),
          Text(
            'Your own estimate of how complete the whole project is.',
            style: AppTypography.caption(context),
          ),
        ],
      ),
    );
  }
}

// ── Defense target card ──────────────────────────────────────────────────────

class _DefenseTargetCard extends StatelessWidget {
  final int current;
  final ({String label, bool onTrack}) status;

  const _DefenseTargetCard({required this.current, required this.status});

  @override
  Widget build(BuildContext context) {
    final targetColor =
        status.onTrack ? AppColors.statusCompleted : AppColors.priorityHigh;
    final targetPct = kDefenseTargetPercent / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: targetColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 15, color: targetColor),
              const SizedBox(width: 8),
              Text('INTERNAL DEFENSE TARGET',
                  style: AppTypography.overline(context)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: targetColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  status.label,
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: targetColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.md),
          Row(
            children: [
              Text('Current: $current%',
                  style: AppTypography.bodyEmphasized(context)),
              const Spacer(),
              Text(
                'Target: $kDefenseTargetPercent%',
                style: AppTypography.bodyEmphasized(context)
                    .copyWith(color: targetColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (current / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        AppColors.session.withValues(alpha: 0.10),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(targetColor),
                  ),
                ),
                Positioned(
                  left: (w * targetPct).clamp(0.0, w - 2),
                  top: 0,
                  child: Container(
                    width: 2,
                    height: 8,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Text(
            'The Internal Project Defense (18–23 Apr 2027) requires '
            'at least 75% completion.',
            style: AppTypography.caption(context),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown card ───────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final Map<String, int> breakdown;
  final void Function(String key, int value) onChanged;

  const _BreakdownCard({required this.breakdown, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('STUDENT-ENTERED ESTIMATES',
                  style: AppTypography.overline(context)),
              const Spacer(),
              Icon(Icons.edit_note_rounded,
                  size: 15, color: AppColors.textTertiary(context)),
            ],
          ),
          const SizedBox(height: DesignTokens.xs),
          Text(
            'Optional per-area estimates. Only you see these.',
            style: AppTypography.caption(context),
          ),
          const SizedBox(height: DesignTokens.sm),
          ...kProgressBreakdownKeys.map((key) {
            final value = breakdown[key] ?? 0;
            return Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    key.breakdownLabel,
                    style: AppTypography.body(context),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    label: '$value%',
                    onChanged: (v) => onChanged(key, v.round()),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '$value%',
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyEmphasized(context)
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
