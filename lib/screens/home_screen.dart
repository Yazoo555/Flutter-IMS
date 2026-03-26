import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';
import '../widgets/class_card.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/day_section_header.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  List<ClassSession> _sessions = [];
  bool _loading = true;
  late String _filterDay;

  // Returns 'Sunday', 'Monday', etc. for today
  static String get todayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[DateTime.now().weekday % 7];
  }

  @override
  void initState() {
    super.initState();
    _filterDay = todayName; // ← default to TODAY
    _load();
  }

  Future<void> _load() async {
    final sessions = await _storage.loadSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  // ── Time helpers ─────────────────────────────────────────────────────────

  /// Convert "09:30 AM" → total minutes since midnight
  static int _toMinutes(String t) {
    final parts = t.split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final min = int.parse(hm[1]);
    final isPm = parts[1].toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return hour * 60 + min;
  }

  ClassStatus _getStatus(ClassSession s) {
    if (s.day != todayName) return ClassStatus.upcoming;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = _toMinutes(s.startTime);
    final endMin = _toMinutes(s.endTime);

    if (nowMin >= startMin && nowMin < endMin) return ClassStatus.ongoing;
    if (nowMin >= endMin) return ClassStatus.ended;
    return ClassStatus.upcoming;
  }

  // ── Derived data ─────────────────────────────────────────────────────────

  List<ClassSession> get _filtered {
    if (_filterDay == 'All') return _sessions;
    return _sessions.where((s) => s.day == _filterDay).toList();
  }

  Map<String, List<ClassSession>> get _grouped {
    final map = <String, List<ClassSession>>{};
    for (final day in weekDays) {
      final list = _filtered.where((s) => s.day == day).toList()
        ..sort(
          (a, b) => _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)),
        );
      if (list.isNotEmpty) map[day] = list;
    }
    return map;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> _openAddSheet() async {
    final result = await _showSheet(null);
    if (result != null) {
      await _storage.addSession(result, _sessions);
      await _load();
    }
  }

  Future<void> _openEditSheet(ClassSession session) async {
    final result = await _showSheet(session);
    if (result != null) {
      await _storage.updateSession(result, _sessions);
      await _load();
    }
  }

  Future<ClassSession?> _showSheet(ClassSession? session) {
    return showModalBottomSheet<ClassSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditSheet(session: session),
    );
  }

  Future<void> _deleteSession(ClassSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Remove "${session.subject}" from your routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.deleteSession(session.id, _sessions);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${session.subject} removed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: isDesktop
          ? _DesktopLayout(
              isDark: widget.isDarkMode,
              onToggleTheme: widget.onToggleTheme,
              filterDay: _filterDay,
              onFilterDay: (d) => setState(() => _filterDay = d),
              sessions: _sessions,
              grouped: _grouped,
              getStatus: _getStatus,
              onAdd: _openAddSheet,
              onEdit: _openEditSheet,
              onDelete: _deleteSession,
            )
          : _MobileLayout(
              isDark: widget.isDarkMode,
              onToggleTheme: widget.onToggleTheme,
              filterDay: _filterDay,
              onFilterDay: (d) => setState(() => _filterDay = d),
              sessions: _sessions,
              grouped: _grouped,
              getStatus: _getStatus,
              onAdd: _openAddSheet,
              onEdit: _openEditSheet,
              onDelete: _deleteSession,
              isTablet: isTablet,
            ),
    );
  }
}

