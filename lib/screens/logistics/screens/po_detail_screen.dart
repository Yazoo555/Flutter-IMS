import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../models/purchase_order.dart';
import '../services/logistics_service.dart';
import '../widgets/status_chip.dart';
import '../widgets/po_line_item_card.dart';
import '../widgets/receive_goods_dialog.dart';

class PODetailScreen extends StatefulWidget {
  final String purchaseOrderId;
  final VoidCallback onDataChanged;
  const PODetailScreen({super.key, required this.purchaseOrderId, required this.onDataChanged});
  @override
  State<PODetailScreen> createState() => _PODetailScreenState();
}

class _PODetailScreenState extends State<PODetailScreen> {
  PurchaseOrder? _po;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final po = await LogisticsService.getPurchaseOrder(widget.purchaseOrderId);
      if (!mounted) return;
      setState(() { _po = po; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load PO.'; _isLoading = false; });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppTheme.errorColor : AppTheme.primary),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      await LogisticsService.updatePOStatus(widget.purchaseOrderId, status);
      _snack('Status updated to $status');
      widget.onDataChanged();
      _fetch();
    } catch (e) {
      _snack('Update failed.', error: true);
    }
  }

  Future<void> _receiveGoods() async {
    if (_po == null || _po!.items == null || _po!.items!.isEmpty) return;
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => ReceiveGoodsDialog(items: _po!.items!),
    );
    if (result == null || result.isEmpty) return;
    try {
      await LogisticsService.receiveGoods(
        purchaseOrderId: widget.purchaseOrderId,
        userId: supabase.auth.currentUser!.id,
        items: result,
      );
      _snack('Goods received successfully!');
      widget.onDataChanged();
      _fetch();
    } catch (e) {
      _snack('Receive failed: $e', error: true);
    }
  }

  Future<void> _addLineItem() async {
    final created = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => _AddLineItemScreen(poId: widget.purchaseOrderId)));
    if (created == true) _fetch();
  }

  Future<void> _editLineItem(PurchaseOrderItem item) async {
    final updated = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => _EditLineItemScreen(item: item)));
    if (updated == true) _fetch();
  }

  Future<void> _deleteLineItem(PurchaseOrderItem item) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text('Remove "${item.itemName}" from this PO?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600))),
      ],
    ));
    if (ok != true) return;
    try {
      await LogisticsService.deletePOItem(item.id);
      _snack('Item removed.'); _fetch();
    } catch (e) { _snack('Delete failed.', error: true); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final tp = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final ts = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final brd = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('PO Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.textHint),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _fetch, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Retry', style: TextStyle(color: Colors.white))),
                ]))
              : RefreshIndicator(
                  color: AppTheme.primary, onRefresh: _fetch,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
                    _headerCard(surf, brd, tp, ts, isDark),
                    const SizedBox(height: 16),
                    _infoSection(surf, brd, tp, ts),
                    const SizedBox(height: 20),
                    _actionButtons(ts),
                    const SizedBox(height: 20),
                    _lineItemsSection(tp, ts),
                  ]),
                ),
    );
  }

  Widget _headerCard(Color surf, Color brd, Color tp, Color ts, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: brd)),
      child: Row(children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(color: isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.receipt_long_rounded, size: 28, color: AppTheme.primary)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(_po!.poNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp))),
            const SizedBox(width: 8),
            StatusChip(status: _po!.status),
          ]),
          const SizedBox(height: 4),
          Text(_po!.supplierName, style: TextStyle(fontSize: 13, color: ts)),
        ])),
      ]),
    );
  }

  Widget _infoSection(Color surf, Color brd, Color tp, Color ts) {
    String fmt(String? d) { if (d == null) return 'N/A'; try { return DateFormat('MMM d, y').format(DateTime.parse(d)); } catch (_) { return d; } }
    return Container(
      decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(12), border: Border.all(color: brd)),
      child: Column(children: [
        _row('Order Date', fmt(_po!.orderDate), tp, ts),
        Divider(height: 1, color: brd),
        _row('Expected Date', fmt(_po!.expectedDate), tp, ts),
        Divider(height: 1, color: brd),
        _row('Total Amount', 'Rs. ${_po!.totalAmount.toStringAsFixed(2)}', tp, ts, highlight: true),
        if (_po!.notes != null && _po!.notes!.isNotEmpty) ...[
          Divider(height: 1, color: brd),
          _row('Notes', _po!.notes!, tp, ts),
        ],
      ]),
    );
  }

  Widget _row(String label, String value, Color tp, Color ts, {bool highlight = false}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 14, color: ts)),
        Flexible(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500, color: highlight ? AppTheme.primary : tp), textAlign: TextAlign.end)),
      ]));
  }

  Widget _actionButtons(Color ts) {
    final canReceive = _po!.status == 'confirmed' || _po!.status == 'partially_received';
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _actionBtn(Icons.update_rounded, 'Update Status', () => _showStatusPicker(), const Color(0xFF3B82F6)),
      if (canReceive)
        _actionBtn(Icons.move_to_inbox_rounded, 'Receive Goods', _receiveGoods, const Color(0xFF10B981)),
      _actionBtn(Icons.add_rounded, 'Add Item', _addLineItem, AppTheme.primary),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
    );
  }

  void _showStatusPicker() {
    final statuses = ['draft', 'confirmed', 'partially_received', 'received', 'cancelled'];
    showModalBottomSheet(context: context, backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ...statuses.map((s) => ListTile(
          leading: StatusChip(status: s),
          title: Text(s.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 14)),
          selected: _po!.status == s,
          onTap: () { Navigator.pop(ctx); _updateStatus(s); },
        )),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _lineItemsSection(Color tp, Color ts) {
    final items = _po!.items ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LINE ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ts, letterSpacing: 0.8)),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Text('No line items yet.', style: TextStyle(fontSize: 14, color: ts))))
      else
        ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: POLineItemCard(item: item, onEdit: () => _editLineItem(item), onDelete: () => _deleteLineItem(item)))),
    ]);
  }
}

