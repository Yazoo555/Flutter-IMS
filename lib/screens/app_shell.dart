import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/routines_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AppShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _DesktopShell(
        isDark: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        currentIndex: _currentIndex,
        onTabChange: (i) => setState(() => _currentIndex = i),
        collapsed: _sidebarCollapsed,
        onToggleCollapse: () =>
            setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      );
    }

    return _MobileShell(
      isDark: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      currentIndex: _currentIndex,
      onTabChange: (i) => setState(() => _currentIndex = i),
    );
  }
}

// ── Navigation Items ────────────────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<NavItem> _navItems = [
  NavItem(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label: 'Dashboard',
  ),
  NavItem(
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today_rounded,
    label: 'Calendar',
  ),
  NavItem(
    icon: Icons.school_outlined,
    activeIcon: Icons.school_rounded,
    label: 'Routines',
  ),
  NavItem(
    icon: Icons.check_circle_outline,
    activeIcon: Icons.check_circle_rounded,
    label: 'Tasks',
  ),
  NavItem(
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    label: 'Analytics',
  ),
  NavItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

// ── Desktop Shell ───────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final int currentIndex;
  final void Function(int) onTabChange;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const _DesktopShell({
    required this.isDark,
    required this.onToggleTheme,
    required this.currentIndex,
    required this.onTabChange,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            isDark: isDark,
            onToggleTheme: onToggleTheme,
            currentIndex: currentIndex,
            onTabChange: onTabChange,
            collapsed: collapsed,
            onToggleCollapse: onToggleCollapse,
          ),

          // Divider
          Container(
            width: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: [
                const DashboardScreen(),
                const CalendarScreen(),
                const RoutinesScreen(),
                const TasksScreen(),
                const AnalyticsScreen(),
                SettingsScreen(onToggleTheme: onToggleTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final int currentIndex;
  final void Function(int) onTabChange;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const _Sidebar({
    required this.isDark,
    required this.onToggleTheme,
    required this.currentIndex,
    required this.onTabChange,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = collapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      curve: Curves.easeOut,
      width: sidebarWidth,
      color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceLightAlt,
      child: Column(
        children: [
          // Logo + collapse toggle
          Container(
            padding: EdgeInsets.fromLTRB(
              collapsed ? 18 : 24,
              36,
              collapsed ? 18 : 16,
              20,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Student Hub',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleCollapse,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
                if (collapsed)
                  GestureDetector(
                    onTap: onToggleCollapse,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 10 : 14,
              ),
              child: Column(
                children: [
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text(
                        'NAVIGATION',
                        style: AppTypography.overline.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ...List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isSelected = currentIndex == i;
                    return _SidebarTile(
                      item: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      collapsed: collapsed,
                      onTap: () => onTabChange(i),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom actions
          Padding(
            padding: EdgeInsets.fromLTRB(
              collapsed ? 10 : 14,
              0,
              collapsed ? 10 : 14,
              20,
            ),
            child: Column(
              children: [
                _ThemeToggle(isDark: isDark, onToggle: onToggleTheme),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Tile ────────────────────────────────────────────────────────────

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool isDark;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return collapsed
        ? Tooltip(
            message: item.label,
            child: _buildTile(isDark),
          )
        : _buildTile(isDark);
  }

  Widget _buildTile(bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.25))
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.small.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Theme Toggle ─────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: DesignTokens.durationSlow,
        curve: Curves.easeOut,
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isDark ? null : AppColors.borderLight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: DesignTokens.durationNormal,
              curve: Curves.easeOutBack,
              left: isDark ? 24 : 2,
              top: 2,
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: DesignTokens.durationFast,
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      key: ValueKey(isDark),
                      size: 13,
                      color: isDark
                          ? const Color(0xFF4F46E5)
                          : AppColors.warning,
                    ),
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

// ── Mobile Shell ────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final int currentIndex;
  final void Function(int) onTabChange;

  const _MobileShell({
    required this.isDark,
    required this.onToggleTheme,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          const DashboardScreen(),
          const CalendarScreen(),
          const RoutinesScreen(),
          const TasksScreen(),
          const AnalyticsScreen(),
          SettingsScreen(onToggleTheme: onToggleTheme),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: onTabChange,
      ),
    );
  }
}

// ── Bottom Navigation ───────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkAlt : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
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
