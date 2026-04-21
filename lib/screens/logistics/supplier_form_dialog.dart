// supplier_form_dialog.dart
// Modal dialog for creating or editing a Supplier.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier; // null → create mode

  const SupplierFormDialog({super.key, this.supplier});

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _contactNameController =
        TextEditingController(text: widget.supplier?.contactName ?? '');
    _emailController =
        TextEditingController(text: widget.supplier?.email ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.supplier?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await LogisticsService.updateSupplier(
          widget.supplier!.id,
          {
            'name': _nameController.text.trim(),
            'contact_name': _contactNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          },
        );
      } else {
        await LogisticsService.createSupplier(
          name: _nameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isEditing ? 'update' : 'create'} supplier.'),
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

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final inputFill = AppTheme.getInputBg(context);
    final borderColor = AppTheme.getBorder(context);

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
                  // ── Header ──────────────────────────────────────────────────
                  Row(
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
                          Icons.business_rounded,
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
                              _isEditing ? 'Edit Supplier' : 'New Supplier',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Update supplier information'
                                  : 'Add a new supplier to your network',
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

                  // ── Name ────────────────────────────────────────────────────
                  _buildField(
                    label: 'Supplier Name *',
                    controller: _nameController,
                    hint: 'e.g. Acme Supplies',
                    icon: Icons.store_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 16),

                  // ── Contact Name ────────────────────────────────────────────
                  _buildField(
                    label: 'Contact Person',
                    controller: _contactNameController,
                    hint: 'e.g. John Doe',
                    icon: Icons.person_outline_rounded,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 16),

                  // ── Email ───────────────────────────────────────────────────
                  _buildField(
                    label: 'Email *',
                    controller: _emailController,
                    hint: 'supplier@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 16),

                  // ── Phone ───────────────────────────────────────────────────
                  _buildField(
                    label: 'Phone *',
                    controller: _phoneController,
                    hint: '+977 98XXXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone is required'
                        : null,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 16),

                  // ── Address ─────────────────────────────────────────────────
                  _buildField(
                    label: 'Address *',
                    controller: _addressController,
                    hint: 'Street, City, Country',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 28),

                  // ── Actions ─────────────────────────────────────────────────
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
                                  _isEditing
                                      ? 'Save Changes'
                                      : 'Create Supplier',
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Color inputFill,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hintColor = AppTheme.getTextHint(context);
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
          keyboardType: keyboardType,
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
