import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

class DesktopScaffold extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final List<Widget> tabs;
  final List<NavigationItem> navigationItems;
  final VoidCallback onLogout;

  const DesktopScaffold({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.tabs,
    required this.navigationItems,
    required this.onLogout,
  });

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Desktop Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                right: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const AppLogo(),
                ),
                const Divider(color: AppTheme.divider, height: 1),
                
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: widget.navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.navigationItems[index];
                      final isSelected = widget.selectedIndex == index;
                      return _buildNavItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: isSelected,
                        onTap: () => widget.onIndexChanged(index),
                      );
                    },
                  ),
                ),
                
                // User Profile Section
                _buildUserProfile(),
                
                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildNavItem(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    isSelected: false,
                    onTap: widget.onLogout,
                    isLogout: true,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: IndexedStack(
              index: widget.selectedIndex,
              children: widget.tabs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout 
        ? AppTheme.errorColor 
        : (isSelected ? AppTheme.primary : AppTheme.textSecondary);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'JD', // Will be dynamic
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Name', // Will be dynamic
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'user@example.com', // Will be dynamic
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  
  const NavigationItem({required this.icon, required this.label});
}