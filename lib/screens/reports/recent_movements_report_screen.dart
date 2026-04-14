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
  List<RecentMovement> _movements = [];
  String _filter = 'recent'; // 'recent' or 'today'

  final _fmt = NumberFormat('#,##0', 'en_US');

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
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final tomorrowStr =
          DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

      final query = supabase.from('recent_movements_with_value').select('*');

      final data = _filter == 'today'
          ? await query
              .gte('created_at', todayStr)
              .lt('created_at', tomorrowStr)
              .order('created_at', ascending: false)
          : await query
              .order('created_at', ascending: false)
              .limit(20);

      if (!mounted) return;

      final movements = (data as List)
          .map((e) => RecentMovement.fromJson(e as Map<String, dynamic>))
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

  Color _colorForType(String type) {
    switch (type) {
      case 'purchase':
        return const Color(0xFF10B981);
      case 'sale':
        return const Color(0xFF6366F1);
      case 'adjustment':
        return const Color(0xFFF59E0B);
      case 'return':
        return const Color(0xFF0EA5E9);
      case 'damage':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'purchase':
        return Icons.add_shopping_cart_rounded;
      case 'sale':
        return Icons.point_of_sale_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      case 'return':
        return Icons.keyboard_return_rounded;
      case 'damage':
        return Icons.warning_amber_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final move = _movements[index];
        final isDeficit =
            move.movementType == 'sale' || move.movementType == 'damage';
        final color = _colorForType(move.movementType);

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.border, width: 1),
          ),
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconForType(move.movementType),
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            move.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy  HH:mm')
                                .format(move.createdAt.toLocal()),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        move.movementType.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Divider ──────────────────────────────────────────────────
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 10),
                // ── Value row ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric(
                      'Qty',
                      '${isDeficit ? '-' : '+'}${move.quantity % 1 == 0 ? move.quantity.toInt() : move.quantity}',
                      isDeficit ? AppTheme.errorColor : color,
                    ),
                    _buildMetric(
                      'Purchase Price',
                      'Rs ${_fmt.format(move.purchasePrice)}',
                      AppTheme.textPrimary,
                    ),
                    _buildMetric(
                      'Sales Price',
                      'Rs ${_fmt.format(move.salesPrice)}',
                      AppTheme.textPrimary,
                    ),
                    _buildMetric(
                      'Value',
                      'Rs ${_fmt.format(move.transactionValue)}',
                      isDeficit ? AppTheme.errorColor : const Color(0xFF10B981),
                      bold: true,
                    ),
                  ],
                ),
                if (move.reference != null && move.reference!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.label_outline_rounded,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(
                        move.reference!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (move.notes != null && move.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          move.notes!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
