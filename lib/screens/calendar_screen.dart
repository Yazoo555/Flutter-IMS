import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_card.dart';
import '../widgets/event_detail_sheet.dart';

/// Premium calendar experience: month view, timeline view, category filters
/// and Day/Week/Month scopes, backed by the official Cohort 11 dataset.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _CalView { month, timeline }

enum _Scope { day, week, month }

/// Category filters. `milestones` matches events linked to an official
/// milestone; `portal` covers portal openings and Google Form events.
enum _Filter {
  all('All'),
  deadlines('Deadlines'),
  milestones('Milestones'),
  assessments('Assessments'),
  portal('Portal'),
  sessions('Sessions'),
  supervisor('Supervisor'),
  results('Results'),
  holidays('Holidays');

  final String label;
  const _Filter(this.label);

  bool matches(FypEvent e) => switch (this) {
        _Filter.all => true,
        _Filter.deadlines => e.category == FypEventCategory.deadline,
        _Filter.milestones =>
          e.category == FypEventCategory.milestone ||
              e.relatedMilestoneId != null,
        _Filter.assessments => e.category == FypEventCategory.assessment,
        _Filter.portal =>
          e.category == FypEventCategory.portalOpening ||
              e.category == FypEventCategory.googleForm,
        _Filter.sessions => e.category == FypEventCategory.session,
        _Filter.supervisor => e.category == FypEventCategory.supervisor,
        _Filter.results => e.category == FypEventCategory.board,
        _Filter.holidays => e.category == FypEventCategory.holiday,
      };
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = FypRepository();
  List<FypEvent> _events = [];
  bool _loading = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _visibleMonth = DateTime.now();
  _CalView _view = _CalView.month;
  _Scope _scope = _Scope.day;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _repo.loadAllEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _toggleComplete(FypEvent event) async {
    await _repo.toggleEventCompleted(event);
    await _load();
  }

  // ── Data selectors ────────────────────────────────────────────────────────

  List<FypEvent> get _filteredEvents =>
      _events.where(_filter.matches).toList();

  List<FypEvent> _eventsOn(DateTime day) => _filteredEvents
      .where((e) => e.isOn(day))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<FypEvent> get _scopedEvents {
    final filtered = _filteredEvents;
    switch (_scope) {
      case _Scope.day:
        return filtered.where((e) => e.isOn(_selectedDate)).toList();
      case _Scope.week:
        final start = mondayOf(_selectedDate);
        final end = start.add(const Duration(days: 6));
        return filtered
            .where((e) => e.endDay.isAfter(start) || e.isOn(start))
            .where((e) => e.startDay.isBefore(end.add(const Duration(days: 1))))
            .toList();
      case _Scope.month:
        return filtered
            .where((e) =>
                e.startDay.month == _selectedDate.month &&
                e.startDay.year == _selectedDate.year ||
                (e.endDate != null && e.isOn(_selectedDate)))
            .toList();
    }
  }

  List<FypEvent> get _holidaySpans => _events
      .where((e) =>
          e.category == FypEventCategory.holiday && !e.isSingleDay)
      .toList();

  bool _inHoliday(DateTime day) =>
      _holidaySpans.any((h) => h.isOn(day));