// ─── DESKTOP LAYOUT ──────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String filterDay;
  final void Function(String) onFilterDay;
  final List<ClassSession> sessions;
  final Map<String, List<ClassSession>> grouped;
  final ClassStatus Function(ClassSession) getStatus;
  final VoidCallback onAdd;
  final Future<void> Function(ClassSession) onEdit;
  final Future<void> Function(ClassSession) onDelete;

  const _DesktopLayout({
    required this.isDark,
    required this.onToggleTheme,
    required this.filterDay,
    required this.onFilterDay,
    required this.sessions,
    required this.grouped,
    required this.getStatus,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  String get today => _HomeScreenState.todayName;

  @override
  Widget build(BuildContext context) {
    final todaySessions = sessions.where((s) => s.day == today).toList()
      ..sort(
        (a, b) => _HomeScreenState._toMinutes(
          a.startTime,
        ).compareTo(_HomeScreenState._toMinutes(b.startTime)),
      );
    final doneCount = todaySessions
        .where((s) => getStatus(s) == ClassStatus.ended)
        .length;
    final ongoingSession = todaySessions
        .where((s) => getStatus(s) == ClassStatus.ongoing)
        .firstOrNull;

    return Row(
      children: [
        // ── Left sidebar ──────────────────────────────────────────────────
        Container(
          width: 260,
          color: isDark ? const Color(0xFF0F0F18) : const Color(0xFFEEEEF8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'My Routine',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today summary box
                    _SidebarTodaySummary(
                      today: today,
                      total: todaySessions.length,
                      done: doneCount,
                      ongoingSubject: ongoingSession?.subject,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),

              // Day nav
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _SidebarDayTile(
                      label: 'All Days',
                      count: sessions.length,
                      isSelected: filterDay == 'All',
                      isToday: false,
                      onTap: () => onFilterDay('All'),
                      isDark: isDark,
                    ),
                    ...weekDays.map((day) {
                      final count = sessions.where((s) => s.day == day).length;
                      return _SidebarDayTile(
                        label: day,
                        count: count,
                        isSelected: filterDay == day,
                        isToday: day == today,
                        onTap: () => onFilterDay(day),
                        isDark: isDark,
                      );
                    }),
                  ],
                ),
              ),

              // Bottom: theme toggle + add
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ThemeToggle(isDark: isDark, onToggle: onToggleTheme),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────
        Expanded(
          child: _ClassListView(
            grouped: grouped,
            today: today,
            filterDay: filterDay,
            getStatus: getStatus,
            onEdit: onEdit,
            onDelete: onDelete,
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
            showAppBar: false,
            isDark: isDark,
            onToggleTheme: onToggleTheme,
            onAdd: onAdd,
          ),
        ),
      ],
    );
  }
}

