import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/meeting.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/meeting_edit_sheet.dart';

/// Meetings manager — record supervisor / reader / team meetings.
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _repo = FypRepository();
  List<Meeting> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meetings = await _repo.loadMeetings();
    if (!mounted) return;
    setState(() {
      _meetings = meetings;
      _loading = false;
    });
  }

  Future<void> _addOrEdit([Meeting? meeting]) async {
    final result = await showMeetingEditor(context, meeting: meeting);
    if (result == null) return;
    if (meeting == null) {
      await _repo.addMeeting(result);
    } else {
      await _repo.updateMeeting(result);
    }
    await _load();
  }

  Future<void> _toggleCompleted(Meeting meeting) async {
    await _repo.updateMeeting(
      meeting.copyWith(completed: !meeting.completed),
    );
    await _load();
  }

  Future<void> _delete(Meeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Remove "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteMeeting(meeting.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcoming = _meetings
        .where((m) => !m.isPast && !m.completed)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = _meetings
        .where((m) => m.isPast || m.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOrEdit,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('Add Meeting',
            style: AppTypography.button(context)),
      ),
      body: _meetings.isEmpty
          ? const EmptyState(
              icon: Icons.meeting_room_rounded,
              title: 'No meetings yet',
              message: 'Keep track of your supervisor and project meetings.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.lg, DesignTokens.xl, DesignTokens.lg, 96,
              ),
              children: [
                Text('Meetings', style: AppTypography.pageTitle(context)),
                Text(
                  '${upcoming.length} upcoming • ${past.length} past',
                  style: AppTypography.caption(context),
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.lg),
                  Text('UPCOMING', style: AppTypography.overline(context)),
                  const SizedBox(height: DesignTokens.sm),
                  ...upcoming.map((m) => _MeetingCard(
                        meeting: m,
                        onToggle: () => _toggleCompleted(m),
                        onEdit: () => _addOrEdit(m),
                        onDelete: () => _delete(m),
                      )),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.lg),
                  Text('PAST & COMPLETED',
                      style: AppTypography.overline(context)),
                  const SizedBox(height: DesignTokens.sm),
                  ...past.map((m) => _MeetingCard(
                        meeting: m,
                        onToggle: () => _toggleCompleted(m),
                        onEdit: () => _addOrEdit(m),
                        onDelete: () => _delete(m),
                      )),
                ],
              ],
            ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeetingCard({
    required this.meeting,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final isUpcoming = !m.isPast && !m.completed;
    final countdown = m.isToday
        ? 'Today'
        : '${m.daysFromNow} day${m.daysFromNow == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isUpcoming
              ? AppColors.supervisor.withValues(alpha: 0.25)
              : AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.supervisor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  m.type.label,
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.supervisor,
                  ),
                ),
              ),
              const Spacer(),
              if (isUpcoming)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.supervisor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  ),
                  child: Text(
                    countdown,
                    style: AppTypography.caption(context).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.supervisor,
                    ),
                  ),
                )
              else
                Icon(Icons.check_rounded,
                    size: 13, color: AppColors.statusCompleted),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'toggle') onToggle();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(m.completed ? 'Mark not done' : 'Mark completed'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            m.title,
            style: AppTypography.bodyEmphasized(context).copyWith(
              decoration: m.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 11, color: AppColors.textTertiary(context)),
              const SizedBox(width: 4),
              Text(m.date.formatted, style: AppTypography.caption(context)),
              if (m.timeLabel != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.schedule_outlined,
                    size: 11, color: AppColors.textTertiary(context)),
                const SizedBox(width: 3),
                Text(m.timeLabel!, style: AppTypography.caption(context)),
              ],
              if (m.supervisor.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.person_outline_rounded,
                    size: 11, color: AppColors.textTertiary(context)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    m.supervisor,
                    style: AppTypography.caption(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (m.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppColors.cardDarkAlt
                    : AppColors.surfaceLightAlt,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(m.notes, style: AppTypography.caption(context)),
            ),
          ],
        ],
      ),
    );
  }
}
