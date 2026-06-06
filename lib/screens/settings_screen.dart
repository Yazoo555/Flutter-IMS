import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Icon(Icons.settings_rounded,
                    size: 20, color: AppTheme.textPrimary(context)),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),

        // Appearance section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _SectionHeader(title: 'APPEARANCE', isDark: isDark),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: _SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: AppColors.primary,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Dark mode active' : 'Light mode active',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) => onToggleTheme(),
                      activeThumbColor: AppColors.primary,
                    ),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  _SettingsTile(
                    icon: Icons.palette_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Accent Color',
                    subtitle: 'Deep Indigo',
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        ),

        // Data section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _SectionHeader(title: 'DATA', isDark: isDark),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: _SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.storage_rounded,
                    iconColor: AppColors.accent,
                    title: 'Local Storage',
                    subtitle: 'All data is stored locally on your device',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary(context),
                    ),
                    isDark: isDark,
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  _SettingsTile(
                    icon: Icons.backup_rounded,
                    iconColor: AppColors.success,
                    title: 'Export Data',
                    subtitle: 'Export your routines and tasks',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary(context),
                    ),
                    isDark: isDark,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Export feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ),

        // About section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _SectionHeader(title: 'ABOUT', isDark: isDark),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: _SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.info,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary(context),
                    ),
                    isDark: isDark,
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  _SettingsTile(
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.error,
                    title: 'Student Hub',
                    subtitle: 'Premium routine management for students',
                    trailing: const SizedBox.shrink(),
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ),

        // Footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Center(
              child: Text(
                'Made with ❤️ for productive students',
                style: AppTypography.small.copyWith(
                  color: AppTheme.textTertiary(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.overline.copyWith(
        color: AppTheme.textTertiary(context),
      ),
    );
  }
}

// ── Settings Card ───────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppTheme.cardShadows(context),
      ),
      child: child,
    );
  }
}

// ── Settings Tile ───────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBold.copyWith(
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.small.copyWith(
                      color: AppTheme.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
