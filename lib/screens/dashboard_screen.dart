import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';
import '../models/storage_service.dart';
import '../widgets/class_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = StorageService();
  List<ClassSession> _sessions = [];
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final todaySessions = _sessions.where((s) => s.day == todayName).toList()
      ..sort(
          (a, b) => _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)));
    final doneCount =
        todaySessions.where((s) => _getStatus(s) == ClassStatus.ended).length;
    final ongoingSession = todaySessions
        .where((s) => _getStatus(s) == ClassStatus.ongoing)
        .firstOrNull;

    // Stats
    final totalSubjects = _sessions.map((s) => s.subject).toSet().length;
    final totalClasses = _sessions.length;
    final daysWithClasses = _sessions.map((s) => s.day).toSet().length;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Welcome header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: _WelcomeHeader(isDark: isDark),
          ),
        ),

        // Today summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _TodaySummaryCard(
              today: todayName,
              totalClasses: todaySessions.length,
              doneCount: doneCount,
              ongoingSession: ongoingSession,
              isDark: isDark,
            ).animate().fadeIn(duration: 300.ms).slideY(
                  begin: 0.05,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Classes',
                    value: '$totalClasses',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Subjects',
                    value: '$totalSubjects',
                    icon: Icons.category_rounded,
                    color: AppColors.secondary,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Active Days',
                    value: '$daysWithClasses',
                    icon: Icons.date_range_rounded,
                    color: AppColors.accent,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                ),
              ],
            ),
          ),
        ),

        // Streak widget
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _StreakWidget(
              doneToday: doneCount,
              totalToday: todaySessions.length,
              isDark: isDark,
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          ),
        ),

        // Upcoming classes section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                const SizedBox(width: 8),
                Text(
                  "Today's Schedule",
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
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '${todaySessions.length} classes',
                    style: AppTypography.smallBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Schedule list
        if (todaySessions.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: _EmptyDashboard(
                icon: Icons.wb_sunny_outlined,
                message: "No classes today. Enjoy your free day!",
                isDark: isDark,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session = todaySessions[index];
                  return ClassCard(
                    session: session,
                    isToday: true,
                    status: _getStatus(session),
                    showActions: false,
                    onEdit: () {},
                    onDelete: () {},
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 300 + index * 50),
                        duration: 300.ms,
                      );
                },
                childCount: todaySessions.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Welcome Header ──────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final bool isDark;
  const _WelcomeHeader({required this.isDark});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  String get _date {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: AppTypography.displayMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, duration: 300.ms),
        const SizedBox(height: 4),
        Text(
          _date,
          style: AppTypography.body.copyWith(
            color: AppTheme.textTertiary(context),
          ),
        ),
      ],
    );
  }
}

// ── Today Summary Card ──────────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final String today;
  final int totalClasses;
  final int doneCount;
  final ClassSession? ongoingSession;
  final bool isDark;

  const _TodaySummaryCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                style: AppTypography.smallBold.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              if (ongoingSession != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusFull),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$doneCount / $totalClasses done',
                  style: AppTypography.small.copyWith(color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ongoingSession != null
                ? ongoingSession!.subject
                : totalClasses == 0
                    ? 'Free day! 🎉'
                    : remaining == 0
                        ? 'All done for today! 🎉'
                        : '$remaining ${remaining == 1 ? 'class' : 'classes'} remaining',
            style: AppTypography.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (ongoingSession != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${ongoingSession!.startTime} – ${ongoingSession!.endTime}  •  ${ongoingSession!.room}',
                style: AppTypography.small.copyWith(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
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

// ── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppTheme.cardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppTheme.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak Widget ───────────────────────────────────────────────────────────

class _StreakWidget extends StatelessWidget {
  final int doneToday;
  final int totalToday;
  final bool isDark;

  const _StreakWidget({
    required this.doneToday,
    required this.totalToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalToday == 0 ? 0.0 : doneToday / totalToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppTheme.cardShadows(context),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor:
                        AppColors.primary.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.smallBold.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: AppTypography.title.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$doneToday of $totalToday classes completed',
                  style: AppTypography.small.copyWith(
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          if (doneToday == totalToday && totalToday > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                '🔥 Complete',
                style: AppTypography.smallBold.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty Dashboard ─────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyDashboard({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
              icon,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: AppTheme.textTertiary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
