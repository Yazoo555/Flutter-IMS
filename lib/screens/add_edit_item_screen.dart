// add_edit_item_screen.dart
// Screens for adding/editing inventory items and adjusting stock levels.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'inventory_models.dart';
import 'inventory_widgets.dart';

// ── Add / Edit Item Screen ────────────────────────────────────────────────────

class AddEditItemScreen extends StatefulWidget {
  final InventoryItem? item;

  const AddEditItemScreen({super.key, this.item});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salesPriceController = TextEditingController();

  List<ItemCategory> _categories = [];
  List<ItemUnit> _units = [];
  String? _selectedCategoryId;
  String? _selectedUnitId;
  bool _isSaving = false;
  bool _isLoadingMeta = true;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _loadMeta();
    if (_isEditing) _populateFields(widget.item!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    _purchasePriceController.dispose();
    _salesPriceController.dispose();
    super.dispose();
  }

  void _populateFields(InventoryItem item) {
    _nameController.text = item.name;
    _skuController.text = item.sku ?? '';
    _descController.text = item.description ?? '';
    _openingStockController.text =
        item.openingStock.toStringAsFixed(item.openingStock % 1 == 0 ? 0 : 2);
    _lowStockController.text = item.lowStockAlert
            ?.toStringAsFixed(item.lowStockAlert! % 1 == 0 ? 0 : 2) ??
        '';
    _purchasePriceController.text = item.purchasePrice.toStringAsFixed(2);
    _salesPriceController.text = item.salesPrice.toStringAsFixed(2);
    _selectedCategoryId = item.categoryId;
    _selectedUnitId = item.unitId;
  }

  Future<void> _loadMeta() async {
    try {
      final catData = await supabase
          .from('categories')
          .select('id,name')
          .order('name', ascending: true);
      final unitData = await supabase
          .from('units')
          .select('id,name,abbreviation')
          .order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _categories = (catData as List)
            .map((e) => ItemCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        _units = (unitData as List)
            .map((e) => ItemUnit.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoadingMeta = false;
        if (!_isEditing) {
          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
          if (_units.isNotEmpty) _selectedUnitId = _units.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedUnitId == null) {
      _showSnack('Please select a category and unit.', error: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final payload = {
        'user_id': userId,
        'category_id': _selectedCategoryId,
        'unit_id': _selectedUnitId,
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'opening_stock': double.tryParse(_openingStockController.text) ?? 0,
        'low_stock_alert': _lowStockController.text.trim().isEmpty
            ? null
            : double.tryParse(_lowStockController.text),
        'purchase_price':
            double.tryParse(_purchasePriceController.text) ?? 0,
        'sales_price': double.tryParse(_salesPriceController.text) ?? 0,
      };

      if (_isEditing) {
        await supabase
            .from('items')
            .update(payload)
            .eq('id', widget.item!.id);
      } else {
        await supabase.from('items').insert(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Save failed. Please try again.', error: true);
      setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Item' : 'Add Item',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingMeta
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  SectionLabel('Basic Info'),
                  FormFieldWidget(
                    label: 'Item Name *',
                    controller: _nameController,
                    hint: 'e.g. Brown Rice 1kg',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FormFieldWidget(
                    label: 'SKU',
                    controller: _skuController,
                    hint: 'e.g. RICE-BRN-1K',
                  ),
                  const SizedBox(height: 12),
                  FormFieldWidget(
                    label: 'Description',
                    controller: _descController,
                    hint: 'Optional description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SectionLabel('Category & Unit'),
                  DropdownFieldWidget<String>(
                    label: 'Category *',
                    value: _selectedCategoryId,
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategoryId = v),
                    hint: 'Select category',
                  ),
                  const SizedBox(height: 12),
                  DropdownFieldWidget<String>(
                    label: 'Unit *',
                    value: _selectedUnitId,
                    items: _units
                        .map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.abbreviation})')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnitId = v),
                    hint: 'Select unit',
                  ),
                  const SizedBox(height: 20),
                  SectionLabel('Stock'),
                  Row(
                    children: [
                      Expanded(
                        child: FormFieldWidget(
                          label: 'Opening Stock *',
                          controller: _openingStockController,
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormFieldWidget(
                          label: 'Low Stock Alert',
                          controller: _lowStockController,
                          hint: 'e.g. 10',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionLabel('Pricing'),
                  Row(
                    children: [
                      Expanded(
                        child: FormFieldWidget(
                          label: 'Purchase Price *',
                          controller: _purchasePriceController,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          prefix: '₹',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormFieldWidget(
                          label: 'Sales Price *',
                          controller: _salesPriceController,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          prefix: '₹',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Stock Adjust Screen ───────────────────────────────────────────────────────

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
  bool _isSaving = false;

  static const _movementTypes = [
    _MovementType('purchase', 'Purchase', Icons.add_shopping_cart_rounded,
        Color(0xFF10B981)),
    _MovementType(
        'sale', 'Sale', Icons.point_of_sale_rounded, Color(0xFF6366F1)),
    _MovementType(
        'adjustment', 'Adjustment', Icons.tune_rounded, Color(0xFFF59E0B)),
    _MovementType('return', 'Return', Icons.keyboard_return_rounded,
        Color(0xFF0EA5E9)),
    _MovementType(
        'damage', 'Damage', Icons.warning_amber_rounded, Color(0xFFEF4444)),
  ];

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
      await supabase.rpc('adjust_stock', params: {
        'p_item_id': widget.item.id,
        'p_movement_type': _movementType,
        'p_quantity': double.parse(_quantityController.text),
        'p_notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'p_reference': _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      });

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

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType =
        _movementTypes.firstWhere((t) => t.value == _movementType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Adjust Stock',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _buildItemSummaryCard(),
            const SizedBox(height: 20),
            SectionLabel('Movement Type'),
            _buildMovementTypeSelector(),
            const SizedBox(height: 20),
            SectionLabel('Details'),
            FormFieldWidget(
              label: 'Quantity *',
              controller: _quantityController,
              hint: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null) return 'Invalid number';
                if (n <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            FormFieldWidget(
              label: 'Reference',
              controller: _referenceController,
              hint: 'e.g. PO-001, INV-2024-01',
            ),
            const SizedBox(height: 12),
            FormFieldWidget(
              label: 'Notes',
              controller: _notesController,
              hint: 'Optional notes',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  'Current Stock: ${widget.item.currentStock.toStringAsFixed(widget.item.currentStock % 1 == 0 ? 0 : 2)} ${widget.item.unit?.abbreviation ?? ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withOpacity(0.15)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? type.color : AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon,
                    size: 16,
                    color: isSelected ? type.color : AppTheme.textHint),
                const SizedBox(width: 6),
                Text(type.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? type.color
                            : AppTheme.textSecondary)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selectedType.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Confirm ${selectedType.label}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
      ),
    );
  }
}

// ── Movement Type Model ───────────────────────────────────────────────────────

class _MovementType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MovementType(this.value, this.label, this.icon, this.color);
}