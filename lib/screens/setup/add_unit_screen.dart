import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import 'units_screen.dart';

class AddUnitScreen extends StatefulWidget {
  /// Pass a [unit] to enter edit mode; omit for add mode.
  final UnitModel? unit;

  const AddUnitScreen({super.key, this.unit});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _abbreviationController;
  bool _isLoading = false;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.unit?.name ?? '');
    _abbreviationController =
        TextEditingController(text: widget.unit?.abbreviation ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Unit name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length > 10) {
      return 'Maximum 10 characters allowed';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      return 'Only letters and spaces allowed';
    }
    return null;
  }

  String? _validateAbbreviation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Abbreviation is required';
    }
    final trimmed = value.trim();
    if (trimmed.length > 5) {
      return 'Maximum 5 characters allowed';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(trimmed)) {
      return 'Only letters allowed, no spaces or special characters';
    }
    return null;
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final abbreviation = _abbreviationController.text.trim();

    try {
      if (_isEditing) {
        await supabase
            .from('units')
            .update({'name': name, 'abbreviation': abbreviation})
            .eq('id', widget.unit!.id);
      } else {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('Not authenticated');
        await supabase.from('units').insert({
          'name': name,
          'abbreviation': abbreviation,
          'created_by': userId,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.code == '23505'
          ? 'A unit with this name or abbreviation already exists.'
          : e.message;
      _showSnack(msg, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _isEditing ? 'Edit Unit' : 'Add Unit',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.straighten_rounded,
                            size: 26, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Update Unit' : 'New Unit',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isEditing
                                  ? 'Modify the details below.'
                                  : 'Define a measurement unit for your items.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Fields ───────────────────────────────────────────────
                _buildFieldLabel('UNIT NAME'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'e.g. Kilogram',
                  maxLength: 10,
                  validator: _validateName,
                  prefixIcon: const Icon(Icons.straighten_rounded,
                      size: 20, color: AppTheme.textHint),
                ),

                const SizedBox(height: 20),

                _buildFieldLabel('ABBREVIATION'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _abbreviationController,
                  hint: 'e.g. kg',
                  maxLength: 5,
                  validator: _validateAbbreviation,
                  prefixIcon: const Icon(Icons.label_outline_rounded,
                      size: 20, color: AppTheme.textHint),
                ),

                const SizedBox(height: 36),

                // ── Submit button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor:
                          AppTheme.primary.withOpacity(0.6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isEditing
                                    ? 'Update Unit'
                                    : 'Create Unit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required String? Function(String?)? validator,
    required Widget prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textHint, fontSize: 14),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
      ),
    );
  }
}