import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'milestones_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const AppShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _destinations = [
    _Destination(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _Destination(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Calendar'),
    _Destination(
        icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Milestones'),
    _Destination(
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle_rounded,
        label: 'Tasks'),
    _Destination(
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        label: 'Progress'),
    _Destination(
        icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= DesignTokens.navRailBreakpoint;

    final screens = [
      HomeScreen(
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
      const CalendarScreen(),
      const MilestonesScreen(),
      const TasksScreen(),
      const ProgressScreen(),
      SettingsScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Wide layout: sidebar; narrow layout: bottom nav handled below.
          if (isWide) ...[
            _Sidebar(
              destinations: _destinations,
              currentIndex: _currentIndex,
              onSelect: (i) => setState(() => _currentIndex = i),
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
            Container(width: 1, color: AppColors.border(context)),
          ],
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _BottomNav(
              destinations: _destinations,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Destination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Sidebar (desktop / tablet) ───────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_Destination> destinations;
  final int currentIndex;
  final void Function(int) onSelect;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const _Sidebar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.isDark(context)
          ? AppColors.surfaceDarkAlt
          : AppColors.surfaceLightAlt,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.board],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd - 2),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FYP Calendar',
                            style: AppTypography.cardTitle(context)),
                        Text('Cohort 11',
                            style: AppTypography.caption(context)
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Destinations
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ...List.generate(destinations.length, (i) {
                      final d = destinations[i];
                      final selected = i == currentIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          child: InkWell(
                            onTap: () => onSelect(i),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    selected ? d.activeIcon : d.icon,
                                    size: 20,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textTertiary(context),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      d.label,
                                      style: AppTypography.body(context)
                                          .copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Theme mode: System / Light / Dark
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Theme', style: AppTypography.caption(context)),
                  const Spacer(),
                  _ThemeOption(
                    icon: Icons.brightness_auto_rounded,
                    tooltip: 'System theme',
                    selected: themeMode == ThemeMode.system,
                    onTap: () => onThemeModeChanged(ThemeMode.system),
                  ),
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    tooltip: 'Light theme',
                    selected: themeMode == ThemeMode.light,
                    onTap: () => onThemeModeChanged(ThemeMode.light),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    tooltip: 'Dark theme',
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => onThemeModeChanged(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border(context),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: selected
                ? AppColors.primary
                : AppColors.textTertiary(context),
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation (mobile) ───────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<_Destination> destinations;
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.surfaceDarkAlt
            : Colors.white,
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(destinations.length, (i) {
              final d = destinations[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusPill),
                        ),
                        child: Icon(
                          selected ? d.activeIcon : d.icon,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textTertiary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.label,
                        style: AppTypography.caption(context).copyWith(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
