import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_theme.dart';
import 'models/storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/todo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const RoutineApp());
}

class RoutineApp extends StatefulWidget {
  const RoutineApp({super.key});

  @override
  State<RoutineApp> createState() => _RoutineAppState();
}

class _RoutineAppState extends State<RoutineApp> {
  bool _isDark = false;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _storage.loadDarkMode().then((v) => setState(() => _isDark = v));
  }

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
    _storage.saveDarkMode(_isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Routine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: RootShell(isDarkMode: _isDark, onToggleTheme: _toggleTheme),
    );
  }
}

// ── Root shell with bottom nav ────────────────────────────────────────────────

class RootShell extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RootShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    // On desktop: show top tab bar instead of bottom nav
    if (isDesktop) {
      return _DesktopShell(
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
        currentIndex: _currentIndex,
        onTabChange: (i) => setState(() => _currentIndex = i),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(isDarkMode: isDark, onToggleTheme: widget.onToggleTheme),
          TodoScreen(isDarkMode: isDark),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

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
        color: isDark ? const Color(0xFF0F0F18) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.07),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.calendar_today_rounded,
                activeIcon: Icons.calendar_today_rounded,
                label: 'Routine',
                isSelected: currentIndex == 0,
                isDark: isDark,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.checklist_rounded,
                activeIcon: Icons.checklist_rounded,
                label: 'Tasks',
                isSelected: currentIndex == 1,
                isDark: isDark,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? AppColors.accent
                    : isDark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.accent
                    : isDark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop shell with top tabs ───────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final int currentIndex;
  final void Function(int) onTabChange;

  const _DesktopShell({
    required this.isDark,
    required this.onToggleTheme,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top bar with tabs
          Container(
            height: 54,
            color: isDark ? const Color(0xFF0F0F18) : Colors.white,
            child: Row(
              children: [
                const SizedBox(width: 24),
                // App name
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Student Hub',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 32),

                // Tabs
                _TopTab(
                  icon: Icons.calendar_today_rounded,
                  label: 'Routine',
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                  onTap: () => onTabChange(0),
                ),
                const SizedBox(width: 4),
                _TopTab(
                  icon: Icons.checklist_rounded,
                  label: 'Tasks',
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                  onTap: () => onTabChange(1),
                ),

                const Spacer(),

                // Theme toggle
                GestureDetector(
                  onTap: onToggleTheme,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 24),
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.accent
                          : Colors.black.withOpacity(0.12),
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
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                size: 13,
                                color: isDark
                                    ? const Color(0xFF1A1A2E)
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.07),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: [
                HomeScreen(isDarkMode: isDark, onToggleTheme: onToggleTheme),
                TodoScreen(isDarkMode: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TopTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.accent
                    : isDark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
