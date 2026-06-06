import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';

class AddEditSheet extends StatefulWidget {
  final ClassSession? session;

  const AddEditSheet({super.key, this.session});

  @override
  State<AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<AddEditSheet> {
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String _selectedDay = weekDays[0];
  String _selectedType = typeOptions[0];

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    if (s != null) {
      _subjectController.text = s.subject;
      _roomController.text = s.room;
      _lecturerController.text = s.lecturer;
      _startController.text = s.startTime;
      _endController.text = s.endTime;
      _selectedDay = s.day;
      _selectedType = s.type;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_subjectController.text.trim().isEmpty ||
        _startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final session = ClassSession(
      id: widget.session?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      day: _selectedDay,
      startTime: _startController.text.trim(),
      endTime: _endController.text.trim(),
      subject: _subjectController.text.trim(),
      type: _selectedType,
      room: _roomController.text.trim(),
      lecturer: _lecturerController.text.trim(),
    );

    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.session != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusSheet),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textTertiaryDark.withOpacity(0.4)
                      : AppColors.textTertiaryLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isEdit ? 'Edit Class' : 'Add Class',
              style: AppTypography.headingLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // Day selector
            _sectionLabel('Day', context),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = weekDays[i];
                  final sel = day == _selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusFull,
                        ),
                      ),
                      child: Text(
                        day.substring(0, 3),
                        style: AppTypography.smallBold.copyWith(
                          color: sel
                              ? Colors.white
                              : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Time row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _startController,
                    label: 'Start Time',
                    hint: '09:00 AM',
                    icon: Icons.schedule_rounded,
                    context: context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _endController,
                    label: 'End Time',
                    hint: '11:00 AM',
                    icon: Icons.schedule_outlined,
                    context: context,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Subject
            _buildField(
              controller: _subjectController,
              label: 'Subject *',
              hint: 'e.g. Cloud Systems',
              icon: Icons.book_outlined,
              context: context,
            ),

            const SizedBox(height: 18),

            // Type chips
            _sectionLabel('Type', context),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeOptions.map((t) {
                final sel = t == _selectedType;
                final c = AppColors.typeColor(t);
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? c : c.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      border: Border.all(
                        color: sel ? c : c.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      t,
                      style: AppTypography.smallBold.copyWith(
                        color: sel ? Colors.white : c,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Room
            _buildField(
              controller: _roomController,
              label: 'Room',
              hint: 'e.g. LT-02 (WLV Block)',
              icon: Icons.location_on_outlined,
              context: context,
            ),

            const SizedBox(height: 18),

            // Lecturer
            _buildField(
              controller: _lecturerController,
              label: 'Lecturer',
              hint: 'e.g. Ms. Jenny Rajak',
              icon: Icons.person_outline_rounded,
              context: context,
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMd,
                    ),
                  ),
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Class',
                  style: AppTypography.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, BuildContext context) => Text(
    text,
    style: AppTypography.smallBold.copyWith(
      color: AppTheme.textSecondary(context),
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, context),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.body.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
