import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../setup/units_screen.dart';
import '../setup/categories_screen.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // ── Quick Access Grid ────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              _QuickAccessCard(
                icon: Icons.straighten_rounded,
                label: 'Units',
                description: 'Manage measurement units',
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UnitsScreen()),
                ),
              ),
              // Placeholder cards — replace with real screens as you build them
             _QuickAccessCard(
  icon: Icons.category_rounded,
  label: 'Categories',
  description: 'Item classifications',
  color: const Color(0xFF0EA5E9),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
  ),
),
              _QuickAccessCard(
                icon: Icons.people_alt_rounded,
                label: 'Suppliers',
                description: 'Vendor management',
                color: const Color(0xFF10B981),
                onTap: () {},
              ),
              _QuickAccessCard(
                icon: Icons.location_on_rounded,
                label: 'Locations',
                description: 'Storage locations',
                color: const Color(0xFFF59E0B),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Dashboard placeholder ────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Overview of your inventory at a glance.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Access Card ─────────────────────────────────────────────────────────

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
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
    );
  }
}