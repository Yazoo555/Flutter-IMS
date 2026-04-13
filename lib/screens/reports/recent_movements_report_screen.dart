import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart'; // for supabase client
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';

class RecentMovementsReportScreen extends StatefulWidget {
  const RecentMovementsReportScreen({super.key});

  @override
  State<RecentMovementsReportScreen> createState() =>
      _RecentMovementsReportScreenState();
}

class _RecentMovementsReportScreenState
    extends State<RecentMovementsReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<StockMovementReport> _movements = [];
  String _filter = 'recent'; // 'recent' or 'today'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      final data = _filter == 'today'
          ? await supabase
              .from('stock_movements')
              .select('*, items(name)')
              .gte('created_at', dateStr)
              .lt('created_at', DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1))))
              .order('created_at', ascending: false)
          : await supabase
              .from('stock_movements')
              .select('*, items(name)')
              .order('created_at', ascending: false)
              .limit(20);

      if (!mounted) return;

      final movements = (data as List)
          .map((e) => StockMovementReport.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load report data.';
        _isLoading = false;
      });
    }
  }

  Color _getColorForMovement(String type) {
    if (type == 'purchase') return const Color(0xFF10B981);
    if (type == 'sale') return const Color(0xFF6366F1);
    if (type == 'adjustment') return const Color(0xFFF59E0B);
    if (type == 'return') return const Color(0xFF0EA5E9);
    if (type == 'damage') return const Color(0xFFEF4444);
    return AppTheme.textSecondary;
  }

  IconData _getIconForMovement(String type) {
    if (type == 'purchase') return Icons.add_shopping_cart_rounded;
    if (type == 'sale') return Icons.point_of_sale_rounded;
    if (type == 'adjustment') return Icons.tune_rounded;
    if (type == 'return') return Icons.keyboard_return_rounded;
    if (type == 'damage') return Icons.warning_amber_rounded;
    return Icons.swap_horiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Recent Movements',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          _buildFilterChip('Recent (Top 20)', 'recent'),
          const SizedBox(width: 8),
          _buildFilterChip('Today', 'today'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _fetchData();
        }
      },
      selectedColor: AppTheme.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movements.isEmpty) {
      return const Center(
        child: Text('No movements found.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _movements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final move = _movements[index];
        final isDeficit = move.type == 'sale' || move.type == 'damage';
        final color = _getColorForMovement(move.type);

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.border, width: 1),
          ),
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIconForMovement(move.type), color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        move.itemName ?? 'Unknown Item',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${move.type.toUpperCase()} • ${DateFormat('MMM dd, yyyy HH:mm').format(move.createdAt)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDeficit ? '-' : '+'}${move.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDeficit ? AppTheme.errorColor : color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
