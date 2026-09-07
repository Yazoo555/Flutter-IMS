import 'package:flutter/material.dart';

import '../data/fyp_phase_logic.dart';
import '../data/fyp_warnings.dart';
import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../models/milestone.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/event_card.dart';
import '../widgets/event_detail_sheet.dart';
import '../widgets/journey_strip.dart';
import '../widgets/meeting_edit_sheet.dart';
import '../widgets/next_deadline_card.dart';
import '../widgets/section_header.dart';
import '../widgets/task_edit_sheet.dart';

/// Home dashboard — answers "What should I care about right now?" in about
/// five seconds: current phase → next important event → today → progress →
/// upcoming → journey. Includes quick actions (add task / meeting, jump to
/// Calendar / Milestones).
class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = FypRepository();
  List<FypEvent> _events = [];
  List<Milestone> _milestones = [];
  List<FypEvent> _importantUpcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.loadAllEvents(),
      _repo.loadMilestones(),
      _repo.importantUpcoming(limit: 5),
    ]);
    if (!mounted) return;
    setState(() {
      _events = results[0] as List<FypEvent>;
      _milestones = results[1] as List<Milestone>;
      _importantUpcoming = results[2] as List<FypEvent>;
      _loading = false;
    });
  }

  Future<void> _toggleComplete(FypEvent event) async {
    await _repo.toggleEventCompleted(event);
    await _load();
  }

  // ── Derived data (computed from the real clock) ─────────────────────────

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  CurrentPhase? get _phase => currentPhaseFor(DateTime.now());

  /// Next important event: deadline / assessment / milestone-linked,
  /// unfinished, not ended — nearest by date.
  FypEvent? get _nextImportant {
    final candidates = _events
        .where((e) =>
            !e.isCompleted &&
            !e.hasEnded &&
            (e.category == FypEventCategory.deadline ||
                e.category == FypEventCategory.assessment ||
                e.relatedMilestoneId != null))
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.date.compareTo(b.date));
    return candidates.first;
  }

  List<FypEvent> get _todayEvents => _events.where((e) => e.isToday).toList();

  // Milestone progress (all official tracker items).
  int get _milestonesDone =>
      _milestones.where((m) => m.isComplete).length;
  double get _milestonePct =>
      _milestones.isEmpty ? 0 : _milestonesDone / _milestones.length;

  /// Project completion: the student's own progress estimates averaged
  /// across milestones — deliberately distinct from milestone counting.
  double get _projectPct {
    if (_milestones.isEmpty) return 0;
    final sum =
        _milestones.map((m) => m.percentageComplete).reduce((a, b) => a + b);
    return sum / _milestones.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final phase = _phase;
    final next = _nextImportant;
    final warnings = relevantWarningsOn(DateTime.now());

    return CustomScrollView(
      slivers: [
        // ── Greeting ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppTypography.body(context)),
                const SizedBox(height: 2),
                Text('FYP Calendar',
                    style: AppTypography.displayLarge(context)),
                Text('Cohort 11', style: AppTypography.caption(context)),
              ],
            ),
          ),
        ),

        // ── Current phase card ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.lg, DesignTokens.lg, 0,
            ),
            child: _CurrentPhaseCard(phase: phase),
          ),
        ),

        // ── Quick actions ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: _QuickActionsRow(
              onAddTask: () async {
                final task = await showTaskEditor(context);
                if (task != null) await _repo.addTask(task);
              },
              onAddMeeting: () async {
                final meeting = await showMeetingEditor(context);
                if (meeting != null) await _repo.addMeeting(meeting);
              },
              onOpenCalendar: () => widget.onNavigate?.call(1),
              onOpenMilestones: () => widget.onNavigate?.call(2),
            ),
          ),
        ),

        // ── Warnings (contextual, max 2) ──────────────────────────────────
        if (warnings.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
              ),
              child: Column(
                children: warnings
                    .map((w) => _WarningCard(warning: w))
                    .toList(),
              ),
            ),
          ),

        // ── Next important event ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: NextDeadlineCard(event: next),
          ),
        ),

        // ── Today's FYP ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: SectionHeader(
              title: "TODAY'S FYP",
              trailing: Text(
                _todayEvents.isEmpty
                    ? 'Free day'
                    : '${_todayEvents.length} item${_todayEvents.length == 1 ? '' : 's'}',
                style: AppTypography.caption(context),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
            child: _todayEvents.isEmpty
                ? _NoTodayCard()
                : Column(
                    children: _todayEvents
                        .map((e) => EventCard(
                              event: e,
                              onToggleComplete: () => _toggleComplete(e),
                              onTap: () => showEventDetail(
                                context,
                                e,
                                onToggleComplete: () => _toggleComplete(e),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),

        // ── Progress summary ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: _ProgressSummaryCard(
              milestonesDone: _milestonesDone,
              milestonesTotal: _milestones.length,
              milestonePct: _milestonePct,
              projectPct: _projectPct,
            ),
          ),
        ),

        // ── Upcoming important events ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: SectionHeader(title: 'UPCOMING IMPORTANT'),
          ),
        ),
        if (_importantUpcoming.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.lg),
              child: Text(''),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final event = _importantUpcoming[i];
                  return EventCard(
                    event: event,
                    onToggleComplete: () => _toggleComplete(event),
                    onTap: () => showEventDetail(
                      context,
                      event,
                      onToggleComplete: () => _toggleComplete(event),
                    ),
                  );
                },
                childCount: _importantUpcoming.length,
              ),
            ),
          ),

        // ── FYP journey ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: JourneyStrip(
              currentPhaseTitle: phase?.title ?? 'Results',
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

