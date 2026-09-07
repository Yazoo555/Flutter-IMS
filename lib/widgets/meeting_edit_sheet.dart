import 'package:flutter/material.dart';

import '../extensions/date_helpers.dart';
import '../models/meeting.dart';
import '../models/milestone.dart';
import '../services/fyp_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Add / edit a supervisor / reader / team meeting.
class MeetingEditSheet extends StatefulWidget {
  final Meeting? meeting;

  const MeetingEditSheet({super.key, this.meeting});

  @override
  State<MeetingEditSheet> createState() => _MeetingEditSheetState();
}

class _MeetingEditSheetState extends State<MeetingEditSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _personController = TextEditingController();
  final _notesController = TextEditingController();
  final _repo = FypRepository();

  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  MeetingType _type = MeetingType.supervisor;
  String? _milestoneId;
  List<Milestone> _milestones = [];

  bool get _isEdit => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    final m = widget.meeting;
    if (m != null) {
      _titleController.text = m.title;
      _locationController.text = m.location;
      _personController.text = m.supervisor;
      _notesController.text = m.notes;
      _date = m.date;
      _time = m.timeMinutes == null
          ? null
          : TimeOfDay(hour: m.timeMinutes! ~/ 60, minute: m.timeMinutes! % 60);
      _type = m.type;
      _milestoneId = m.relatedMilestoneId;
    }
    _repo.loadMilestones().then((list) {
      if (!mounted) return;
      setState(() => _milestones = list);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _personController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026),
      lastDate: DateTime(2028),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }
    final meeting = Meeting(
      id: widget.meeting?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      date: _date,
      timeMinutes: _time == null ? null : _time!.hour * 60 + _time!.minute,
      type: _type,
      location: _locationController.text.trim(),
      supervisor: _personController.text.trim(),
      notes: _notesController.text.trim(),
      relatedMilestoneId: _milestoneId,
      completed: widget.meeting?.completed ?? false,
    );
    Navigator.of(context).pop(meeting);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.lg, DesignTokens.sm, DesignTokens.lg, DesignTokens.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary(context)
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.lg),
              Text(_isEdit ? 'Edit Meeting' : 'New Meeting',
                  style: AppTypography.headingLarge(context)),
              const SizedBox(height: DesignTokens.lg),

              TextField(
                controller: _titleController,
                autofocus: !_isEdit,
                style: AppTypography.body(context),
                decoration: const InputDecoration(
                  hintText: 'Meeting title',
                  prefixIcon: Icon(Icons.title_rounded, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),

              // Type
              Text('TYPE', style: AppTypography.overline(context)),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MeetingType.values.map((t) {
                  final sel = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.supervisor
                            : AppColors.supervisor.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(
                          color: sel
                              ? AppColors.supervisor
                              : AppColors.supervisor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        t.label,
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white
                              : AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.md),

              // Date & time
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.isDark(context)
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_outlined,
                                size: 16,
                                color: AppColors.textTertiary(context)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_date.formatted,
                                  style: AppTypography.body(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 16,
                              color: AppColors.textTertiary(context)),
                          const SizedBox(width: 8),
                          Text(
                            _time == null
                                ? 'Time'
                                : _time!.format(context),
                            style: AppTypography.body(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.md),

              TextField(
                controller: _personController,
                style: AppTypography.body(context),
                decoration: const InputDecoration(
                  hintText: 'Supervisor / person (optional)',
                  prefixIcon:
                      Icon(Icons.person_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),
              TextField(
                controller: _locationController,
                style: AppTypography.body(context),
                decoration: const InputDecoration(
                  hintText: 'Location (optional)',
                  prefixIcon: Icon(Icons.place_outlined, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),
              TextField(
                controller: _notesController,
                style: AppTypography.body(context),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes / agenda (optional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                ),
              ),
              const SizedBox(height: DesignTokens.md),

              // Related milestone
              Text('RELATED MILESTONE (OPTIONAL)',
                  style: AppTypography.overline(context)),
              const SizedBox(height: DesignTokens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _milestoneId = null),
                    child: _Chip(
                      label: 'None',
                      selected: _milestoneId == null,
                    ),
                  ),
                  ..._milestones.map((m) => GestureDetector(
                        onTap: () => setState(() => _milestoneId = m.id),
                        child: _Chip(
                          label: m.title.split('—').first.trim(),
                          selected: _milestoneId == m.id,
                        ),
                      )),
                ],
              ),

              const SizedBox(height: DesignTokens.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Save Changes' : 'Create Meeting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.milestone
            : AppColors.milestone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: selected
              ? AppColors.milestone
              : AppColors.milestone.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

/// Convenience: open the meeting editor and return the saved meeting.
Future<Meeting?> showMeetingEditor(BuildContext context, {Meeting? meeting}) {
  return showModalBottomSheet<Meeting>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MeetingEditSheet(meeting: meeting),
  );
}
