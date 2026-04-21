// task_form_dialog.dart
// Modal dialog for creating or editing a Logistics Task.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';

class TaskFormDialog extends StatefulWidget {
  final String supplierId;
  final LogisticsTask? task; // null → create mode

  const TaskFormDialog({
    super.key,
    required this.supplierId,
    this.task,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late String _status;
  DateTime? _scheduledDate;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  static const _statuses = [
    ('pending', 'Pending'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _notesController =
        TextEditingController(text: widget.task?.notes ?? '');
    _status = widget.task?.status ?? 'pending';
    _scheduledDate = widget.task?.scheduledDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: AppTheme.primary,
                  surface: AppTheme.darkSurface,
                )
              : const ColorScheme.light(
                  primary: AppTheme.primary,
                  surface: AppTheme.surface,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dateStr = _scheduledDate != null
          ? DateFormat('yyyy-MM-dd').format(_scheduledDate!)
          : null;

      if (_isEditing) {
        final fields = <String, dynamic>{
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _status,
          'scheduled_date': dateStr,
          'notes': _notesController.text.trim(),
        };

        // Set completed_at when status changes to completed
        if (_status == 'completed' && widget.task!.status != 'completed') {
          fields['completed_at'] = DateTime.now().toUtc().toIso8601String();
        } else if (_status != 'completed') {
          fields['completed_at'] = null;
        }

        await LogisticsService.updateTask(widget.task!.id, fields);
      } else {
        await LogisticsService.createTask(
          supplierId: widget.supplierId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          scheduledDate: dateStr,
          notes: _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to ${_isEditing ? 'update' : 'create'} task.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => const Color(0xFFF59E0B),
        'in_progress' => const Color(0xFF0EA5E9),
        'completed' => const Color(0xFF10B981),
        'cancelled' => const Color(0xFFEF4444),
        _ => AppTheme.textHint,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final inputFill =
        isDark ? AppTheme.darkInputBackground : AppTheme.inputBackground;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final hintColor = isDark ? AppTheme.darkTextHint : AppTheme.textHint;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkPrimaryLight
                              : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit Task' : 'New Task',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Update task details'
                                  : 'Create a new logistics task',
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded,
                            size: 22, color: textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Title ───────────────────────────────────────────────
                  _buildTextField(
                    label: 'Title *',
                    controller: _titleController,
                    hint: 'e.g. Deliver raw materials',
                    icon: Icons.title_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    hintColor: hintColor,
                    inputFill: inputFill,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 16),

                  // ── Description ─────────────────────────────────────────
                  _buildTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hint: 'Task details...',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    hintColor: hintColor,
                    inputFill: inputFill,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 16),

                  // ── Status ──────────────────────────────────────────────
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) {
                      final isSelected = _status == s.$1;
                      final color = _statusColor(s.$1);
                      return GestureDetector(
                        onTap: () => setState(() => _status = s.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withAlpha(25)
                                : inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ── Scheduled Date ──────────────────────────────────────
                  Text(
                    'Scheduled Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: hintColor),
                          const SizedBox(width: 10),
                          Text(
                            _scheduledDate != null
                                ? DateFormat('MMM d, yyyy')
                                    .format(_scheduledDate!)
                                : 'Select a date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _scheduledDate != null
                                  ? textPrimary
                                  : hintColor,
                            ),
                          ),
                          const Spacer(),
                          if (_scheduledDate != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _scheduledDate = null),
                              child: Icon(Icons.clear_rounded,
                                  size: 16, color: hintColor),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Notes ───────────────────────────────────────────────
                  _buildTextField(
                    label: 'Notes',
                    controller: _notesController,
                    hint: 'Additional notes...',
                    icon: Icons.notes_rounded,
                    maxLines: 2,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    hintColor: hintColor,
                    inputFill: inputFill,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 28),

                  // ── Actions ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Save Changes' : 'Create Task',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Color textPrimary,
    required Color textSecondary,
    required Color hintColor,
    required Color inputFill,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: hintColor),
            prefixIcon: Icon(icon, size: 18, color: hintColor),
            filled: true,
            fillColor: inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
