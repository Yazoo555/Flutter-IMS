import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_theme.dart';
import '../models/class_session.dart';
import '../models/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _storage = StorageService();
  List<ClassSession> _sessions = [];
  bool _loading = true;

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

  Map<String, int> get _subjectDistribution {
    final map = <String, int>{};
    for (final s in _sessions) {
      map[s.subject] = (map[s.subject] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _typeDistribution {
    final map = <String, int>{};
    for (final s in _sessions) {
      map[s.type] = (map[s.type] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _dayDistribution {
    final map = <String, int>{};
    for (final s in _sessions) {
      map[s.day] = (map[s.day] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 20, color: AppTheme.textPrimary(context)),
                const SizedBox(width: 10),
                Text(
                  'Analytics',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Summary cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: _AnalyticsStatCard(
                    label: 'Total Classes',
                    value: '${_sessions.length}',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnalyticsStatCard(
                    label: 'Unique Subjects',
                    value: '${_subjectDistribution.length}',
                    icon: Icons.category_rounded,
                    color: AppColors.secondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnalyticsStatCard(
                    label: 'Active Days',
                    value: '${_dayDistribution.length}',
                    icon: Icons.date_range_rounded,
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),

        // Subject distribution chart
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _ChartCard(
              title: 'Classes by Subject',
              isDark: isDark,
              child: SizedBox(
                height: 200,
                child: _buildSubjectPieChart(isDark),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        ),

        // Weekly schedule chart
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _ChartCard(
              title: 'Weekly Schedule',
              isDark: isDark,
              child: SizedBox(
                height: 200,
                child: _buildWeeklyBarChart(isDark),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ),

        // Type distribution
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _ChartCard(
              title: 'Session Types',
              isDark: isDark,
              child: _buildTypeBreakdown(isDark),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ),

        // Subject details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: _ChartCard(
              title: 'Subject Details',
              isDark: isDark,
              child: Column(
                children: _subjectDistribution.entries.map((e) {
                  final color = AppColors.subjectColor(e.key);
                  final fraction = e.value / _sessions.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: AppTypography.bodyBold.copyWith(
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ),
                            Text(
                              '${e.value} classes',
                              style: AppTypography.small.copyWith(
                                color: AppTheme.textTertiary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
        ),
      ],
    );
  }

  Widget _buildSubjectPieChart(bool isDark) {
    final entries = _subjectDistribution.entries.toList();
    final colors = entries
        .map((e) => AppColors.subjectColor(e.key))
        .toList();

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.body.copyWith(
            color: AppTheme.textTertiary(context),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                return PieChartSectionData(
                  value: entries[i].value.toDouble(),
                  color: colors[i],
                  radius: 24,
                  title: '${entries[i].value}',
                  titleStyle: AppTypography.smallBold.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((e) {
            final color = AppColors.subjectColor(e.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.key.length > 20
                        ? '${e.key.substring(0, 20)}...'
                        : e.key,
                    style: AppTypography.small.copyWith(
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(bool isDark) {
    const dayOrder = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final data = dayOrder
        .map((d) => _dayDistribution[d]?.toDouble() ?? 0)
        .toList();
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal + 1 : 5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < dayOrder.length) {
                  return Text(
                    dayOrder[idx].substring(0, 2),
                    style: AppTypography.caption.copyWith(
                      color: AppTheme.textTertiary(context),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: AppColors.primary,
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTypeBreakdown(bool isDark) {
    final entries = _typeDistribution.entries.toList();

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.body.copyWith(
            color: AppTheme.textTertiary(context),
          ),
        ),
      );
    }

    return Column(
      children: entries.map((e) {
        final color = AppColors.typeColor(e.key);
        final fraction = e.value / _sessions.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(
                  e.key == 'Lecture'
                      ? Icons.cast_rounded
                      : e.key == 'Workshop'
                          ? Icons.build_rounded
                          : e.key == 'Tutorial'
                              ? Icons.question_answer_rounded
                              : Icons.science_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: AppTypography.bodyBold.copyWith(
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${e.value}',
                style: AppTypography.title.copyWith(
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Analytics Stat Card ─────────────────────────────────────────────────────

class _AnalyticsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headingLarge.copyWith(
              color: AppTheme.textPrimary(context),
              fontSize: 20,
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

// ── Chart Card ──────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _ChartCard({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppTheme.cardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
