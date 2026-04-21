// purchase_orders_tab.dart
// List view for purchase orders with status filter and FAB.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';
import '../services/logistics_service.dart';
import '../widgets/status_chip.dart';
import 'po_detail_screen.dart';

class PurchaseOrdersTab extends StatefulWidget {
  const PurchaseOrdersTab({super.key});

  @override
  State<PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends State<PurchaseOrdersTab> {
  List<PurchaseOrder> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = '';

  final _statusFilters = const [
    {'label': 'All', 'value': ''},
    {'label': 'Draft', 'value': 'draft'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Partial', 'value': 'partially_received'},
    {'label': 'Received', 'value': 'received'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await LogisticsService.getPurchaseOrders(
          status: _filterStatus.isEmpty ? null : _filterStatus);
      if (!mounted) return;
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load purchase orders.';
        _isLoading = false;
      });
    }
  }

  void _setFilter(String value) {
    setState(() => _filterStatus = value);
    _fetchOrders();
  }

  Future<void> _openCreatePO() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _CreatePOScreen()),
    );
    if (created == true) _fetchOrders();
  }

  Future<void> _openPODetail(PurchaseOrder po) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PODetailScreen(
          purchaseOrderId: po.id,
          onDataChanged: _fetchOrders,
        ),
      ),
    );
    if (result == true) _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePO,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New PO',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((f) {
            final isSelected = _filterStatus == f['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _setFilter(f['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? AppTheme.primary : borderColor),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
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
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkPrimaryLight
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text('No Purchase Orders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Tap "New PO" to create your first purchase order.',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _POCard(
          po: _orders[i],
          onTap: () => _openPODetail(_orders[i]),
          isDark: isDark,
        ),
      ),
    );
  }
}

// ── PO Card ──────────────────────────────────────────────────────────────────

class _POCard extends StatelessWidget {
  final PurchaseOrder po;
  final VoidCallback onTap;
  final bool isDark;

  const _POCard({required this.po, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkPrimaryLight
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 24, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(po.poNumber,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(status: po.status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(po.supplierName,
                            style: TextStyle(
                                fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: textSecondary),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _InfoBadge(
                      label: 'Order Date',
                      value: _formatDate(po.orderDate),
                      color: const Color(0xFF6366F1)),
                  const SizedBox(width: 14),
                  _InfoBadge(
                      label: 'Expected',
                      value: _formatDate(po.expectedDate),
                      color: const Color(0xFFF59E0B)),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total',
                          style: TextStyle(
                              fontSize: 10, color: textSecondary)),
                      Text('Rs. ${po.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(date);
      return DateFormat('MMM d, y').format(d);
    } catch (_) {
      return date;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ── Create PO Screen ─────────────────────────────────────────────────────────

class _CreatePOScreen extends StatefulWidget {
  const _CreatePOScreen();

  @override
  State<_CreatePOScreen> createState() => _CreatePOScreenState();
}

class _CreatePOScreenState extends State<_CreatePOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _poNumberController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _supplierOptions = [];
  String? _selectedSupplierId;
  DateTime? _orderDate;
  DateTime? _expectedDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _orderDate = DateTime.now();
    _expectedDate = DateTime.now().add(const Duration(days: 7));
    _loadSuppliers();
  }

  @override
  void dispose() {
    _poNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final data = await LogisticsService.getSupplierDropdown();
      if (!mounted) return;
      setState(() {
        _supplierOptions = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(bool isOrder) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isOrder ? (_orderDate ?? now) : (_expectedDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isOrder) {
        _orderDate = picked;
      } else {
        _expectedDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      _showSnack('Please select a supplier.', error: true);
      return;
    }
    setState(() => _isSaving = true);

    try {
      await LogisticsService.createPurchaseOrder({
        'user_id': supabase.auth.currentUser!.id,
        'supplier_id': _selectedSupplierId,
        'po_number': _poNumberController.text.trim(),
        'status': 'draft',
        'order_date': _orderDate != null
            ? DateFormat('yyyy-MM-dd').format(_orderDate!)
            : null,
        'expected_date': _expectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_expectedDate!)
            : null,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to create PO: $e', error: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Purchase Order',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _sectionLabel('ORDER DETAILS', textSecondary),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PO Number
                        _fieldLabel('PO Number *', textSecondary),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _poNumberController,
                          style:
                              TextStyle(fontSize: 14, color: textPrimary),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                          decoration: _inputDecoration(
                              'e.g. PO-2026-001', isDark, borderColor,
                              surfaceColor),
                        ),
                        const SizedBox(height: 16),

                        // Supplier dropdown
                        _fieldLabel('Supplier *', textSecondary),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedSupplierId,
                          items: _supplierOptions
                              .map((s) => DropdownMenuItem(
                                    value: s['id'] as String,
                                    child: Text(s['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedSupplierId = v),
                          hint: Text('Select supplier',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.textHint)),
                          style:
                              TextStyle(fontSize: 14, color: textPrimary),
                          dropdownColor: surfaceColor,
                          decoration: _inputDecoration(
                              '', isDark, borderColor, surfaceColor),
                        ),
                        const SizedBox(height: 16),

                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                'Order Date',
                                _orderDate,
                                () => _pickDate(true),
                                isDark,
                                textPrimary,
                                textSecondary,
                                borderColor,
                                surfaceColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _dateField(
                                'Expected Date',
                                _expectedDate,
                                () => _pickDate(false),
                                isDark,
                                textPrimary,
                                textSecondary,
                                borderColor,
                                surfaceColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        _fieldLabel('Notes', textSecondary),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style:
                              TextStyle(fontSize: 14, color: textPrimary),
                          decoration: _inputDecoration(
                              'Optional notes', isDark, borderColor,
                              surfaceColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor:
                            AppTheme.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Create PO',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8)),
    );
  }

  Widget _fieldLabel(String text, Color color) {
    return Text(text,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color));
  }

  InputDecoration _inputDecoration(
      String hint, bool isDark, Color borderColor, Color surfaceColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.darkTextHint : AppTheme.textHint),
      filled: true,
      fillColor: surfaceColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? date,
    VoidCallback onTap,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, textSecondary),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM d, y').format(date)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? textPrimary
                          : (isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.textHint),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