// ── Add Line Item Screen ─────────────────────────────────────────────────────

class _AddLineItemScreen extends StatefulWidget {
  final String poId;
  const _AddLineItemScreen({required this.poId});
  @override
  State<_AddLineItemScreen> createState() => _AddLineItemScreenState();
}

class _AddLineItemScreenState extends State<_AddLineItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String? _selectedItemId;
  bool _isLoading = true, _isSaving = false;

  @override
  void initState() { super.initState(); _loadItems(); }

  @override
  void dispose() { _qtyController.dispose(); _priceController.dispose(); super.dispose(); }

  Future<void> _loadItems() async {
    try {
      final data = await LogisticsService.getItemsDropdown();
      if (!mounted) return;
      setState(() { _items = data; _isLoading = false; });
    } catch (_) { if (!mounted) return; setState(() => _isLoading = false); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedItemId == null) return;
    setState(() => _isSaving = true);
    try {
      await LogisticsService.addPOItem({
        'purchase_order_id': widget.poId,
        'item_id': _selectedItemId,
        'quantity_ordered': double.tryParse(_qtyController.text) ?? 0,
        'unit_price': double.tryParse(_priceController.text) ?? 0,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final tp = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final ts = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final brd = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Add Line Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp))),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: brd)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Item *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedItemId,
                    items: _items.map((it) => DropdownMenuItem(value: it['id'] as String, child: Text('${it['name']}${it['sku'] != null ? ' (${it['sku']})' : ''}'))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedItemId = v);
                      final sel = _items.firstWhere((it) => it['id'] == v, orElse: () => {});
                      if (sel.isNotEmpty && _priceController.text.isEmpty) {
                        _priceController.text = (sel['purchase_price'] as num?)?.toStringAsFixed(2) ?? '';
                      }
                    },
                    hint: Text('Select item', style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint)),
                    style: TextStyle(fontSize: 14, color: tp), dropdownColor: surf,
                    decoration: _dec(isDark, brd, surf),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                      const SizedBox(height: 6),
                      TextFormField(controller: _qtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (double.tryParse(v) == null) return 'Invalid'; return null; },
                        style: TextStyle(fontSize: 14, color: tp), decoration: _dec(isDark, brd, surf, hint: '0')),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Unit Price *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                      const SizedBox(height: 6),
                      TextFormField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (double.tryParse(v) == null) return 'Invalid'; return null; },
                        style: TextStyle(fontSize: 14, color: tp), decoration: _dec(isDark, brd, surf, hint: '0.00')),
                    ])),
                  ]),
                ])),
              const SizedBox(height: 32),
              SizedBox(height: 52, child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.primary.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
            ])),
    );
  }

  InputDecoration _dec(bool isDark, Color brd, Color surf, {String hint = ''}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
    filled: true, fillColor: surf, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5)),
  );
}

// ── Edit Line Item Screen ────────────────────────────────────────────────────

class _EditLineItemScreen extends StatefulWidget {
  final PurchaseOrderItem item;
  const _EditLineItemScreen({required this.item});
  @override
  State<_EditLineItemScreen> createState() => _EditLineItemScreenState();
}

class _EditLineItemScreenState extends State<_EditLineItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.quantityOrdered.toStringAsFixed(widget.item.quantityOrdered % 1 == 0 ? 0 : 2));
    _priceController = TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
  }

  @override
  void dispose() { _qtyController.dispose(); _priceController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await LogisticsService.updatePOItem(widget.item.id, {
        'quantity_ordered': double.tryParse(_qtyController.text) ?? 0,
        'unit_price': double.tryParse(_priceController.text) ?? 0,
      });
      if (!mounted) return; Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final tp = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final ts = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final brd = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Edit Line Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp))),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: brd)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.item.itemName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)), const SizedBox(height: 6),
                TextFormField(controller: _qtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Invalid' : null,
                  style: TextStyle(fontSize: 14, color: tp),
                  decoration: InputDecoration(filled: true, fillColor: surf, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)))),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Unit Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)), const SizedBox(height: 6),
                TextFormField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Invalid' : null,
                  style: TextStyle(fontSize: 14, color: tp),
                  decoration: InputDecoration(filled: true, fillColor: surf, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)))),
              ])),
            ]),
          ])),
        const SizedBox(height: 32),
        SizedBox(height: 52, child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.primary.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Update Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
      ])),
    );
  }
}
