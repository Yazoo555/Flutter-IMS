import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../extensions/date_helpers.dart';
import '../models/project_info.dart';
import '../services/fyp_repository.dart';
import '../services/reminder_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Settings — Appearance, Notifications, Project, Data, About.
class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = FypRepository();
  final _storage = StorageService();
  final _reminderService = ReminderService();

  ProjectInfo _info = const ProjectInfo();
  bool _notifEnabled = true;
  bool _notifDeadlines = true;
  bool _notifPortals = true;
  bool _notifMeetings = true;
  List<ReminderPlan> _reminderPreview = [];
  bool _loaded = false;

  // Text controllers for the Project section.
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  final _readerCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _supervisorCtrl.dispose();
    _readerCtrl.dispose();
    _teamCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final info = await _repo.loadProjectInfo() ?? const ProjectInfo();
    final results = await Future.wait([
      _storage.loadNotifEnabled(),
      _storage.loadNotifDeadlines(),
      _storage.loadNotifPortals(),
      _storage.loadNotifMeetings(),
    ]);
    final events = await _repo.loadAllEvents();
    final meetings = await _repo.loadMeetings();
    final preview = await _reminderService.upcomingPreview(
      events: events,
      meetings: meetings,
    );
    if (!mounted) return;
    setState(() {
      _info = info;
      _titleCtrl.text = info.title;
      _descCtrl.text = info.description;
      _supervisorCtrl.text = info.supervisorName;
      _readerCtrl.text = info.readerName;
      _teamCtrl.text = info.teamMembers;
      _notifEnabled = results[0];
      _notifDeadlines = results[1];
      _notifPortals = results[2];
      _notifMeetings = results[3];
      _reminderPreview = preview;
      _loaded = true;
    });
  }

  Future<void> _saveProject() async {
    final info = ProjectInfo(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      studentName: _info.studentName,
      supervisorName: _supervisorCtrl.text.trim(),
      readerName: _readerCtrl.text.trim(),
      teamMembers: _teamCtrl.text.trim(),
    );
    await _repo.saveProjectInfo(info);
    setState(() => _info = info);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Project info saved'),
          backgroundColor: AppColors.cardDarkAlt,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    final summary = await _repo.exportSummary();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Export'),
        content: Text(
          'Local data snapshot:\n\n'
          '${summary.entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n\n'
          'All data lives on this device (SharedPreferences). Copy or '
          'integrate a JSON export here when a backend is ever added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This removes all locally saved progress: completed events, '
          'milestone status, tasks, meetings, checklists and project '
          'info. Official FYP dates are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.resetUserState();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Local data cleared'),
            backgroundColor: AppColors.cardDarkAlt,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, DesignTokens.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: AppTypography.headingLarge(context)),
                Text('Make the app yours',
                    style: AppTypography.caption(context)),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),

        // ── APPEARANCE ────────────────────────────────────────────────────
        _Section('APPEARANCE', [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Theme',
                    style: AppTypography.bodyBold(context)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.sm),
          Row(
            children: [
              _ThemeChoice(
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                selected: widget.themeMode == ThemeMode.system,
                onTap: () =>
                    widget.onThemeModeChanged(ThemeMode.system),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: widget.themeMode == ThemeMode.light,
                onTap: () => widget.onThemeModeChanged(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: widget.themeMode == ThemeMode.dark,
                onTap: () => widget.onThemeModeChanged(ThemeMode.dark),
              ),
            ],
          ),
        ]),

        // ── NOTIFICATIONS ─────────────────────────────────────────────────
        _Section('NOTIFICATIONS', [
          _SwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Enable reminders',
            value: _notifEnabled,
            onChanged: (v) async {
              setState(() => _notifEnabled = v);
              await _storage.saveNotifEnabled(v);
            },
          ),
          _SwitchTile(
            icon: Icons.alarm_rounded,
            title: 'Deadline reminders',
            subtitle: '7 / 3 / 1 days before + on the day',
            value: _notifDeadlines && _notifEnabled,
            onChanged: _notifEnabled
                ? (v) async {
                    setState(() => _notifDeadlines = v);
                    await _storage.saveNotifDeadlines(v);
                  }
                : null,
          ),
          _SwitchTile(
            icon: Icons.app_registration_rounded,
            title: 'Portal opening reminders',
            subtitle: 'One nudge when a submission portal opens',
            value: _notifPortals && _notifEnabled,
            onChanged: _notifEnabled
                ? (v) async {
                    setState(() => _notifPortals = v);
                    await _storage.saveNotifPortals(v);
                  }
                : null,
          ),
          _SwitchTile(
            icon: Icons.meeting_room_rounded,
            title: 'Meeting reminders',
            subtitle: 'The day before each meeting',
            value: _notifMeetings && _notifEnabled,
            onChanged: _notifEnabled
                ? (v) async {
                    setState(() => _notifMeetings = v);
                    await _storage.saveNotifMeetings(v);
                  }
                : null,
          ),
          if (_reminderPreview.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.sm),
            Text('NEXT SCHEDULED',
                style: AppTypography.overline(context)),
            ..._reminderPreview.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.textTertiary(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${p.fireDate.formatted} — ${p.title}',
                          style: AppTypography.caption(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: DesignTokens.xs),
          Text(
            'Delivery requires a notification plugin on the platform; '
            'the schedule is prepared and respects these toggles.',
            style: AppTypography.caption(context).copyWith(fontSize: 10),
          ),
        ]),

        // ── PROJECT ───────────────────────────────────────────────────────
        _Section('PROJECT', [
          _Field(controller: _titleCtrl, hint: 'Project title'),
          const SizedBox(height: 8),
          _Field(
            controller: _descCtrl,
            hint: 'Short description',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _Field(controller: _supervisorCtrl, hint: 'Supervisor'),
          const SizedBox(height: 8),
          _Field(controller: _readerCtrl, hint: 'Reader'),
          const SizedBox(height: 8),
          _Field(controller: _teamCtrl, hint: 'Team members'),
          const SizedBox(height: DesignTokens.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveProject,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save project info'),
            ),
          ),
        ]),

        // ── DATA ──────────────────────────────────────────────────────────
        _Section('DATA', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.ios_share_rounded,
                size: 20, color: AppColors.primary),
            title:
                Text('Export data', style: AppTypography.bodyBold(context)),
            subtitle: Text('See a snapshot of what is stored locally',
                style: AppTypography.caption(context)),
            onTap: _exportData,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever_outlined,
                size: 20, color: AppColors.error),
            title: Text('Clear data',
                style: AppTypography.bodyBold(context)
                    .copyWith(color: AppColors.error)),
            subtitle: Text('Reset all local progress (official dates stay)',
                style: AppTypography.caption(context)),
            onTap: _clearData,
          ),
        ]),

        // ── ABOUT ─────────────────────────────────────────────────────────
        _Section('ABOUT', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.school_rounded,
                size: 20, color: AppColors.primary),
            title: Text('FYP Calendar',
                style: AppTypography.bodyBold(context)),
            subtitle: Text('Cohort 11 • Final Year Project Planner',
                style: AppTypography.caption(context)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline_rounded,
                size: 20, color: AppColors.info),
            title: Text('Version', style: AppTypography.bodyBold(context)),
            subtitle: Text('1.0.0', style: AppTypography.caption(context)),
          ),
        ]),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.lg, DesignTokens.md, DesignTokens.lg, DesignTokens.xxl,
            ),
            child: Center(
              child: Text(
                'Made with ❤️ for FYP students',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section container ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.lg, 0, DesignTokens.lg, DesignTokens.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.overline(context)),
            const SizedBox(height: DesignTokens.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body(context)),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.caption(context)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: 'Use $label theme',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.border(context),
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textTertiary(context)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body(context),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
