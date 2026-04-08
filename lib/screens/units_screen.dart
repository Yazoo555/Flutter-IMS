import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'add_unit_screen.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class UnitModel {
  final String id;
  final String name;
  final String abbreviation;

  const UnitModel({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
        id: json['id'] as String,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<UnitModel> _units = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('units')
          .select('id, name, abbreviation')
          .order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _units = (data as List)
            .map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load units. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirmed = await _showDeleteDialog(unit.name, unit.abbreviation);
    if (!confirmed) return;

    try {
      await supabase.from('units').delete().eq('id', unit.id);
      if (!mounted) return;
      _showSnack('${unit.name} deleted.');
      _fetchUnits();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.code == '23503'
          ? 'Cannot delete: items still use this unit.'
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

  Future<bool> _showDeleteDialog(String name, String abbreviation) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Delete Unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '$name ($abbreviation)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const TextSpan(text: '? This cannot be undone.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
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

  Future<void> _openAddUnit() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddUnitScreen()),
    );
    if (created == true) {
      _showSnack('Unit added.');
      _fetchUnits();
    }
  }

  Future<void> _openEditUnit(UnitModel unit) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddUnitScreen(unit: unit)),
    );
    if (updated == true) {
      _showSnack('Unit updated.');
      _fetchUnits();
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Units',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary, size: 22),
            onPressed: _fetchUnits,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddUnit,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Unit',
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
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.textHint),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUnits,
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

    if (_units.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.straighten_rounded,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Units Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Add Unit" to create your first one.',
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchUnits,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _units.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _UnitTile(
          unit: _units[i],
          onEdit: () => _openEditUnit(_units[i]),
          onDelete: () => _deleteUnit(_units[i]),
        ),
      ),
    );
  }
}

// ── Unit Tile ─────────────────────────────────────────────────────────────────

class _UnitTile extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitTile({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Abbreviation badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                unit.abbreviation,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + abbreviation label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Abbreviation: ${unit.abbreviation}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppTheme.textSecondary),
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
        ],
      ),
    );
  }
}