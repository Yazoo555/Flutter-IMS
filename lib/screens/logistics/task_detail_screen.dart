// task_detail_screen.dart
// Detailed view for a Logistics Task including supplier info and assigned items.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';
import 'task_form_dialog.dart';

class TaskDetailScreen extends StatefulWidget {
  final LogisticsTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late LogisticsTask _task;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _refreshTask();
  }

  Future<void> _refreshTask() async {
    setState(() => _isLoading = true);
    try {
      final updatedTask = await LogisticsService.getTaskDetail(_task.id);
      if (mounted) {
        setState(() {
          _task = updatedTask;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editTask() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TaskFormDialog(supplierId: _task.supplierId, task: _task),
    );
    if (result == true) {
      _refreshTask();
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
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Task Details', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
            onPressed: _editTask,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTask,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _buildHeaderCard(surfaceColor, textPrimary, textSecondary, borderColor),
            const SizedBox(height: 24),
            _buildSectionTitle('Supplier Information', Icons.business_rounded, textPrimary),
            const SizedBox(height: 12),
            _buildSupplierCard(surfaceColor, textPrimary, textSecondary, borderColor),
            const SizedBox(height: 24),
            _buildSectionTitle('Items & Quantities', Icons.inventory_2_outlined, textPrimary),
            const SizedBox(height: 12),
            _buildItemsList(surfaceColor, textPrimary, textSecondary, borderColor),
            if (_task.notes != null && _task.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Notes', Icons.notes_rounded, textPrimary),
              const SizedBox(height: 12),
              _buildNotesCard(surfaceColor, textPrimary, textSecondary, borderColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildHeaderCard(Color surface, Color textPrimary, Color textSecondary, Color border) {
    final statusColor = _statusColor(_task.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  _task.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                ),
              ),
              if (_task.scheduledDate != null)
                Text(
                  DateFormat('MMM d, yyyy').format(_task.scheduledDate!),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_task.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2)),
          if (_task.description != null && _task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_task.description!, style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5)),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Icons.access_time_rounded, 'Created', DateFormat('MMM d, HH:mm').format(_task.createdAt), textSecondary),
              const Spacer(),
              if (_task.completedAt != null)
                _buildInfoItem(Icons.check_circle_outline_rounded, 'Completed', DateFormat('MMM d, HH:mm').format(_task.completedAt!), AppTheme.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.5), fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplierCard(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_task.supplierName ?? 'Unknown Supplier', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                if (_task.supplierPhone != null)
                  Text(_task.supplierPhone!, style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
            onPressed: () {
              // Navigate to supplier detail if needed
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(Color surface, Color textPrimary, Color textSecondary, Color border) {
    if (_task.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Center(child: Text('No items assigned to this task', style: TextStyle(fontSize: 13, color: textSecondary))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _task.items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: border, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = _task.items[index];
          final qty = item['quantity'] ?? 0.0;
          final unit = item['unit_abbreviation'] ?? '';
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(item['name'] ?? 'Unknown Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
            subtitle: Text('SKU: ${item['sku'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} $unit',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesCard(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(_task.notes!, style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5)),
    );
  }
}
