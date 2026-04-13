import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart'; // for supabase client
import '../../models/inventory_models.dart';
import 'package:intl/intl.dart';

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
      final data = await supabase.rpc('get_monthly_stock_report', params: {
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

  String _getMonthName(int monthIndex) {
    // monthIndex is 1-12 usually from DB, but map it correctly
    if (monthIndex < 1 || monthIndex > 12) return 'Unknown';
    final date = DateTime(2000, monthIndex, 1);
    return DateFormat('MMMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Monthly Report',
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
    final List<int> years = List.generate(10, (index) => DateTime.now().year - index);
    
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Year:',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
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
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.textHint),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
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
      return const Center(
        child: Text('No monthly data found for this year.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.border, width: 1),
          ),
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getMonthName(report.month),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedYear.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppTheme.border, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Purchases', report.totalPurchases, const Color(0xFF10B981)),
                    _buildStatCol('Sales', report.totalSales, const Color(0xFF6366F1)),
                    _buildStatCol('Adjusts', report.totalAdjustments, const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
