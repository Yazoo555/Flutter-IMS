import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_models.dart';
import 'inventory_widgets.dart';
import '../../models/logistics_models.dart';
import '../../services/logistics_service.dart';

class StockAdjustScreen extends StatefulWidget {
  final InventoryItem item;

  const StockAdjustScreen({super.key, required this.item});

  @override
  State<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();
  String _movementType = 'purchase';
  List<Supplier> _suppliers = [];
  bool _isSaving = false;

  static const _movementTypes = [
    _MovementType('purchase', 'Purchase', Icons.add_shopping_cart_rounded, Color(0xFF10B981)),
    _MovementType('sale', 'Sale', Icons.point_of_sale_rounded, Color(0xFF6366F1)),
    _MovementType('adjustment', 'Adjustment', Icons.tune_rounded, Color(0xFFF59E0B)),
    _MovementType('return', 'Return', Icons.keyboard_return_rounded, Color(0xFF0EA5E9)),
    _MovementType('damage', 'Damage', Icons.warning_amber_rounded, Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    try {
      final suppliers = await LogisticsService.getSuppliers();
      setState(() => _suppliers = suppliers);
    } catch (_) {}
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final qty = double.parse(_quantityController.text);
      final ref = _referenceController.text.trim();

      await supabase.rpc('adjust_stock', params: {
        'p_item_id': widget.item.id,
        'p_movement_type': _movementType,
        'p_quantity': qty,
        'p_notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'p_reference': ref.isEmpty ? null : ref,
      });

      if (!mounted) return;

      if (_movementType == 'sale') {
        await _handleLogisticsTaskCreation(qty, ref);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Adjustment failed. Please try again.', error: true);
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogisticsTaskCreation(double qty, String ref) async {
    if (_suppliers.isEmpty) {
      _showSnack('No suppliers found to create task.');
      return;
    }

    final selectedSupplier = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Text('Select Supplier for Task', style: TextStyle(color: AppTheme.getTextPrimary(context))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suppliers.length,
            itemBuilder: (context, index) {
              final s = _suppliers[index];
              return ListTile(
                leading: const Icon(Icons.business_rounded, color: AppTheme.primary),
                title: Text(s.name, style: TextStyle(color: AppTheme.getTextPrimary(context))),
                onTap: () => Navigator.pop(ctx, s),
              );
            },
          ),
        ),
      ),
    );

    if (selectedSupplier != null) {
      try {
        final task = await LogisticsService.createTask(
          supplierId: selectedSupplier.id,
          title: 'Delivery: ${widget.item.name}',
          description: 'Qty: $qty | Ref: ${ref.isEmpty ? 'N/A' : ref}\n${_notesController.text.trim()}',
          status: 'pending',
        );
        // Link the item to the task with quantity
        await LogisticsService.addTaskItems(task.id, [
          {'id': widget.item.id, 'quantity': qty}
        ]);
        _showSnack('Logistics task created successfully.');
      } catch (e) {
        _showSnack('Failed to create logistics task.', error: true);
      }
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = _movementTypes.firstWhere((t) => t.value == _movementType);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.getTextSecondary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Adjust Stock',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.getTextPrimary(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _buildItemSummaryCard(),
            const SizedBox(height: 24),
            SectionLabel('Movement Type'),
            _buildSectionCard([
              _buildMovementTypeSelector(),
            ]),
            const SizedBox(height: 24),
            SectionLabel('Details'),
            _buildSectionCard([
              FormFieldWidget(
                label: 'Quantity *',
                controller: _quantityController,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null) return 'Invalid number';
                  if (n <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                label: 'Reference',
                controller: _referenceController,
                hint: 'e.g. PO-001, INV-2024-01',
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                label: 'Notes',
                controller: _notesController,
                hint: 'Optional notes',
                maxLines: 3,
              ),
              if (_movementType == 'sale') ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkPrimaryLight
                            : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Logistics Task',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.getTextPrimary(context))),
                          Text('A delivery task will be created automatically for this sale.',
                              style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ]),
            const SizedBox(height: 32),
            _buildConfirmButton(selectedType),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkPrimaryLight
                  : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded, size: 24, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextPrimary(context)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  'Current Stock: ${widget.item.currentStock.toStringAsFixed(widget.item.currentStock % 1 == 0 ? 0 : 2)} ${widget.item.unit?.abbreviation ?? ''}',
                  style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _movementTypes.map((type) {
        final isSelected = _movementType == type.value;
        return GestureDetector(
          onTap: () => setState(() => _movementType = type.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withOpacity(0.15)
                  : AppTheme.getBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? type.color : AppTheme.getBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, size: 16, color: isSelected ? type.color : AppTheme.getTextHint(context)),
                const SizedBox(width: 6),
                Text(type.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? type.color : AppTheme.getTextSecondary(context))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton(_MovementType selectedType) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedType.color,
          disabledBackgroundColor: selectedType.color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selectedType.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Confirm ${selectedType.label}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
      ),
    );
  }
}

class _MovementType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MovementType(this.value, this.label, this.icon, this.color);
}