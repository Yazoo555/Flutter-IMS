// add_edit_item_screen.dart
// Screens for adding/editing inventory items and adjusting stock levels.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_models.dart';
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

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor:
              AppTheme.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Save Item',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.getTextSecondary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Item' : 'Add Item',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimary(context)),
        ),
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
                  _buildSectionCard([
                    FormFieldWidget(
                      label: 'Item Name *',
                      controller: _nameController,
                      hint: 'e.g. Brown Rice 1kg',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (!RegExp(r'[a-zA-Z]').hasMatch(v.trim())) {
                          return 'Name must contain at least one letter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormFieldWidget(
                      label: 'SKU',
                      controller: _skuController,
                      hint: 'e.g. RICE-BRN-1K',
                    ),
                    const SizedBox(height: 16),
                    FormFieldWidget(
                      label: 'Description',
                      controller: _descController,
                      hint: 'Optional description',
                      maxLines: 3,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  
                  SectionLabel('Category & Unit'),
                  _buildSectionCard([
                    DropdownFieldWidget<String>(
                      label: 'Category *',
                      value: _selectedCategoryId,
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      hint: 'Select category',
                    ),
                    const SizedBox(height: 16),
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
                  ]),
                  const SizedBox(height: 24),

                  SectionLabel('Stock Details'),
                  _buildSectionCard([
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldWidget(
                            label: 'Opening Stock *',
                            controller: _openingStockController,
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormFieldWidget(
                            label: 'Low Stock Alert',
                            controller: _lowStockController,
                            hint: 'e.g. 10',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 24),

                  SectionLabel('Pricing Details'),
                  _buildSectionCard([
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldWidget(
                            label: 'Purchase Price *',
                            controller: _purchasePriceController,
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefix: 'Rs. ',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormFieldWidget(
                            label: 'Sales Price *',
                            controller: _salesPriceController,
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefix: 'Rs. ',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }
}

