import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';

class AddEditSheet extends StatefulWidget {
  final ClassSession? session; // null = add mode

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
      id:
          widget.session?.id ??
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : const Color(0xFFF7F7FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isEdit ? 'Edit Class' : 'Add Class',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 22),

            // Day selector
            _label('Day', isDark),
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
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent
                            : (isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.black.withOpacity(0.06)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sel
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Time row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _startController,
                    label: 'Start Time',
                    hint: '09:00 AM',
                    icon: Icons.schedule_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _endController,
                    label: 'End Time',
                    hint: '11:00 AM',
                    icon: Icons.schedule_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Subject
            _buildField(
              controller: _subjectController,
              label: 'Subject *',
              hint: 'e.g. Cloud Systems',
              icon: Icons.book_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Type chips
            _label('Type', isDark),
            const SizedBox(height: 8),
            Row(
              children: typeOptions.map((t) {
                final sel = t == _selectedType;
                final c = AppColors.typeColor(t);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? c : c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? c : c.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : c,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Room
            _buildField(
              controller: _roomController,
              label: 'Room',
              hint: 'e.g. LT-02 (WLV Block)',
              icon: Icons.location_on_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Lecturer
            _buildField(
              controller: _lecturerController,
              label: 'Lecturer',
              hint: 'e.g. Ms. Jenny Rajak',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Class',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: isDark ? Colors.white54 : Colors.black45,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, isDark),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
