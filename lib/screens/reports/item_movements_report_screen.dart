import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart'; // for supabase client
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';

class ItemMovementsReportScreen extends StatefulWidget {
  const ItemMovementsReportScreen({super.key});

  @override
  State<ItemMovementsReportScreen> createState() =>
      _ItemMovementsReportScreenState();
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
                // stub out required fields not needed for dropdown
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
      final data = await supabase.rpc('get_stock_movements_by_date', params: {
        'p_item_id': _selectedItemId,
        'p_start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'p_end_date': DateFormat('yyyy-MM-dd').format(_endDate),
      });

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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Item Movements',
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
          const Text('Date Range',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDateRange(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const Icon(Icons.date_range_rounded, color: AppTheme.textHint),
                ],
              ),
            ),
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

    if (_selectedItemId == null) {
      return const Center(
        child: Text('Select an item to view movements.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    if (_movements.isEmpty) {
      return const Center(
        child: Text('No movements found for this item in selected date range.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: DataTable(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Notes')),
            ],
            rows: _movements.map((move) {
              final isDeficit = move.type == 'sale' || move.type == 'damage';
              final color = _getColorForMovement(move.type);
              return DataRow(cells: [
                DataCell(Text(DateFormat('MMM dd, yyyy').format(move.createdAt))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      move.type.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(Text(
                  '${isDeficit ? '-' : '+'}${move.quantity}',
                  style: TextStyle(color: isDeficit ? AppTheme.errorColor : color, fontWeight: FontWeight.bold),
                )),
                DataCell(Text(move.notes ?? '-')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
