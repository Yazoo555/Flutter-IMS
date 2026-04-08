import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  static const _baseUrl =
      'https://zinognrruckgcmrxgzro.supabase.co/rest/v1/units';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inppbm9nbnJydWNrZ2NtcnhnenJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MDY4ODIsImV4cCI6MjA5MDE4Mjg4Mn0.l1fN3dKA_b3QAIIfQrAuSf_h_tRuoElR-9vPSew_aeA';

  List<UnitModel> _units = [];
  bool _isLoading = true;
  String? _error;

  String get _accessToken =>
      supabase.auth.currentSession?.accessToken ?? _anonKey;

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _fetchUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          '$_baseUrl?select=id,name,abbreviation&order=name.asc');
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _units = data.map((e) => UnitModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load units (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<bool> _createUnit(String name, String abbreviation) async {
    final userId = supabase.auth.currentUser?.id ?? '';
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'abbreviation': abbreviation,
        'created_by': userId,
      }),
    );
    return res.statusCode == 201;
  }

  Future<bool> _updateUnit(String id, String name, String abbreviation) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl?id=eq.$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'abbreviation': abbreviation}),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<bool> _deleteUnit(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl?id=eq.$id'),
      headers: _headers,
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  // ── Navigation Methods ─────────────────────────────────────────────────────

  Future<void> _addUnit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddUnitScreen(
          onSave: (name, abbreviation) async {
            return await _createUnit(name, abbreviation);
          },
        ),
      ),
    );

    if (result == true) {
      await _fetchUnits();
      _showSnack('Unit added.');
    }
  }

  Future<void> _editUnit(UnitModel unit) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddUnitScreen(
          unitId: unit.id,
          initialName: unit.name,
          initialAbbreviation: unit.abbreviation,
          onSave: (name, abbreviation) async {
            return await _updateUnit(unit.id, name, abbreviation);
          },
        ),
      ),
    );

    if (result == true) {
      await _fetchUnits();
      _showSnack('Unit updated.');
    }
  }

  Future<void> _confirmDelete(UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Unit',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: '${unit.name} (${unit.abbreviation})',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
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
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await _deleteUnit(unit.id);
    if (ok) {
      await _fetchUnits();
      _showSnack('Unit deleted.');
    } else {
      _showSnack('Failed to delete. Please try again.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppTheme.border,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Units',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUnit,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchUnits,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
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
            const Text('No Units Yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Add your first measurement unit to get started.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              onPressed: _addUnit,
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: Colors.white),
              label: const Text('Add Unit',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchUnits,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _units.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _UnitTile(
          unit: _units[i],
          onEdit: () => _editUnit(_units[i]),
          onDelete: () => _confirmDelete(_units[i]),
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryLighter,
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
        title: Text(
          unit.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          'Abbreviation: ${unit.abbreviation}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 20, color: AppTheme.primary),
              tooltip: 'Edit',
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                fixedSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppTheme.errorColor),
              tooltip: 'Delete',
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                fixedSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}