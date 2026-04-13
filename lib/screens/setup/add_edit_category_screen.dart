import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import 'categories_screen.dart';

class AddEditCategoryScreen extends StatefulWidget {
  /// Pass a [category] to enter edit mode; omit for add mode.
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  bool _isLoading = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category?.name ?? '');
    _descController =
        TextEditingController(text: widget.category?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    if (value.trim().length > 50) {
      return 'Name must not exceed 50 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null && value.trim().length > 200) {
      return 'Description must not exceed 200 characters';
    }
    return null;
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    try {
      if (_isEditing) {
        await supabase
            .from('categories')
            .update({
              'name': name,
              'description': description.isEmpty ? null : description,
            })
            .eq('id', widget.category!.id);
      } else {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('Not authenticated');
        await supabase.from('categories').insert({
          'user_id': userId,
          'name': name,
          'description': description.isEmpty ? null : description,
        });
      }

      if (!mounted) return;
      _showSnack(
          _isEditing ? 'Category updated.' : 'Category created.');
      Navigator.pop(context, true); // signal success to list screen
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // Unique violation: same name already exists for this user
      final msg = e.code == '23505'
          ? 'A category with this name already exists.'
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
          _isEditing ? 'Edit Category' : 'Add Category',
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
                    color: const Color(0xFF0EA5E9).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF0EA5E9).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.category_rounded,
                            size: 26, color: Color(0xFF0EA5E9)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Update Category'
                                  : 'New Category',
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
                                  : 'Group your inventory items by category.',
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
                LabeledTextField(
                  label: 'CATEGORY NAME',
                  hintText: 'e.g. Electronics, Beverages',
                  controller: _nameController,
                  maxLength: 50,
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  validator: _validateName,
                ),

                const SizedBox(height: 20),

                LabeledTextField(
                  label: 'DESCRIPTION (OPTIONAL)',
                  hintText: 'Brief description of this category',
                  controller: _descController,
                  maxLength: 200,
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  validator: _validateDescription,
                ),

                const SizedBox(height: 36),

                // ── Submit button ─────────────────────────────────────────
                PrimaryButton(
                  label: _isEditing ? 'Update Category' : 'Create Category',
                  onPressed: _handleSubmit,
                  showArrow: true,
                  isLoading: _isLoading,
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
}