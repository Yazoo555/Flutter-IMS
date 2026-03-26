import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../models/app_theme.dart';
import '../models/class_session.dart';

class AddEditTodoSheet extends StatefulWidget {
  final TodoItem? todo;

  const AddEditTodoSheet({super.key, this.todo});

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TodoCategory _category = TodoCategory.assignment;
  TodoPriority _priority = TodoPriority.medium;
  String? _subject;
  DateTime? _dueDate;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _category = t.category;
      _priority = t.priority;
      _subject = t.subject;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    final todo = TodoItem(
      id: widget.todo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _category,
      priority: _priority,
      subject: _subject,
      dueDate: _dueDate,
      isCompleted: widget.todo?.isCompleted ?? false,
      createdAt: widget.todo?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(todo);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : const Color(0xFFF7F7FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
              _isEdit ? 'Edit Task' : 'New Task',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 22),

            // Task title field
            _buildField(
              controller: _titleController,
              label: 'Task Title *',
              hint: 'e.g. Submit assignment for Cloud Systems',
              icon: Icons.task_alt_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 14),

            // Description
            _buildField(
              controller: _descController,
              label: 'Notes (optional)',
              hint: 'Add any extra details...',
              icon: Icons.notes_rounded,
              isDark: isDark,
              maxLines: 2,
            ),

            const SizedBox(height: 18),

            // Category
            _sectionLabel('Category', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TodoCategory.values.map((c) {
                final sel = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? c.color : c.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? c.color : c.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c.icon,
                          size: 14,
                          color: sel ? Colors.white : c.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : c.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Priority
            _sectionLabel('Priority', isDark),
            const SizedBox(height: 8),
            Row(
              children: TodoPriority.values.map((p) {
                final sel = p == _priority;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? p.color : p.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? p.color : p.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.icon,
                            size: 13,
                            color: sel ? Colors.white : p.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : p.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Subject (from known subjects)
            _sectionLabel('Subject (optional)', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SubjectChip(
                  label: 'None',
                  selected: _subject == null,
                  onTap: () => setState(() => _subject = null),
                  isDark: isDark,
                ),
                ...subjectOptions.map(
                  (s) => _SubjectChip(
                    label: s,
                    selected: _subject == s,
                    onTap: () => setState(() => _subject = s),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Due date
            _sectionLabel('Due Date (optional)', isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: _dueDate != null
                      ? Border.all(color: AppColors.accent.withOpacity(0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 17,
                      color: _dueDate != null
                          ? AppColors.accent
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Pick a due date'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dueDate != null
                            ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                            : (isDark ? Colors.white30 : Colors.black38),
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
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
                  _isEdit ? 'Save Changes' : 'Add Task',
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

  Widget _sectionLabel(String text, bool isDark) => Text(
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, isDark),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
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

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
