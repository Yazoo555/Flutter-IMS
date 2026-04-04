import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive_layout.dart';
import '../widgets/desktop_scaffold.dart';
import 'login_screen.dart';
import 'home_screen.dart' show _DashboardTab, _InventoryTab, _ReportsTab, _SettingsTab;

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _tabs = const [
    _DashboardTab(),
    _InventoryTab(),
    _ReportsTab(),
    _SettingsTab(),
  ];
  
  final List<NavigationItem> _navItems = const [
    NavigationItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    NavigationItem(icon: Icons.inventory_2_rounded, label: 'Inventory'),
    NavigationItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
    NavigationItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    
    if (isDesktop) {
      return DesktopScaffold(
        selectedIndex: _currentIndex,
        onIndexChanged: (index) => setState(() => _currentIndex = index),
        tabs: _tabs,
        navigationItems: _navItems,
        onLogout: _handleLogout,
      );
    }
    
    // Mobile layout (your original HomeScreen logic)
    // You can either duplicate your original code here or refactor it
    return const Placeholder(); // Replace with your original HomeScreen
  }
}