import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';
import '../../utils/report_pdf_helper.dart';

class ItemMovementsReportScreen extends StatefulWidget {
  const ItemMovementsReportScreen({super.key});
  @override
  State<ItemMovementsReportScreen> createState() => _ItemMovementsReportScreenState();
}

class _ItemMovementsReportScreenState extends State<ItemMovementsReportScreen> {
  bool _isLoading = false;
  String? _error;
  List<StockMovementReport> _movements = [];
  List<InventoryItem> _items = [];
  String? _selectedItemId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() { super.initState(); _fetchItems(); }

  Future<void> _fetchItems() async {
    try {
      final data = await supabase.from('items').select('id, name').order('name', ascending: true);
      if (!mounted) return;
      final items = (data as List).map((e) => InventoryItem(id: e['id'], name: e['name'], userId: '', categoryId: '', unitId: '', openingStock: 0, currentStock: 0, purchasePrice: 0, salesPrice: 0, isActive: true, createdAt: DateTime.now())).toList();
      setState(() { _items = items; if (items.isNotEmpty) { _selectedItemId = items.first.id; _fetchReport(); } });
    } catch (e) { if (!mounted) return; setState(() => _error = 'Failed to load items.'); }
  }

  Future<void> _fetchReport() async {
    if (_selectedItemId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await supabase.rpc('get_stock_movements_by_date', params: { 'p_item_id': _selectedItemId, 'p_start_date': DateFormat('yyyy-MM-dd').format(_startDate), 'p_end_date': DateFormat('yyyy-MM-dd').format(_endDate) });
      if (!mounted) return;
      final movements = (data as List).map((e) => StockMovementReport.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _movements = movements; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'Failed to load report data.'; _isLoading = false; }); }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final c = context.colors;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020), lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary)),
          child: child!,
        );
      },
    );
    if (picked != null) { setState(() { _startDate = picked.start; _endDate = picked.end; }); _fetchReport(); }
  }

  Color _getColorForMovement(String type) {
    if (type == 'purchase') return const Color(0xFF10B981);
    if (type == 'sale') return const Color(0xFF6366F1);
    if (type == 'adjustment') return const Color(0xFFF59E0B);
    if (type == 'return') return const Color(0xFF0EA5E9);
    if (type == 'damage') return const Color(0xFFEF4444);
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('Item Movements', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: c.textPrimary)),
        backgroundColor: c.surface, elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded),
            onPressed: (_movements.isEmpty || _selectedItemId == null) ? null : () {
              final itemName = _items.firstWhere((i) => i.id == _selectedItemId).name;
              ReportPdfHelper.generateItemMovementsPdf(_movements, itemName, _startDate, _endDate);
            }),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [_buildControls(), Expanded(child: _buildBody())]),
    );
  }

  Widget _buildControls() {
    final c = context.colors;
    return Container(
      color: c.surface, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select Item', style: TextStyle(fontSize: 14, color: c.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedItemId, isExpanded: true,
              hint: Text('Select an item', style: TextStyle(color: c.textHint)),
              dropdownColor: c.surface,
              items: _items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, style: TextStyle(color: c.textPrimary)))).toList(),
              onChanged: (val) { if (val != null) { setState(() => _selectedItemId = val); _fetchReport(); } },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Date Range', style: TextStyle(fontSize: 14, color: c.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateRange(context), borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}', style: TextStyle(fontSize: 14, color: c.textPrimary)),
              Icon(Icons.date_range_rounded, color: c.textHint),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    final c = context.colors;
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, size: 48, color: c.textHint), const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
    ])));
    if (_selectedItemId == null) return Center(child: Text('Select an item to view movements.', style: TextStyle(color: c.textSecondary)));
    if (_movements.isEmpty) return Center(child: Text('No movements found for this item in selected date range.', style: TextStyle(color: c.textSecondary)));

    return SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: ConstrainedBox(constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary),
          dataTextStyle: TextStyle(color: c.textPrimary),
          columns: const [DataColumn(label: Text('Date')), DataColumn(label: Text('Type')), DataColumn(label: Text('Qty'), numeric: true), DataColumn(label: Text('Notes'))],
          rows: _movements.map((move) {
            final isDeficit = move.type == 'sale' || move.type == 'damage';
            final color = _getColorForMovement(move.type);
            return DataRow(cells: [
              DataCell(Text(DateFormat('MMM dd, yyyy').format(move.createdAt))),
              DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(move.type.toUpperCase(), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)))),
              DataCell(Text('${isDeficit ? '-' : '+'}${move.quantity}', style: TextStyle(color: isDeficit ? AppTheme.errorColor : color, fontWeight: FontWeight.bold))),
              DataCell(Text(move.notes ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    ));
  }
}
