import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import 'add_edit_category_screen.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class Category {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isDefault;
  final bool hasExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.isDefault,
    this.hasExpiry = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        hasExpiry: json['has_expiry'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'has_expiry': hasExpiry,
      };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _categories = (data as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load categories. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // Guard: cannot delete default category
    if (category.isDefault) {
      _showSnack('The default "General" category cannot be deleted.',
          error: true);
      return;
    }

    final confirmed = await _showDeleteDialog(category.name);
    if (!confirmed) return;

    try {
      await supabase.from('categories').delete().eq('id', category.id);
      if (!mounted) return;
      _showSnack('${category.name} deleted.');
      _fetchCategories();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // Likely FK violation — items still reference this category
      final msg = e.code == '23503'
          ? 'Cannot delete: items still use this category.'
          : e.message;
      _showSnack(msg, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Delete failed. Please try again.', error: true);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  Future<bool> _showDeleteDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.getSurface(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            content: Text(
              'Are you sure you want to delete "$name"? This cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openAddCategory() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditCategoryScreen(),
      ),
    );
    if (created == true) _fetchCategories();
  }

  Future<void> _openEditCategory(Category category) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCategoryScreen(category: category),
      ),
    );
    if (updated == true) _fetchCategories();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.getTextSecondary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppTheme.getTextSecondary(context), size: 22),
            onPressed: _fetchCategories,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategory,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.getTextHint(context)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.category_rounded,
                  size: 36, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Categories Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add Category" to create your first one.',
              style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchCategories,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CategoryTile(
          category: _categories[i],
          onEdit: () => _openEditCategory(_categories[i]),
          onDelete: () => _deleteCategory(_categories[i]),
        ),
      ),
    );
  }
}

// ── Category Tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const tileColor = Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tileColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category_rounded,
                size: 22, color: tileColor),
          ),
          const SizedBox(width: 14),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (category.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (category.description != null &&
                    category.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    category.description!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.getTextSecondary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (!category.isDefault) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: AppTheme.getTextSecondary(context)),
              onPressed: onEdit,
              tooltip: 'Edit',
              splashRadius: 20,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppTheme.errorColor),
              onPressed: onDelete,
              tooltip: 'Delete',
              splashRadius: 20,
            ),
          ] else ...[
            // Default category — only allow editing
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: AppTheme.getTextSecondary(context)),
              onPressed: onEdit,
              tooltip: 'Edit',
              splashRadius: 20,
            ),
          ],
        ],
      ),
    );
  }
}