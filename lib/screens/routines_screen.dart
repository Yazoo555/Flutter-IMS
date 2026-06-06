import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';
import '../widgets/class_card.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/day_section_header.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _storage = StorageService();
  List<ClassSession> _sessions = [];
  bool _loading = true;
  late String _filterDay;

  static String get todayName {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    return days[DateTime.now().weekday % 7];
  }

  @override
  void initState() {
    super.initState();
    _filterDay = todayName;
    _load();
  }

  Future<void> _load() async {
    final sessions = await _storage.loadSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

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

  List<ClassSession> get _filtered {
    if (_filterDay == 'All') return _sessions;
    return _sessions.where((s) => s.day == _filterDay).toList();
  }

  Map<String, List<ClassSession>> get _grouped {
    final map = <String, List<ClassSession>>{};
    for (final day in weekDays) {
      final list = _filtered.where((s) => s.day == day).toList()
        ..sort((a, b) =>
            _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)));
      if (list.isNotEmpty) map[day] = list;
    }
    return map;
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<ClassSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditSheet(),
    );
    if (result != null) {
      await _storage.addSession(result, _sessions);
      await _load();
    }
  }

  Future<void> _openEditSheet(ClassSession session) async {
    final result = await showModalBottomSheet<ClassSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditSheet(session: session),
    );
    if (result != null) {
      await _storage.updateSession(result, _sessions);
      await _load();
    }
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Icon(Icons.school_rounded,
                  size: 20,
                  color: AppTheme.textPrimary(context)),
              const SizedBox(width: 10),
              Text(
                'Routines',
                style: AppTypography.headingLarge.copyWith(
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              _AddButton(onTap: _openAddSheet),
            ],
          ),
        ),

        // Day filter chips
        _DayFilterBar(
          selected: _filterDay,
          onSelect: (d) => setState(() => _filterDay = d),
          today: todayName,
        ),

        // Class list
        Expanded(
          child: _grouped.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes on $_filterDay',
                        style: AppTypography.body.copyWith(
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first class',
                        style: AppTypography.small.copyWith(
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: _buildDelegate(
                          _grouped,
                          todayName,
                          _getStatus,
                          _openEditSheet,
                          _deleteSession,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Shared list delegate builder ────────────────────────────────────────────

SliverChildBuilderDelegate _buildDelegate(
  Map<String, List<ClassSession>> grouped,
  String today,
  ClassStatus Function(ClassSession) getStatus,
  Future<void> Function(ClassSession) onEdit,
  Future<void> Function(ClassSession) onDelete,
) {
  final days = grouped.keys.toList();
  final totalCount =
      grouped.values.fold(0, (sum, list) => sum + list.length + 1);

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

// ── Add Button ──────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: DesignTokens.indigoGlow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'Add Class',
              style: AppTypography.smallBold.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Filter Chips ────────────────────────────────────────────────────────

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
    final isDark = AppTheme.isDark(context);
    final options = ['All', ...weekDays];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final day = options[i];
          final isSelected = day == selected;
          final isTodayLabel = day == today;

          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: DesignTokens.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: isTodayLabel && !isSelected
                    ? Border.all(color: AppColors.primary.withOpacity(0.4))
                    : null,
              ),
              child: Text(
                day == 'All' ? 'All' : day.substring(0, 3),
                style: AppTypography.smallBold.copyWith(
                  color: isSelected
                      ? Colors.white
                      : isTodayLabel
                          ? AppColors.primary
                          : AppTheme.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
