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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  CurrentPhase? get _phase => currentPhaseFor(DateTime.now());

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

  int get _milestonesDone =>
      _milestones.where((m) => m.isComplete).length;
  double get _milestonePct =>
      _milestones.isEmpty ? 0 : _milestonesDone / _milestones.length;

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
        // ── Page header ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home', style: AppTypography.pageTitle(context)),
                const SizedBox(height: 2),
                Text(
                  '$_greeting — ${weekLabelOf(DateTime.now())}',
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
        ),

        // ── Current phase ────────────────────────────────────────────────
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

        // ── Warnings ──────────────────────────────────────────────────
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

        // ── Next important event ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, 0,
            ),
            child: NextDeadlineCard(event: next),
          ),
        ),

        // ── Today's FYP ───────────────────────────────────────────────
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
                ? const _NoTodayCard()
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

        // ── Progress summary ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: _ProgressSummary(
              milestonesDone: _milestonesDone,
              milestonesTotal: _milestones.length,
              milestonePct: _milestonePct,
              projectPct: _projectPct,
            ),
          ),
        ),

        // ── Upcoming ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
            ),
            child: SectionHeader(title: 'UPCOMING'),
          ),
        ),
        if (_importantUpcoming.isEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
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

        // ── FYP journey ───────────────────────────────────────────────
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
          label: 'Add task',
          tooltip: 'Add a personal FYP task',
          onTap: () => onAddTask(),
        ),
        const SizedBox(width: 6),
        _QuickAction(
          icon: Icons.meeting_room_rounded,
          label: 'Add meeting',
          tooltip: 'Record a supervisor or project meeting',
          onTap: () => onAddMeeting(),
        ),
        const SizedBox(width: 6),
        _QuickAction(
          icon: Icons.calendar_month_rounded,
          label: 'Calendar',
          tooltip: 'View the official FYP calendar',
          onTap: onOpenCalendar,
        ),
        const SizedBox(width: 6),
        _QuickAction(
          icon: Icons.flag_rounded,
          label: 'Milestones',
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
  final VoidCallback onTap;
  final String tooltip;

  const _QuickAction({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.captionPrimary(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: p == null
          ? Text(
              'FYP journey complete',
              style: AppTypography.cardTitle(context)
                  .copyWith(color: Colors.white),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore_rounded,
                        size: 13, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text('CURRENT PHASE',
                        style: AppTypography.overlinePrimary(context)
                            .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                    const Spacer(),
                    Text(
                      weekLabelOf(DateTime.now()),
                      style: AppTypography.captionPrimary(context)
                          .copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.title,
                  style: AppTypography.sectionTitle(context)
                      .copyWith(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.progressOn(DateTime.now()).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.start.shortFormatted} → ${p.end.shortFormatted} • ${p.daysLeft < 0 ? 'ending' : '${p.daysLeft} days left'}',
                  style: AppTypography.captionPrimary(context)
                      .copyWith(color: Colors.white.withValues(alpha: 0.75)),
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
        color: AppColors.priorityHigh.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
            color: AppColors.priorityHigh.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warning.icon, size: 15, color: AppColors.priorityHigh),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: AppTypography.bodyEmphasized(context)
                      .copyWith(color: AppColors.priorityHigh),
                ),
                const SizedBox(height: 2),
                Text(warning.message, style: AppTypography.captionPrimary(context)),
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
  const _NoTodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 16, color: AppColors.textTertiary(context)),
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

// ── Progress summary ────────────────────────────────────────────────────────

class _ProgressSummary extends StatelessWidget {
  final int milestonesDone;
  final int milestonesTotal;
  final double milestonePct;
  final double projectPct;

  const _ProgressSummary({
    required this.milestonesDone,
    required this.milestonesTotal,
    required this.milestonePct,
    required this.projectPct,
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
                        style: AppTypography.bodyEmphasized(context)),
                    Text(
                      '$milestonesDone / $milestonesTotal submitted',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
              Text(
                '${(milestonePct * 100).round()}%',
                style: AppTypography.statValueColored(AppColors.milestone, context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: milestonePct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.milestone.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.milestone),
            ),
          ),

          const SizedBox(height: DesignTokens.md),

          // Project completion (self-estimated)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project completion (self-estimated)',
                        style: AppTypography.bodyEmphasized(context)),
                    Text(
                      'Average of your per-milestone progress',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
              Text(
                '${(projectPct * 100).round()}%',
                style: AppTypography.statValueColored(AppColors.session, context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: projectPct.clamp(0.0, 1.0),
              minHeight: 4,
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
