import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart'; // for supabase client
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';
import '../../utils/report_pdf_helper.dart';

class MonthlyStockReportScreen extends StatefulWidget {
  const MonthlyStockReportScreen({super.key});

  @override
  State<MonthlyStockReportScreen> createState() =>
      _MonthlyStockReportScreenState();
}

class _MonthlyStockReportScreenState extends State<MonthlyStockReportScreen> {
  bool _isLoading = false;
  String? _error;
  List<MonthlyStockReport> _reports = [];

  int _selectedYear = DateTime.now().year;

  final _fmt = NumberFormat('#,##0', 'en_US');
  final _pct = NumberFormat('0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _error = 'User not authenticated.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await supabase.rpc('get_monthly_report_with_value', params: {
        'p_user_id': user.id,
        'p_year': _selectedYear,
      });

      if (!mounted) return;

      final reports = (data as List)
          .map((e) => MonthlyStockReport.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _reports = reports;
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
        title: Text('Monthly Report',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.getTextPrimary(context))),
        backgroundColor: AppTheme.getSurface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getTextPrimary(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _reports.isEmpty ? null : () => ReportPdfHelper.generateMonthlyReportPdf(_reports, _selectedYear),
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
    final List<int> years =
        List.generate(10, (index) => DateTime.now().year - index);

    return Container(
      color: AppTheme.getSurface(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Select Year:',
              style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.getBorder(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString(),
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context))),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYear = val);
                    _fetchReport();
                  }
                },
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
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.getTextHint(context)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchReport,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Text('No monthly data found for this year.',
            style: TextStyle(color: AppTheme.getTextSecondary(context))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index];
        return _buildMonthCard(r);
      },
    );
  }

  Widget _buildMonthCard(MonthlyStockReport r) {
    final isProfit = r.grossProfit >= 0;
    final profitColor =
        isProfit ? const Color(0xFF10B981) : AppTheme.errorColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
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
            // ── Month header ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      r.monthName.isNotEmpty
                          ? r.monthName
                          : DateFormat('MMMM')
                              .format(DateTime(r.month, r.month)),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.darkPrimaryLighter 
                          : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedYear.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                // Items sold badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${r.totalItemsSold} item${r.totalItemsSold == 1 ? '' : 's'} sold',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.getBorder(context)),
            const SizedBox(height: 12),

            // ── Qty row ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQtyCol('Purchased',
                    r.totalPurchasesQty, const Color(0xFF10B981)),
                _vDivider(),
                _buildQtyCol(
                    'Sold', r.totalSalesQty, const Color(0xFF6366F1)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.getBorder(context)),
            const SizedBox(height: 12),

            // ── Value row ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _valueTile(
                    'Purchase Value',
                    'Rs ${_fmt.format(r.totalPurchaseValue)}',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _valueTile(
                    'Sales Value',
                    'Rs ${_fmt.format(r.totalSalesValue)}',
                    const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Profit row ─────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: profitColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: profitColor.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isProfit
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: profitColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gross Profit',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.getTextSecondary(context))),
                          Text(
                            'Rs ${_fmt.format(r.grossProfit)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: profitColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: profitColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pct.format(r.grossMarginPercentage)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: profitColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyCol(String label, double qty, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppTheme.getTextSecondary(context))),
        const SizedBox(height: 4),
        Text(
          qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text('units',
            style:
                TextStyle(fontSize: 11, color: AppTheme.getTextHint(context))),
      ],
    );
  }

  Widget _vDivider() => Container(
        height: 36,
        width: 1,
        color: AppTheme.getBorder(context),
      );

  Widget _valueTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
