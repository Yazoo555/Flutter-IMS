import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/inventory_models.dart';
import '../setup/units_screen.dart';
import '../setup/categories_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _loadingMonthly = true;
  bool _loadingRecent = true;

  List<MonthlyStockReport> _monthlyReports = [];
  List<RecentMovement> _recentMovements = [];

  String? _monthlyError;
  String? _recentError;

  // Bar chart touch index
  int _touchedMonthlyIndex = -1;

  final _fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchMonthly();
    _fetchRecent();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchMonthly() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _monthlyError = 'Not authenticated';
          _loadingMonthly = false;
        });
      }
      return;
    }
    try {
      final data = await supabase.rpc('get_monthly_report_with_value', params: {
        'p_user_id': user.id,
        'p_year': DateTime.now().year,
      });
      if (!mounted) return;
      final reports = (data as List)
          .map((e) => MonthlyStockReport.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _monthlyReports = reports;
        _loadingMonthly = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monthlyError = 'Failed to load monthly data';
        _loadingMonthly = false;
      });
    }
  }

  Future<void> _fetchRecent() async {
    try {
      final data = await supabase
          .from('recent_movements_with_value')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);
      if (!mounted) return;
      final movements = (data as List)
          .map((e) => RecentMovement.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _recentMovements = movements;
        _loadingRecent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentError = 'Failed to load recent movements';
        _loadingRecent = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Totals across all monthly data loaded
  (double, double, double) get _ytdTotals {
    double purchase = 0, sales = 0, profit = 0;
    for (final r in _monthlyReports) {
      purchase += r.totalPurchaseValue;
      sales += r.totalSalesValue;
      profit += r.grossProfit;
    }
    return (purchase, sales, profit);
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'purchase':
        return const Color(0xFF10B981);
      case 'sale':
        return const Color(0xFF6366F1);
      case 'adjustment':
        return const Color(0xFFF59E0B);
      case 'return':
        return const Color(0xFF0EA5E9);
      case 'damage':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'purchase':
        return Icons.add_shopping_cart_rounded;
      case 'sale':
        return Icons.point_of_sale_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      case 'return':
        return Icons.keyboard_return_rounded;
      case 'damage':
        return Icons.warning_amber_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        setState(() {
          _loadingMonthly = true;
          _loadingRecent = true;
        });
        await Future.wait([_fetchMonthly(), _fetchRecent()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── YTD Summary cards ──────────────────────────────────────────
            _buildYtdSummaryRow(),
            const SizedBox(height: 20),

            // ── Monthly Bar Chart ──────────────────────────────────────────
            _buildSectionHeader('Monthly Overview', Icons.bar_chart_rounded),
            const SizedBox(height: 12),
            _buildMonthlyBarChart(),
            const SizedBox(height: 20),

            // ── Recent Movements ───────────────────────────────────────────
            _buildSectionHeader(
                'Recent Transactions', Icons.history_rounded),
            const SizedBox(height: 12),
            _buildRecentMovements(),
            const SizedBox(height: 20),

            // ── Quick Access ───────────────────────────────────────────────
            _buildSectionHeader('Quick Access', Icons.grid_view_rounded),
            const SizedBox(height: 12),
            _buildQuickAccess(context),
          ],
        ),
      ),
    );
  }

  // ── YTD Cards ─────────────────────────────────────────────────────────────

  Widget _buildYtdSummaryRow() {
    if (_loadingMonthly) {
      return const SizedBox(
        height: 90,
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    final (purchase, sales, profit) = _ytdTotals;
    final isProfit = profit >= 0;
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'YTD Sales',
            'Rs ${_fmt.format(sales)}',
            Icons.point_of_sale_rounded,
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'YTD Purchase',
            'Rs ${_fmt.format(purchase)}',
            Icons.add_shopping_cart_rounded,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Gross Profit',
            'Rs ${_fmt.format(profit)}',
            isProfit
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            isProfit ? const Color(0xFF10B981) : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── Monthly Bar Chart ──────────────────────────────────────────────────────

  Widget _buildMonthlyBarChart() {
    if (_loadingMonthly) {
      return _chartSkeleton();
    }
    if (_monthlyError != null || _monthlyReports.isEmpty) {
      return _chartEmpty(_monthlyError ?? 'No monthly data yet');
    }

    // Build groups — purchase (blue/green) vs sales (indigo) side by side
    final groups = _monthlyReports.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      final isTouched = i == _touchedMonthlyIndex;
      const purchaseColor = Color(0xFF10B981);
      const salesColor = Color(0xFF6366F1);
      final maxVal = _monthlyReports
          .map((r) =>
              [r.totalPurchaseValue, r.totalSalesValue].reduce(
                  (a, b) => a > b ? a : b))
          .reduce((a, b) => a > b ? a : b);

      // Scale to reasonable chart height (max 100)
      double scale(double v) => maxVal == 0 ? 0 : (v / maxVal) * 100;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: scale(r.totalPurchaseValue),
            color: isTouched
                ? purchaseColor
                : purchaseColor.withOpacity(0.75),
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: scale(r.totalSalesValue),
            color:
                isTouched ? salesColor : salesColor.withOpacity(0.75),
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 3,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Wrap(
            spacing: 16,
            children: [
              _legend('Purchase Value', const Color(0xFF10B981)),
              _legend('Sales Value', const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 12),
          // Tooltip on touch
          if (_touchedMonthlyIndex >= 0 &&
              _touchedMonthlyIndex < _monthlyReports.length)
            _buildBarTooltip(_monthlyReports[_touchedMonthlyIndex]),
          if (_touchedMonthlyIndex >= 0) const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 110,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    getTooltipItem: (p1, p2, p3, p4) => null,
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (response == null ||
                          response.spot == null ||
                          event is FlTapUpEvent ||
                          event is FlPointerExitEvent) {
                        _touchedMonthlyIndex = -1;
                      } else {
                        _touchedMonthlyIndex =
                            response.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _monthlyReports.length) {
                          return const SizedBox();
                        }
                        final name = _monthlyReports[idx].monthName;
                        final abbr =
                            name.length >= 3 ? name.substring(0, 3) : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            abbr,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.border,
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarTooltip(MonthlyStockReport r) {
    final isProfit = r.grossProfit >= 0;
    final profitColor =
        isProfit ? const Color(0xFF10B981) : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.monthName,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text(
                  'Buy: Rs ${_fmt.format(r.totalPurchaseValue)}  '
                  'Sell: Rs ${_fmt.format(r.totalSalesValue)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          Text(
            '${isProfit ? '+' : ''}Rs ${_fmt.format(r.grossProfit)}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: profitColor),
          ),
        ],
      ),
    );
  }

  // ── Recent Movements ───────────────────────────────────────────────────────

  Widget _buildRecentMovements() {
    if (_loadingRecent) {
      return Column(
        children: List.generate(
            3, (_) => _skeletonTile()),
      );
    }
    if (_recentError != null) {
      return _chartEmpty(_recentError!);
    }
    if (_recentMovements.isEmpty) {
      return _chartEmpty('No recent transactions');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: _recentMovements.asMap().entries.map((entry) {
          final i = entry.key;
          final move = entry.value;
          final isLast = i == _recentMovements.length - 1;
          final isDeficit =
              move.movementType == 'sale' || move.movementType == 'damage';
          final color = _colorForType(move.movementType);

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(_iconForType(move.movementType),
                          color: color, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            move.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${move.movementType.toUpperCase()}  ·  ${DateFormat('MMM dd, HH:mm').format(move.createdAt.toLocal())}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs ${_fmt.format(move.transactionValue)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDeficit
                                ? AppTheme.errorColor
                                : const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          '${isDeficit ? '-' : '+'}${move.quantity % 1 == 0 ? move.quantity.toInt() : move.quantity} units',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 62, color: AppTheme.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Quick Access ───────────────────────────────────────────────────────────

  Widget _buildQuickAccess(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickCard(
            context,
            icon: Icons.straighten_rounded,
            label: 'Units',
            description: 'Measurement units',
            color: AppTheme.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UnitsScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickCard(
            context,
            icon: Icons.category_rounded,
            label: 'Categories',
            description: 'Item classifications',
            color: const Color(0xFF0EA5E9),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
        ),
      ],
    );
  }

  Widget _quickCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(description,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10, decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _chartSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }

  Widget _chartEmpty(String msg) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Text(msg,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _skeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
      ),
    );
  }
}