// ─── MOBILE LAYOUT ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String filterDay;
  final void Function(String) onFilterDay;
  final List<ClassSession> sessions;
  final Map<String, List<ClassSession>> grouped;
  final ClassStatus Function(ClassSession) getStatus;
  final VoidCallback onAdd;
  final Future<void> Function(ClassSession) onEdit;
  final Future<void> Function(ClassSession) onDelete;
  final bool isTablet;

  const _MobileLayout({
    required this.isDark,
    required this.onToggleTheme,
    required this.filterDay,
    required this.onFilterDay,
    required this.sessions,
    required this.grouped,
    required this.getStatus,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.isTablet,
  });

  String get today => _HomeScreenState.todayName;

  @override
  Widget build(BuildContext context) {
    final todaySessions = sessions.where((s) => s.day == today).toList();
    final doneCount = todaySessions
        .where((s) => getStatus(s) == ClassStatus.ended)
        .length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Class',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            collapsedHeight: 60,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 70, 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Routine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '$today  •  $doneCount/${todaySessions.length} done today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              _ThemeToggle(isDark: isDark, onToggle: onToggleTheme),
              const SizedBox(width: 12),
            ],
          ),

          // Today summary card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                12,
                isTablet ? 24 : 16,
                0,
              ),
              child: _TodayCard(
                today: today,
                totalClasses: todaySessions.length,
                doneCount: doneCount,
                ongoingSession: todaySessions
                    .where((s) => getStatus(s) == ClassStatus.ongoing)
                    .firstOrNull,
                isDark: isDark,
              ),
            ),
          ),

          // Day filter chips
          SliverToBoxAdapter(
            child: _DayFilterBar(
              selected: filterDay,
              onSelect: onFilterDay,
              today: today,
            ),
          ),

          // Class list
          if (grouped.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 52,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No classes on $filterDay',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                0,
                isTablet ? 24 : 16,
                100,
              ),
              sliver: SliverList(
                delegate: _buildDelegate(
                  grouped,
                  today,
                  getStatus,
                  onEdit,
                  onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared list delegate builder ────────────────────────────────────────────

SliverChildBuilderDelegate _buildDelegate(
  Map<String, List<ClassSession>> grouped,
  String today,
  ClassStatus Function(ClassSession) getStatus,
  Future<void> Function(ClassSession) onEdit,
  Future<void> Function(ClassSession) onDelete,
) {
  final days = grouped.keys.toList();
  final totalCount = grouped.values.fold(
    0,
    (sum, list) => sum + list.length + 1,
  );

  return SliverChildBuilderDelegate((_, i) {
    int cursor = 0;
    for (final day in days) {
      final cards = grouped[day]!;
      final total = 1 + cards.length;
      if (i < cursor + total) {
        final localIdx = i - cursor;
        if (localIdx == 0) {
          return DaySectionHeader(
            day: day,
            isToday: day == today,
            classCount: cards.length,
          );
        } else {
          final session = cards[localIdx - 1];
          return ClassCard(
            session: session,
            isToday: day == today,
            status: getStatus(session),
            onEdit: () => onEdit(session),
            onDelete: () => onDelete(session),
          );
        }
      }
      cursor += total;
    }
    return null;
  }, childCount: totalCount);
}

// ─── Desktop class list view (no appbar) ─────────────────────────────────────

class _ClassListView extends StatelessWidget {
  final Map<String, List<ClassSession>> grouped;
  final String today;
  final String filterDay;
  final ClassStatus Function(ClassSession) getStatus;
  final Future<void> Function(ClassSession) onEdit;
  final Future<void> Function(ClassSession) onDelete;
  final EdgeInsets padding;
  final bool showAppBar;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onAdd;

  const _ClassListView({
    required this.grouped,
    required this.today,
    required this.filterDay,
    required this.getStatus,
    required this.onEdit,
    required this.onDelete,
    required this.padding,
    required this.showAppBar,
    required this.isDark,
    required this.onToggleTheme,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 60,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 14),
            Text(
              'No classes on $filterDay',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 17,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: _buildDelegate(
              grouped,
              today,
              getStatus,
              onEdit,
              onDelete,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sidebar day tile ─────────────────────────────────────────────────────────

class _SidebarDayTile extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarDayTile({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.accent.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            if (isToday)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.accent
                      : isToday
                      ? AppColors.accent.withOpacity(0.8)
                      : isDark
                      ? Colors.white60
                      : Colors.black54,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.2)
                      : isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.accent
                        : isDark
                        ? Colors.white38
                        : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar today summary ────────────────────────────────────────────────────

class _SidebarTodaySummary extends StatelessWidget {
  final String today;
  final int total;
  final int done;
  final String? ongoingSubject;
  final bool isDark;

  const _SidebarTodaySummary({
    required this.today,
    required this.total,
    required this.done,
    required this.ongoingSubject,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - done;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                size: 13,
                color: AppColors.accent,
              ),
              const SizedBox(width: 5),
              Text(
                today,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ongoingSubject != null
                ? ongoingSubject!
                : remaining == 0
                ? 'All done! 🎉'
                : '$remaining left today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.accent.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done / $total classes done',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theme toggle ─────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.accent : Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: isDark ? 26 : 2,
              top: 3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mobile today card ────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final String today;
  final int totalClasses;
  final int doneCount;
  final ClassSession? ongoingSession;
  final bool isDark;

  const _TodayCard({
    required this.today,
    required this.totalClasses,
    required this.doneCount,
    required this.ongoingSession,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalClasses - doneCount;
    final progress = totalClasses == 0 ? 0.0 : doneCount / totalClasses;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(
                today,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // If something is ongoing, show a live badge
              if (ongoingSession != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$doneCount / $totalClasses done',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ongoingSession != null
                ? ongoingSession!.subject
                : totalClasses == 0
                ? 'No classes today 🎉'
                : remaining == 0
                ? 'All done for today! 🎉'
                : '$remaining ${remaining == 1 ? 'class' : 'classes'} remaining',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (ongoingSession != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${ongoingSession!.startTime} – ${ongoingSession!.endTime}  •  ${ongoingSession!.room}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day filter chips ─────────────────────────────────────────────────────────

class _DayFilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final String today;

  const _DayFilterBar({
    required this.selected,
    required this.onSelect,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['All', ...weekDays];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = options[i];
          final isSelected = day == selected;
          final isToday = day == today;

          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.accent.withOpacity(0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                day == 'All' ? 'All' : day.substring(0, 3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppColors.accent
                      : isDark
                      ? Colors.white54
                      : Colors.black45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
