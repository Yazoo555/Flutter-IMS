// task_form_dialog.dart
// Modal dialog for creating or editing a Logistics Task.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'item_picker_dialog.dart';

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

  // Items State
  List<Map<String, dynamic>> _selectedItems = [];
  bool _isLoadingItems = false;

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

    if (_isEditing) {
      _fetchAssignedItems();
    }
  }

  Future<void> _fetchAssignedItems() async {
    setState(() => _isLoadingItems = true);
    try {
      // Get all items and filter those assigned to this task
      // Note: Ideally we'd have a specific endpoint for this, 
      // but we'll use the available items + assigned IDs filter for now.
      final assignedIds = await LogisticsService.getAssignedItemIds(widget.task!.id);
      final allItems = await LogisticsService.getAvailableItems();
      
      if (!mounted) return;
      setState(() {
        _selectedItems = allItems.where((i) => assignedIds.contains(i['id'])).toList();
        _isLoadingItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingItems = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
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

  void _openItemPicker() async {
    final excludedIds = _selectedItems.map((i) => i['id'] as String).toSet();
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => ItemPickerDialog(excludedIds: excludedIds),
    );

    if (result != null) {
      setState(() {
        // Add default quantity of 1.0 to each newly selected item
        final itemsWithQty = result.map((i) => {
          ...i,
          'quantity': 1.0,
        }).toList();
        _selectedItems.addAll(itemsWithQty);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, double qty) {
    setState(() {
      _selectedItems[index]['quantity'] = qty;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dateStr = _scheduledDate != null
          ? DateFormat('yyyy-MM-dd').format(_scheduledDate!)
          : null;

      String taskId;

      if (_isEditing) {
        taskId = widget.task!.id;
        final fields = <String, dynamic>{
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _status,
          'scheduled_date': dateStr,
          'notes': _notesController.text.trim(),
        };

        if (_status == 'completed' && widget.task!.status != 'completed') {
          fields['completed_at'] = DateTime.now().toUtc().toIso8601String();
        } else if (_status != 'completed') {
          fields['completed_at'] = null;
        }

        await LogisticsService.updateTask(taskId, fields);
      } else {
        final newTask = await LogisticsService.createTask(
          supplierId: widget.supplierId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          scheduledDate: dateStr,
          notes: _notesController.text.trim(),
        );
        taskId = newTask.id;
      }

      // Add selected items with quantities
      if (_selectedItems.isNotEmpty) {
        final itemsToSync = _selectedItems.map((i) => {
          'id': i['id'] as String,
          'quantity': i['quantity'] ?? 1.0,
        }).toList();
        
        await LogisticsService.addTaskItems(taskId, itemsToSync);

        // Reduce stock immediately for new tasks or new items added
        // For simplicity, we'll assume "sale" movement type for logistics tasks.
        // If it's a new task, reduce stock for all items.
        if (!_isEditing) {
          await LogisticsService.adjustStockBulk(
            items: itemsToSync,
            movementType: 'sale',
            reference: 'TASK-${taskId.substring(0, 8).toUpperCase()}',
            notes: 'Stock reduced for logistics task: ${_titleController.text.trim()}',
          );
        }
      }

      // Invalidate cache immediately so any screen showing tasks
      // (including LogisticsScreen via IndexedStack) gets fresh data
      // on next render — regardless of how this dialog was opened.
      LogisticsService.invalidateTasks();

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
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final inputFill = AppTheme.getInputBg(context);
    final borderColor = AppTheme.getBorder(context);
    final hintColor = AppTheme.getTextHint(context);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
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
                              ? 'Update task details and items'
                              : 'Create task and select items',
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
            ),
            
            Divider(height: 1, color: borderColor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: 'Title *',
                        controller: _titleController,
                        hint: 'e.g. Deliver materials',
                        icon: Icons.title_rounded,
                        maxLength: 40,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Title is required';
                          return null;
                        },
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        hintColor: hintColor,
                        inputFill: inputFill,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Description *',
                        controller: _descriptionController,
                        hint: 'Task details...',
                        icon: Icons.description_outlined,
                        maxLines: 2,
                        maxLength: 120,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Description is required';
                          return null;
                        },
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        hintColor: hintColor,
                        inputFill: inputFill,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                      
                      // Status Selection
                      Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withAlpha(25) : inputFill,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? color : borderColor, width: isSelected ? 1.5 : 1),
                              ),
                              child: Text(s.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? color : textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Picker
                      Text('Scheduled Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: hintColor),
                              const SizedBox(width: 10),
                              Text(_scheduledDate != null ? DateFormat('MMM d, yyyy').format(_scheduledDate!) : 'Select a date', style: TextStyle(fontSize: 14, color: _scheduledDate != null ? textPrimary : hintColor)),
                              const Spacer(),
                              if (_scheduledDate != null) GestureDetector(onTap: () => setState(() => _scheduledDate = null), child: Icon(Icons.clear_rounded, size: 16, color: hintColor)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ── Items Section ──────────────────────────────────────
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('Task Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _openItemPicker,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Items', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildItemsList(borderColor, textPrimary, textSecondary),
                      
                      const SizedBox(height: 24),
                      
                      _buildTextField(
                        label: 'Notes',
                        controller: _notesController,
                        hint: 'Additional notes...',
                        icon: Icons.notes_rounded,
                        maxLines: 2,
                        maxLength: 150,
                        validator: (v) {
                          // Notes is optional — no character restriction
                          return null;
                        },
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        hintColor: hintColor,
                        inputFill: inputFill,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Divider(height: 1, color: borderColor),

            // Fixed Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEditing ? 'Save Changes' : 'Create Task', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(Color borderColor, Color textPrimary, Color textSecondary) {
    if (_isLoadingItems) {
      return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_selectedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.getBg(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, style: BorderStyle.solid)),
        child: Center(child: Text('No items selected', style: TextStyle(fontSize: 12, color: textSecondary))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppTheme.getBg(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedItems.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
        itemBuilder: (context, index) {
          final item = _selectedItems[index];
          final qty = item['quantity'] ?? 1.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      Text('SKU: ${item['sku'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity Input
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _QtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            if (qty > 1) _updateItemQuantity(index, qty - 1);
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add_rounded,
                          onTap: () => _updateItemQuantity(index, qty + 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppTheme.errorColor),
                  onPressed: () => _removeItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
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
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: hintColor),
            prefixIcon: Icon(icon, size: 18, color: hintColor),
            filled: true,
            fillColor: inputFill,
            counterStyle: TextStyle(fontSize: 10, color: textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.05),
        ),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }
}
