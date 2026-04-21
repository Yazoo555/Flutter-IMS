import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../models/shipment.dart';
import '../models/purchase_order.dart';
import '../services/logistics_service.dart';
import '../widgets/status_chip.dart';
import 'shipment_detail_screen.dart';

class ShipmentsTab extends StatefulWidget {
  const ShipmentsTab({super.key});
  @override
  State<ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<ShipmentsTab> {
  List<Shipment> _shipments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await LogisticsService.getShipments();
      if (!mounted) return;
      setState(() { _shipments = data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load shipments.'; _isLoading = false; });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const _CreateShipmentScreen()));
    if (created == true) _fetch();
  }

  Future<void> _openDetail(Shipment s) async {
    final result = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipment: s, onDataChanged: _fetch)));
    if (result == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate, backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Shipment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.textHint), const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)), const SizedBox(height: 20),
      ElevatedButton(onPressed: _fetch, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Retry', style: TextStyle(color: Colors.white)))])));
    if (_shipments.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.local_shipping_rounded, size: 36, color: AppTheme.primary)),
      const SizedBox(height: 16),
      Text('No Shipments Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text('Tap "New Shipment" to track a delivery.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center)]));

    return RefreshIndicator(color: AppTheme.primary, onRefresh: _fetch,
      child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 12, 16, 120), itemCount: _shipments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ShipmentCard(shipment: _shipments[i], onTap: () => _openDetail(_shipments[i]), isDark: isDark)));
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment shipment; final VoidCallback onTap; final bool isDark;
  const _ShipmentCard({required this.shipment, required this.onTap, required this.isDark});

  String _fmt(String? d) { if (d == null) return 'N/A'; try { return DateFormat('MMM d, y').format(DateTime.parse(d)); } catch (_) { return d; } }

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final brd = isDark ? AppTheme.darkBorder : AppTheme.border;
    final tp = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final ts = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;

    return GestureDetector(onTap: onTap, child: Container(
      decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: brd)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping_rounded, size: 24, color: AppTheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(shipment.trackingNumber ?? 'No Tracking #', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tp), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              StatusChip(status: shipment.status, type: StatusChipType.shipment),
            ]),
            const SizedBox(height: 3),
            Text(shipment.supplierName, style: TextStyle(fontSize: 12, color: ts)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 20, color: ts),
        ])),
        Container(
          decoration: BoxDecoration(color: bgColor.withOpacity(0.5), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _Badge(label: 'Carrier', value: shipment.carrier ?? 'N/A', color: const Color(0xFF6366F1)),
            const SizedBox(width: 14),
            _Badge(label: 'Shipped', value: _fmt(shipment.shippedDate), color: const Color(0xFF3B82F6)),
            const SizedBox(width: 14),
            _Badge(label: 'ETA', value: _fmt(shipment.estimatedArrival), color: const Color(0xFFF59E0B)),
          ])),
      ])));
  }
}

class _Badge extends StatelessWidget {
  final String label, value; final Color color;
  const _Badge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  ]);
}

// ── Create Shipment Screen ───────────────────────────────────────────────────

class _CreateShipmentScreen extends StatefulWidget {
  const _CreateShipmentScreen();
  @override
  State<_CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<_CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carrierCtrl = TextEditingController();
  final _trackingCtrl = TextEditingController();
  List<PurchaseOrder> _pos = [];
  String? _selectedPoId;
  DateTime? _shippedDate, _estimatedArrival;
  bool _isLoading = true, _isSaving = false;

  @override
  void initState() { super.initState(); _shippedDate = DateTime.now(); _estimatedArrival = DateTime.now().add(const Duration(days: 3)); _loadPOs(); }
  @override
  void dispose() { _carrierCtrl.dispose(); _trackingCtrl.dispose(); super.dispose(); }

  Future<void> _loadPOs() async {
    try { final data = await LogisticsService.getConfirmedPOs(); if (!mounted) return; setState(() { _pos = data; _isLoading = false; }); }
    catch (_) { if (!mounted) return; setState(() => _isLoading = false); }
  }

  Future<void> _pickDate(bool isShipped) async {
    final picked = await showDatePicker(context: context, initialDate: isShipped ? (_shippedDate ?? DateTime.now()) : (_estimatedArrival ?? DateTime.now()),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: AppTheme.primary)), child: child!));
    if (picked == null) return;
    setState(() { if (isShipped) _shippedDate = picked; else _estimatedArrival = picked; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedPoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: AppTheme.errorColor)); return; }
    setState(() => _isSaving = true);
    try {
      await LogisticsService.createShipment({
        'user_id': supabase.auth.currentUser!.id, 'purchase_order_id': _selectedPoId, 'status': 'pending',
        'carrier': _carrierCtrl.text.trim().isEmpty ? null : _carrierCtrl.text.trim(),
        'tracking_number': _trackingCtrl.text.trim().isEmpty ? null : _trackingCtrl.text.trim(),
        'shipped_date': _shippedDate != null ? DateFormat('yyyy-MM-dd').format(_shippedDate!) : null,
        'estimated_arrival': _estimatedArrival != null ? DateFormat('yyyy-MM-dd').format(_estimatedArrival!) : null,
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

    return Scaffold(backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Create Shipment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp))),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: brd)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Purchase Order *', ts), const SizedBox(height: 6),
                  DropdownButtonFormField<String>(value: _selectedPoId,
                    items: _pos.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.poNumber} — ${p.supplierName}'))).toList(),
                    onChanged: (v) => setState(() => _selectedPoId = v),
                    hint: Text('Select PO', style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint)),
                    style: TextStyle(fontSize: 14, color: tp), dropdownColor: surf, decoration: _dec(isDark, brd, surf)),
                  const SizedBox(height: 16),
                  _lbl('Carrier', ts), const SizedBox(height: 6),
                  TextFormField(controller: _carrierCtrl, style: TextStyle(fontSize: 14, color: tp), decoration: _dec(isDark, brd, surf, hint: 'e.g. Bagmati Logistics')),
                  const SizedBox(height: 16),
                  _lbl('Tracking Number', ts), const SizedBox(height: 6),
                  TextFormField(controller: _trackingCtrl, style: TextStyle(fontSize: 14, color: tp), decoration: _dec(isDark, brd, surf, hint: 'e.g. TRK-20260421')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _dateField('Shipped Date', _shippedDate, () => _pickDate(true), isDark, tp, ts, brd, surf)),
                    const SizedBox(width: 16),
                    Expanded(child: _dateField('Est. Arrival', _estimatedArrival, () => _pickDate(false), isDark, tp, ts, brd, surf)),
                  ]),
                ])),
              const SizedBox(height: 32),
              SizedBox(height: 52, child: ElevatedButton(onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.primary.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Shipment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
            ])),
    );
  }

  Widget _lbl(String t, Color c) => Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c));

  InputDecoration _dec(bool isDark, Color brd, Color surf, {String hint = ''}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
    filled: true, fillColor: surf, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brd)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)));

  Widget _dateField(String label, DateTime? date, VoidCallback onTap, bool isDark, Color tp, Color ts, Color brd, Color surf) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(label, ts), const SizedBox(height: 6),
      GestureDetector(onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(10), border: Border.all(color: brd)),
        child: Row(children: [
          Expanded(child: Text(date != null ? DateFormat('MMM d, y').format(date) : 'Select', style: TextStyle(fontSize: 14, color: date != null ? tp : (isDark ? AppTheme.darkTextHint : AppTheme.textHint)))),
          Icon(Icons.calendar_today_rounded, size: 16, color: ts),
        ])))]);
  }
}
