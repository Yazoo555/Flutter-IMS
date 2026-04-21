import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../models/shipment.dart';
import '../services/logistics_service.dart';
import '../widgets/status_chip.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  final VoidCallback onDataChanged;
  const ShipmentDetailScreen({super.key, required this.shipment, required this.onDataChanged});
  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late Shipment _s;

  @override
  void initState() { super.initState(); _s = widget.shipment; }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppTheme.errorColor : AppTheme.primary));
  }

  Future<void> _markInTransit() async {
    try {
      await LogisticsService.updateShipmentStatus(_s.id, {'status': 'in_transit'});
      _snack('Marked as In Transit'); widget.onDataChanged(); Navigator.pop(context, true);
    } catch (e) { _snack('Update failed.', error: true); }
  }

  Future<void> _markDelivered() async {
    try {
      await LogisticsService.updateShipmentStatus(_s.id, {'status': 'delivered', 'actual_arrival': DateFormat('yyyy-MM-dd').format(DateTime.now())});
      _snack('Marked as Delivered'); widget.onDataChanged(); Navigator.pop(context, true);
    } catch (e) { _snack('Update failed.', error: true); }
  }

  Future<void> _markFailed() async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(controller: notesCtrl, maxLines: 3,
          decoration: InputDecoration(hintText: 'Reason for failure...', filled: true,
            fillColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirm', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600))),
        ]);
    });
    if (ok != true) return;
    try {
      await LogisticsService.updateShipmentStatus(_s.id, {'status': 'failed', 'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()});
      _snack('Marked as Failed'); widget.onDataChanged(); Navigator.pop(context, true);
    } catch (e) { _snack('Update failed.', error: true); }
  }

  String _fmt(String? d) { if (d == null) return 'N/A'; try { return DateFormat('MMM d, y').format(DateTime.parse(d)); } catch (_) { return d; } }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final tp = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final ts = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final brd = isDark ? AppTheme.darkBorder : AppTheme.border;
    final pl = isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight;

    return Scaffold(backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Shipment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp))),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: brd)),
          child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: pl, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_shipping_rounded, size: 28, color: AppTheme.primary)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(_s.trackingNumber ?? 'No Tracking #', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp))),
                const SizedBox(width: 8),
                StatusChip(status: _s.status, type: StatusChipType.shipment),
              ]),
              const SizedBox(height: 4),
              Text(_s.supplierName, style: TextStyle(fontSize: 13, color: ts)),
            ])),
          ])),
        const SizedBox(height: 20),

        // Info
        _secTitle('SHIPMENT INFORMATION', ts),
        Container(decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(12), border: Border.all(color: brd)),
          child: Column(children: [
            _infoRow('PO Number', _s.poNumber, tp, ts),
            Divider(height: 1, color: brd),
            _infoRow('Carrier', _s.carrier ?? 'N/A', tp, ts),
            Divider(height: 1, color: brd),
            _infoRow('Shipped Date', _fmt(_s.shippedDate), tp, ts),
            Divider(height: 1, color: brd),
            _infoRow('Est. Arrival', _fmt(_s.estimatedArrival), tp, ts),
            if (_s.actualArrival != null) ...[
              Divider(height: 1, color: brd),
              _infoRow('Actual Arrival', _fmt(_s.actualArrival), tp, ts, highlight: true),
            ],
            if (_s.notes != null && _s.notes!.isNotEmpty) ...[
              Divider(height: 1, color: brd),
              _infoRow('Notes', _s.notes!, tp, ts),
            ],
          ])),
        const SizedBox(height: 24),

        // Actions
        if (_s.status == 'pending') ...[
          _fullBtn('Mark In Transit', Icons.flight_takeoff_rounded, const Color(0xFF3B82F6), _markInTransit),
          const SizedBox(height: 10),
        ],
        if (_s.status == 'in_transit') ...[
          _fullBtn('Mark Delivered', Icons.check_circle_rounded, const Color(0xFF10B981), _markDelivered),
          const SizedBox(height: 10),
        ],
        if (_s.status != 'delivered' && _s.status != 'failed')
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
            onPressed: _markFailed,
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor,
              side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: const Text('Mark Failed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
      ])),
    );
  }

  Widget _secTitle(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.8)));

  Widget _infoRow(String label, String value, Color tp, Color ts, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, color: ts)),
      Flexible(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500, color: highlight ? AppTheme.primary : tp), textAlign: TextAlign.end)),
    ]));

  Widget _fullBtn(String label, IconData icon, Color color, VoidCallback onTap) => SizedBox(width: double.infinity, height: 52,
    child: ElevatedButton.icon(onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))));
}
