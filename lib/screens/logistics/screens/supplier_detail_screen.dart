// supplier_detail_screen.dart
// Detail view for a single supplier with Edit and Delete actions.

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/supplier.dart';
import '../services/logistics_service.dart';
import 'suppliers_tab.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onDataChanged;

  const SupplierDetailScreen({
    super.key,
    required this.supplier,
    required this.onDataChanged,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  Future<void> _deleteSupplier() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Supplier',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to deactivate "${widget.supplier.name}"?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(
                    color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await LogisticsService.deleteSupplier(widget.supplier.id);
      if (!mounted) return;
      _showSnack('${widget.supplier.name} deactivated.');
      widget.onDataChanged();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final primaryLight =
        isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Supplier Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            onPressed: () async {
              // Navigate to edit using the supplier form from suppliers_tab
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => _SupplierEditWrapper(supplier: s),
                ),
              );
              if (updated == true) {
                widget.onDataChanged();
                if (mounted) Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.business_rounded,
                        size: 28, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary)),
                        if (s.contactName != null &&
                            s.contactName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(s.contactName!,
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Info
            _buildSectionTitle('CONTACT INFORMATION', textSecondary),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.phone_rounded, 'Phone',
                      s.phone ?? 'Not provided', textPrimary, textSecondary),
                  Divider(height: 1, color: borderColor),
                  _infoRow(Icons.email_rounded, 'Email',
                      s.email ?? 'Not provided', textPrimary, textSecondary),
                  Divider(height: 1, color: borderColor),
                  _infoRow(
                      Icons.location_on_rounded,
                      'Address',
                      s.address ?? 'Not provided',
                      textPrimary,
                      textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _deleteSupplier,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Deactivate Supplier',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit Wrapper (reuses the form from suppliers_tab.dart) ───────────────────

class _SupplierEditWrapper extends StatelessWidget {
  final Supplier supplier;
  const _SupplierEditWrapper({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return _SupplierEditFormScreen(
      supplier: supplier,
      isDark: isDark,
      bg: bg,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
    );
  }
}

class _SupplierEditFormScreen extends StatefulWidget {
  final Supplier supplier;
  final bool isDark;
  final Color bg;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceColor;
  final Color borderColor;

  const _SupplierEditFormScreen({
    required this.supplier,
    required this.isDark,
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  State<_SupplierEditFormScreen> createState() =>
      _SupplierEditFormScreenState();
}

class _SupplierEditFormScreenState extends State<_SupplierEditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier.name);
    _contactController =
        TextEditingController(text: widget.supplier.contactName ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier.phone ?? '');
    _emailController =
        TextEditingController(text: widget.supplier.email ?? '');
    _addressController =
        TextEditingController(text: widget.supplier.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await LogisticsService.updateSupplier(widget.supplier.id, {
        'name': _nameController.text.trim(),
        'contact_name': _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bg,
      appBar: AppBar(
        backgroundColor: widget.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: widget.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Supplier',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.textPrimary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Name *', _nameController, 'e.g. Nepal Traders',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null),
                  const SizedBox(height: 16),
                  _field('Contact Name', _contactController,
                      'e.g. Ram Bahadur'),
                  const SizedBox(height: 16),
                  _field('Phone', _phoneController, 'e.g. 9801234567',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _field('Email', _emailController, 'e.g. ram@example.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _field('Address', _addressController,
                      'e.g. New Road, Kathmandu',
                      maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Update Supplier',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: widget.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 14,
                color: widget.isDark
                    ? AppTheme.darkTextHint
                    : AppTheme.textHint),
            filled: true,
            fillColor: widget.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.borderColor),
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
          ),
        ),
      ],
    );
  }
}