// ── Quick actions row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final Future<void> Function() onAddTask;
  final Future<void> Function() onAddMeeting;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMilestones;

  const _QuickActionsRow({
    required this.onAddTask,
    required this.onAddMeeting,
    required this.onOpenCalendar,
    required this.onOpenMilestones,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_task_rounded,
          label: 'Task',
          color: AppColors.primary,
          tooltip: 'Add a personal FYP task',
          onTap: () => onAddTask(),
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.meeting_room_rounded,
          label: 'Meeting',
          color: AppColors.supervisor,
          tooltip: 'Record a supervisor or project meeting',
          onTap: () => onAddMeeting(),
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.calendar_month_rounded,
          label: 'Calendar',
          color: AppColors.board,
          tooltip: 'View the official FYP calendar',
          onTap: onOpenCalendar,
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.flag_rounded,
          label: 'Milestones',
          color: AppColors.milestone,
          tooltip: 'Track your official milestones',
          onTap: onOpenMilestones,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Current phase card ───────────────────────────────────────────────────────

class _CurrentPhaseCard extends StatelessWidget {
  final CurrentPhase? phase;
  const _CurrentPhaseCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final p = phase;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: DesignTokens.glowShadows(AppColors.primary),
      ),
      child: p == null
          ? Text(
              'FYP journey complete — congratulations! 🎓',
              style: AppTypography.headingMedium(context)
                  .copyWith(color: Colors.white),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text('CURRENT PHASE',
                        style: AppTypography.overline(context)
                            .copyWith(color: Colors.white70)),
                    const Spacer(),
                    Text(
                      weekLabelOf(DateTime.now()),
                      style: AppTypography.caption(context)
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.title,
                  style: AppTypography.headingLarge(context)
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.progressOn(DateTime.now()).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.start.shortFormatted} → ${p.end.shortFormatted} • ${p.daysLeft < 0 ? 'ending' : '${p.daysLeft} days left'}',
                  style: AppTypography.caption(context)
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
    );
  }
}

// ── Warning card ─────────────────────────────────────────────────────────────

class _WarningCard extends StatelessWidget {
  final FypWarning warning;
  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.priorityHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border:
            Border.all(color: AppColors.priorityHigh.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warning.icon, size: 16, color: AppColors.priorityHigh),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: AppTypography.bodyBold(context)
                      .copyWith(color: AppColors.priorityHigh),
                ),
                const SizedBox(height: 2),
                Text(warning.message, style: AppTypography.caption(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── No-today card ────────────────────────────────────────────────────────────

class _NoTodayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 18, color: AppColors.priorityHigh),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No scheduled FYP activities today.',
              style: AppTypography.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress summary card ────────────────────────────────────────────────────

class _ProgressSummaryCard extends StatelessWidget {
  final int milestonesDone;
  final int milestonesTotal;
  final double milestonePct;
  final double projectPct;

  const _ProgressSummaryCard({
    required this.milestonesDone,
    required this.milestonesTotal,
    required this.milestonePct,
    required this.projectPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: DesignTokens.cardShadows(isDark: AppColors.isDark(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FYP PROGRESS', style: AppTypography.overline(context)),
          const SizedBox(height: DesignTokens.md),

          // Milestone completion
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Milestones',
                        style: AppTypography.bodyBold(context)),
                    Text(
                      '$milestonesDone / $milestonesTotal submitted',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
              Text(
                '${(milestonePct * 100).round()}%',
                style: AppTypography.statValue(context)
                    .copyWith(color: AppColors.milestone),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: milestonePct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.milestone.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.milestone),
            ),
          ),

          const SizedBox(height: DesignTokens.md),

          // Project completion (self-estimated) — clearly distinct
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project completion (self-estimated)',
                        style: AppTypography.bodyBold(context)),
                    Text(
                      'Average of your per-milestone progress — not the same '
                      'as milestones submitted',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
              Text(
                '${(projectPct * 100).round()}%',
                style: AppTypography.statValue(context)
                    .copyWith(color: AppColors.session),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: projectPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.session.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.session),
            ),
          ),
        ],
      ),
    );
  }
}
