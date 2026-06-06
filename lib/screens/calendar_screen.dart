import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';
import '../widgets/class_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = StorageService();
  List<ClassSession> _sessions = [];
  bool _loading = true;
  late DateTime _selectedDate;
  late DateTime _weekStart;

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
    _selectedDate = DateTime.now();
    _weekStart = _getDateForDay('Sunday');
    _load();
  }

  DateTime _getDateForDay(String dayName) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final now = DateTime.now();
    final todayIndex = now.weekday % 7;
    final targetIndex = days.indexOf(dayName);
    return now.subtract(Duration(days: todayIndex - targetIndex));
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

  String _dayNameForDate(DateTime date) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    return days[date.weekday % 7];
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  List<ClassSession> get _selectedDaySessions {
    final dayName = _dayNameForDate(_selectedDate);
    return _sessions.where((s) => s.day == dayName).toList()
      ..sort(
          (a, b) => _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final selectedDayName = _dayNameForDate(_selectedDate);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
              const SizedBox(width: 10),
              Text(
                'Calendar',
                style: AppTypography.headingLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),

        // Week navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _previousWeek,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthName(_weekStart.month)} ${_weekStart.day} – ${_monthName(_weekStart.add(const Duration(days: 6)).month)} ${_weekStart.add(const Duration(days: 6)).day}',
                    style: AppTypography.title.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _nextWeek,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Week day selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: weekDays.map((date) {
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final hasClasses = _sessions
                  .any((s) => s.day == _dayNameForDate(date));
              final dayName = _dayNameForDate(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName.substring(0, 2).toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : AppTheme.textTertiary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: AppTypography.title.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasClasses)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Selected day label
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text(
                '$selectedDayName Classes',
                style: AppTypography.headingMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${_selectedDaySessions.length} classes',
                  style: AppTypography.smallBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sessions list
        Expanded(
          child: _selectedDaySessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No classes on $selectedDayName',
                        style: AppTypography.body.copyWith(
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  itemCount: _selectedDaySessions.length,
                  itemBuilder: (context, index) {
                    final session = _selectedDaySessions[index];
                    return ClassCard(
                      session: session,
                      isToday: selectedDayName == todayName,
                      status: _getStatus(session),
                      showActions: false,
                      onEdit: () {},
                      onDelete: () {},
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: index * 50),
                          duration: 250.ms,
                        );
                  },
                ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}
