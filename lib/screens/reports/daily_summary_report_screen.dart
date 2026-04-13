import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';

class DailySummaryReportScreen extends StatefulWidget {
  const DailySummaryReportScreen({super.key});

  @override
  State<DailySummaryReportScreen> createState() =>
      _DailySummaryReportScreenState();
}

class _DailySummaryReportScreenState extends State<DailySummaryReportScreen> {
  bool _isLoading = false;
  String? _error;
  List<DailyStockSummary> _summaries = [];
  
  List<InventoryItem> _items = [];
  String? _selectedItemId;
  int _daysBack = 30;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final data = await supabase
          .from('items')
          .select('id, name')
          .order('name', ascending: true);

      if (!mounted) return;
      
      final items = (data as List)
          .map((e) => InventoryItem(
                id: e['id'],
                name: e['name'],
                userId: '', categoryId: '', unitId: '',
                openingStock: 0, currentStock: 0,
                purchasePrice: 0, salesPrice: 0,
                isActive: true, createdAt: DateTime.now(),
              ))
          .toList();

      setState(() {
        _items = items;
        if (items.isNotEmpty) {
          _selectedItemId = items.first.id;
          _fetchReport();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load items.');
    }
  }

  Future<void> _fetchReport() async {
    if (_selectedItemId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await supabase.rpc('get_daily_stock_summary', params: {
        'p_item_id': _selectedItemId,
        'p_days_back': _daysBack,
      });

      if (!mounted) return;

      final summaries = (data as List)
          .map((e) => DailyStockSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _summaries = summaries;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Daily Summary',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Item',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedItemId,
                isExpanded: true,
                hint: const Text('Select an item'),
                items: _items.map((item) {
                  return DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedItemId = val);
                    _fetchReport();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Days History:',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              DropdownButton<int>(
                value: _daysBack,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 14, child: Text('Last 14 Days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _daysBack = val);
                    _fetchReport();
                  }
                },
              ),
            ],
          ),
        ],
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
            ],
          ),
        ),
      );
    }

    if (_summaries.isEmpty) {
      return const Center(
        child: Text('No daily summary data found.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final summary = _summaries[index];
        final isPositiveNet = summary.netChange >= 0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
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
                  width: 56,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(summary.date),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary),
                      ),
                      Text(
                        DateFormat('MMM').format(summary.date),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMiniStat('IN', summary.totalPurchased + summary.totalReturned, const Color(0xFF10B981)),
                          _buildMiniStat('OUT', summary.totalSold, AppTheme.errorColor),
                          if (summary.totalAdjusted != 0)
                            _buildMiniStat('ADJ', summary.totalAdjusted, const Color(0xFFF59E0B)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Closing: ${summary.closingStock}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Net Change',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositiveNet ? '+' : ''}${summary.netChange}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isPositiveNet
                            ? const Color(0xFF10B981)
                            : AppTheme.errorColor,
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

  Widget _buildMiniStat(String label, double val, Color color) {
    if (val == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $val',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
