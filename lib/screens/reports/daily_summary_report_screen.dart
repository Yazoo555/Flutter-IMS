import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';
import '../../utils/report_pdf_helper.dart';

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

  final _fmt = NumberFormat('#,##0', 'en_US');

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
                userId: '',
                categoryId: '',
                unitId: '',
                openingStock: 0,
                currentStock: 0,
                purchasePrice: 0,
                salesPrice: 0,
                isActive: true,
                createdAt: DateTime.now(),
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
      final data =
          await supabase.rpc('get_daily_summary_with_value', params: {
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
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        title: Text('Daily Summary',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.getTextPrimary(context))),
        backgroundColor: AppTheme.getSurface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getTextPrimary(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: (_summaries.isEmpty || _selectedItemId == null)
                ? null
                : () {
                    final itemName = _items.firstWhere((i) => i.id == _selectedItemId).name;
                    ReportPdfHelper.generateDailySummaryPdf(_summaries, itemName, _daysBack);
                  },
          ),
          const SizedBox(width: 8),
        ],
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
      color: AppTheme.getSurface(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Item',
              style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.getBorder(context)),
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
              Text('Days History:',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
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
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.getTextHint(context)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.getTextSecondary(context))),
            ],
          ),
        ),
      );
    }

    if (_selectedItemId == null) {
      return Center(
        child: Text('Select an item to view summary.',
            style: TextStyle(color: AppTheme.getTextSecondary(context))),
      );
    }

    if (_summaries.isEmpty) {
      return Center(
        child: Text('No daily summary data found.',
            style: TextStyle(color: AppTheme.getTextSecondary(context))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final s = _summaries[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.getBorder(context), width: 1),
          ),
          color: AppTheme.getSurface(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date header ─────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.darkPrimaryLighter 
                          : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(s.date),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primary),
                          ),
                          Text(
                            DateFormat('MMM').format(s.date),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(s.date),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.getTextPrimary(context)),
                        ),
                        const SizedBox(height: 2),
                        // Qty badges
                        Wrap(
                          spacing: 6,
                          children: [
                            if (s.totalPurchasedQty > 0)
                              _qtyBadge('IN',
                                  s.totalPurchasedQty, const Color(0xFF10B981)),
                            if (s.totalSoldQty > 0)
                              _qtyBadge(
                                  'OUT', s.totalSoldQty, AppTheme.errorColor),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Gross profit pill
                    _profitPill(s.grossProfit),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.getBorder(context)),
                const SizedBox(height: 14),
                // ── Value metrics (2×2 grid) ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _valueStat(
                        'Purchase Value',
                        'Rs ${_fmt.format(s.purchaseValue)}',
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _valueStat(
                        'Sales Value',
                        'Rs ${_fmt.format(s.salesValue)}',
                        const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _valueStat(
                        'Closing Stock',
                        '${s.closingStockQty % 1 == 0 ? s.closingStockQty.toInt() : s.closingStockQty} units',
                        const Color(0xFFF59E0B), // Amber
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _valueStat(
                        'Stock Value',
                        'Rs ${_fmt.format(s.closingStockValue)}',
                        const Color(0xFF3B82F6), // Blue
                        bold: true,
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

  Widget _qtyBadge(String label, double val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${val % 1 == 0 ? val.toInt() : val}',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _profitPill(double profit) {
    final isPositive = profit >= 0;
    final color = isPositive ? const Color(0xFF10B981) : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Rs ${_fmt.format(profit)}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _valueStat(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: valueColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: valueColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.getTextSecondary(context),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