  FypEvent? _holidayFor(DateTime day) {
    for (final h in _holidaySpans) {
      if (h.isOn(day)) return h;
    }
    return null;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month,
          _selectedDate.day.clamp(1, 28));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _Header(
          view: _view,
          onViewChanged: (v) => setState(() => _view = v),
        ),
        Expanded(
          child: _view == _CalView.month ? _buildMonthView() : _buildTimeline(),
        ),
      ],
    );
  }

  // ── Month view ────────────────────────────────────────────────────────────

  Widget _buildMonthView() {
    final selectedEvents = _eventsOn(_selectedDate);
    final holiday = _holidayFor(_selectedDate);

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.lg, DesignTokens.sm, DesignTokens.lg, 0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                  style: AppTypography.pageTitle(context),
                ),
              ),
              _NavBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              const SizedBox(width: DesignTokens.sm),
              _NavBtn(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
        ),

        // Filters
        _FilterBar(
          filter: _filter,
          onFilterChanged: (f) => setState(() => _filter = f),
        ),

        // Weekday labels
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.lg, DesignTokens.md, DesignTokens.lg, DesignTokens.xs,
          ),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppTypography.caption(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
          child: _MonthGrid(
            month: _visibleMonth,
            selectedDate: _selectedDate,
            events: _filteredEvents,
            inHoliday: _inHoliday,
            onSelect: (d) => setState(() {
              _selectedDate = d;
              _visibleMonth = DateTime(d.year, d.month, 1);
            }),
          ),
        ),

        const SizedBox(height: DesignTokens.sm),

        // Day detail header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.lg, DesignTokens.sm, DesignTokens.lg, DesignTokens.sm,
          ),
          child: Row(
            children: [
              Text(
                _selectedDate.day == DateTime.now().day &&
                        _selectedDate.month == DateTime.now().month
                    ? 'Today • ${_selectedDate.shortFormatted}'
                    : _selectedDate.shortFormatted,
                style: AppTypography.cardTitle(context),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  weekLabelOf(_selectedDate),
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                style: AppTypography.caption(context),
              ),
            ],
          ),
        ),

        // Scope selector + day events
        _ScopeBar(
          scope: _scope,
          onScopeChanged: (s) => setState(() => _scope = s),
        ),

        Expanded(
          child: _scopedList(selectedEvents, holiday),
        ),
      ],
    );
  }

  // ── Timeline view ─────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final filtered = _filteredEvents;
    final past =
        filtered.where((e) => e.hasEnded && !e.isToday).toList();
    final current =
        filtered.where((e) => e.isToday && !e.hasEnded).toList();
    final upcoming =
        filtered.where((e) => !e.hasEnded && !e.isToday).toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_rounded,
        title: 'No events match this filter',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.lg, DesignTokens.sm, DesignTokens.lg, DesignTokens.xxl,
      ),
      children: [
        _TimelineSection(
          title: 'CURRENT',
          color: AppColors.deadline,
          events: current,
          onToggle: _toggleComplete,
          emptyNote: 'Nothing happening today.',
        ),
        _TimelineSection(
          title: 'UPCOMING',
          color: AppColors.primary,
          events: upcoming,
          onToggle: _toggleComplete,
          emptyNote: 'Nothing ahead in this filter.',
        ),
        _TimelineSection(
          title: 'PAST',
          color: AppColors.textTertiary(context),
          events: past.reversed.toList(),
          onToggle: _toggleComplete,
          emptyNote: 'Nothing behind you yet.',
        ),
      ],
    );
  }

  /// List for the detail area, honoring the Day / Week / Month scope.
  Widget _scopedList(List<FypEvent> dayEvents, FypEvent? holiday) {
    if (_scope == _Scope.day) {
      return _eventList(dayEvents, holiday: holiday);
    }

    final scoped = _scopedEvents
      ..sort((a, b) => a.date.compareTo(b.date));
    if (scoped.isEmpty) {
      return _eventList(const [], holiday: holiday);
    }

    // Group by calendar day, then render with small date headers.
    final byDay = <DateTime, List<FypEvent>>{};
    for (final e in scoped) {
      byDay.putIfAbsent(e.startDay, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.lg, DesignTokens.xs, DesignTokens.lg, DesignTokens.xxl,
      ),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final events = byDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: DesignTokens.sm, bottom: DesignTokens.xs,
              ),
              child: Row(
                children: [
                  Text(
                    '${day.dayShort} ${day.day} ${day.monthShort}',
                    style: AppTypography.caption(context)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.border(context),
                    ),
                  ),
                ],
              ),
            ),
            ...events.map((e) => EventCard(
                  event: e,
                  onToggleComplete: () => _toggleComplete(e),
                  onTap: () => showEventDetail(
                    context,
                    e,
                    onToggleComplete: () => _toggleComplete(e),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _eventList(List<FypEvent> events, {FypEvent? holiday}) {
    if (events.isEmpty) {
      return EmptyState(
        icon: holiday != null
            ? Icons.beach_access_rounded
            : Icons.event_available_rounded,
        title: holiday != null ? holiday.title : 'Nothing scheduled',
        message: holiday != null
            ? 'This day falls inside an official non-teaching period.'
            : _scope == _Scope.day
                ? 'No FYP events on this day.'
                : 'No events in this range for the selected filter.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.lg, 0, DesignTokens.lg, DesignTokens.xxl,
      ),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final event = events[i];
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
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}

// ── Header with view switch ──────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _CalView view;
  final void Function(_CalView) onViewChanged;

  const _Header({required this.view, required this.onViewChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Calendar', style: AppTypography.pageTitle(context)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Row(
              children: [
                _Toggle(
                  icon: Icons.calendar_month_rounded,
                  label: 'Month',
                  selected: view == _CalView.month,
                  onTap: () => onViewChanged(_CalView.month),
                ),
                _Toggle(
                  icon: Icons.timeline_rounded,
                  label: 'Timeline',
                  selected: view == _CalView.timeline,
                  onTap: () => onViewChanged(_CalView.timeline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd - 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textTertiary(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter filter;
  final void Function(_Filter) onFilterChanged;

  const _FilterBar({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    final filters = _Filter.values;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.lg, vertical: DesignTokens.sm,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = f == filter;
          return GestureDetector(
            onTap: () => onFilterChanged(f),
            child: AnimatedContainer(
              duration: DesignTokens.durationFast,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.isDark(context)
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: Text(
                f.label,
                style: AppTypography.caption(context).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Scope bar (Day / Week / Month) ───────────────────────────────────────────

class _ScopeBar extends StatelessWidget {
  final _Scope scope;
  final void Function(_Scope) onScopeChanged;

  const _ScopeBar({required this.scope, required this.onScopeChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.lg),
      child: Row(
        children: [
          Text('SHOWING', style: AppTypography.overline(context)),
          const SizedBox(width: 10),
          ..._Scope.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onScopeChanged(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s == scope
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      border: Border.all(
                        color: s == scope
                            ? AppColors.primary
                            : AppColors.border(context),
                      ),
                    ),
                    child: Text(
                      switch (s) {
                        _Scope.day => 'Day',
                        _Scope.week => 'Week',
                        _Scope.month => 'Month',
                      },
                      style: AppTypography.caption(context).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: s == scope
                            ? AppColors.primary
                            : AppColors.textTertiary(context),
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Month grid with holiday shading ──────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final List<FypEvent> events;
  final bool Function(DateTime) inHoliday;
  final void Function(DateTime) onSelect;

  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.events,
    required this.inHoliday,
    required this.onSelect,
  });

  /// Up to 2 indicator dots for a day, deadline first.
  List<Color> _dotsFor(DateTime day) {
    final dayEvents = events.where((e) => e.isOn(day)).toList();
    final colors = <Color>[];
    // Deadlines first — impossible to miss.
    for (final e in dayEvents) {
      if (e.category == FypEventCategory.deadline) {
        colors.add(AppColors.deadline);
        break;
      }
    }
    for (final e in dayEvents) {
      final c = AppColors.categoryColor(e.category);
      if (!colors.contains(c)) colors.add(c);
      if (colors.length >= 3) break;
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final cellIndex = r * 7 + c;
            final dayNumber = cellIndex - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            final date = DateTime(month.year, month.month, dayNumber);
            final isSelected = date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final holiday = inHoliday(date);
            final dots = _dotsFor(date);

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(date),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : holiday
                            ? AppColors.holiday.withValues(alpha: 0.10)
                            : isToday
                                ? AppColors.primary.withValues(alpha: 0.10)
                                : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSm + 2),
                    border: isSelected
                        ? null
                        : isToday
                            ? Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4))
                            : holiday
                                ? Border.all(
                                    color: AppColors.holiday
                                        .withValues(alpha: 0.25))
                                : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: AppTypography.bodyEmphasized(context).copyWith(
                          color: isSelected
                              ? Colors.white
                              : holiday
                                  ? AppColors.textTertiary(context)
                                  : AppColors.textPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots
                              .map((c) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : c,
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ── Timeline section ─────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<FypEvent> events;
  final Future<void> Function(FypEvent) onToggle;
  final String emptyNote;

  const _TimelineSection({
    required this.title,
    required this.color,
    required this.events,
    required this.onToggle,
    required this.emptyNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.overline(context)),
            const SizedBox(width: 8),
            Text('${events.length}',
                style: AppTypography.caption(context)),
          ],
        ),
        const SizedBox(height: DesignTokens.md),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
                left: DesignTokens.md, bottom: DesignTokens.lg),
            child: Text(emptyNote, style: AppTypography.caption(context)),
          )
        else ...[
          ...events.map((e) => _TimelineRow(
                event: e,
                isLast: e == events.last,
                onTap: () => showEventDetail(
                  context,
                  e,
                  onToggleComplete: () => onToggle(e),
                ),
              )),
          const SizedBox(height: DesignTokens.lg),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final FypEvent event;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(event.category);

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: event.isCompleted
                          ? AppColors.statusCompleted
                          : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: DesignTokens.sm + 4, left: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(
                    color: event.category == FypEventCategory.deadline
                        ? AppColors.deadline.withValues(alpha: 0.4)
                        : AppColors.border(context),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.isSingleDay
                              ? event.date.formatted
                              : '${event.date.shortFormatted} – ${event.endDate!.shortFormatted}',
                          style: AppTypography.caption(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                DesignTokens.radiusPill),
                          ),
                          child: Text(
                            event.category.label,
                            style: AppTypography.caption(context).copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: AppTypography.bodyEmphasized(context).copyWith(
                        decoration: event.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav button ───────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child:
            Icon(icon, size: 20, color: AppColors.textSecondary(context)),
      ),
    );
  }
}
