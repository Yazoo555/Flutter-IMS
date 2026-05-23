import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_models.dart';
import '../setup/units_screen.dart';
import '../setup/categories_screen.dart';
import '../../models/logistics_models.dart';
import '../logistics/task_detail_screen.dart';
import '../../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String? _monthlyError;
  String? _recentError;
  String? _tasksError;

  bool _loadingMonthly = true;
  bool _loadingRecent = true;
  bool _loadingTasks = true;

  List<MonthlyStockReport> _monthlyReports = [];
  List<RecentMovement> _recentMovements = [];
  List<LogisticsTask> _latestTasks = [];

  // Bar chart touch index
  int _touchedMonthlyIndex = -1;

  final _fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      // 1. Try to get data
      final (monthly, recent, tasks) = await DashboardService.fetchDashboardData(forceRefresh: forceRefresh);
      
      if (mounted) {
        setState(() {
          _monthlyReports = monthly;
          _recentMovements = recent;
          _latestTasks = tasks;
          _loadingMonthly = false;
          _loadingRecent = false;
          _loadingTasks = false;
          _monthlyError = null;
          _recentError = null;
          _tasksError = null;
        });
      }

      // 2. Background update if stale
      if (!forceRefresh && DashboardService.isCacheStale) {
        _refreshInBackground();
      }
    } catch (e) {
      if (mounted) {
        // If we already have data showing, don't replace it with an error UI
        if (_monthlyReports.isNotEmpty || _recentMovements.isNotEmpty || _latestTasks.isNotEmpty) {
          setState(() {
            _loadingMonthly = false;
            _loadingRecent = false;
            _loadingTasks = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Connect to wifi to update dashboard'),
              backgroundColor: AppTheme.errorColor.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _monthlyError = 'Failed to load dashboard';
            _recentError = 'Failed to load transactions';
            _tasksError = 'Failed to load tasks';
            _loadingMonthly = false;
            _loadingRecent = false;
            _loadingTasks = false;
          });
        }
      }
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final (monthly, recent, tasks) = await DashboardService.fetchDashboardData(forceRefresh: true);
      if (mounted) {
        setState(() {
          _monthlyReports = monthly;
          _recentMovements = recent;
          _latestTasks = tasks;
          _monthlyError = null;
          _recentError = null;
          _tasksError = null;
        });
      }
    } catch (_) {
      // Fail silently in background, keeping current (cached) data
    }
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  // Removed individual fetch methods as they are now handled by DashboardService

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
      onRefresh: () => _loadData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── YTD Summary cards ──────────────────────────────────────────
            _buildYtdSummaryRow(),
            const SizedBox(height: 20),

            // ── Overall Ratio ──────────────────────────────────────────────
            _buildSectionHeader('Overall Purchase vs Sales', Icons.pie_chart_rounded),
            const SizedBox(height: 12),
            _buildPieChart(),
            const SizedBox(height: 20),

            // ── Recent Movements ───────────────────────────────────────────
            _buildSectionHeader(
                'Recent Transactions', Icons.history_rounded),
            const SizedBox(height: 12),
            _buildRecentMovements(),
            const SizedBox(height: 20),

            // ── Latest Tasks ───────────────────────────────────────────────
            _buildSectionHeader('Latest Logistics Tasks', Icons.local_shipping_rounded),
            const SizedBox(height: 12),
            _buildLatestTasks(),
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
    return Column(
      children: [
        _summaryCard(
          'Total Sales (YTD)',
          'Rs ${_fmt.format(sales)}',
          Icons.point_of_sale_rounded,
          const Color(0xFF6366F1),
        ),
        const SizedBox(height: 10),
        _summaryCard(
          'Total Purchase (YTD)',
          'Rs ${_fmt.format(purchase)}',
          Icons.add_shopping_cart_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 10),
        _summaryCard(
          'Gross Profit (YTD)',
          'Rs ${_fmt.format(profit)}',
          isProfit
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          isProfit ? const Color(0xFF10B981) : AppTheme.errorColor,
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4), size: 20),
        ],
      ),
    );
  }

  // ── Monthly Chart ──────────────────────────────────────────────────────────

  Widget _buildPieChart() {
    if (_loadingMonthly) {
      return _chartSkeleton();
    }
    if (_monthlyError != null || _monthlyReports.isEmpty) {
      return _chartEmpty(_monthlyError ?? 'No data yet');
    }

    const purchaseColor = Color(0xFF10B981);
    const salesColor = Color(0xFF6366F1);
    const profitColor = Color(0xFFF59E0B);

    final (totalPurchase, totalSales, totalProfit) = _ytdTotals;
    
    if (totalPurchase == 0 && totalSales == 0 && totalProfit <= 0) {
      return _chartEmpty('No significant data to show');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getBorder(context).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('Purchase', purchaseColor),
              _legend('Sales', salesColor),
              if (totalProfit > 0) _legend('Profit', profitColor),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedMonthlyIndex = -1;
                            return;
                          }
                          _touchedMonthlyIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      _buildPieSection(
                        index: 0,
                        value: totalPurchase,
                        color: purchaseColor,
                        title: 'Buy',
                      ),
                      _buildPieSection(
                        index: 1,
                        value: totalSales,
                        color: salesColor,
                        title: 'Sell',
                      ),
                      if (totalProfit > 0)
                        _buildPieSection(
                          index: 2,
                          value: totalProfit,
                          color: profitColor,
                          title: 'Profit',
                        ),
                    ],
                  ),
                ),
                if (_touchedMonthlyIndex >= 0)
                  _buildPieTooltip(
                    _getTouchedValue(totalPurchase, totalSales, totalProfit),
                    _getTouchedLabel(),
                    _getTouchedColor(purchaseColor, salesColor, profitColor),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TOTAL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: AppTheme.getTextSecondary(context))),
                      const SizedBox(height: 2),
                      Text('Rs ${_fmt.format(totalSales)}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.getTextPrimary(context))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection({
    required int index,
    required double value,
    required Color color,
    required String title,
  }) {
    final isTouched = _touchedMonthlyIndex == index;
    final double radius = isTouched ? 75 : 60;
    final double fontSize = isTouched ? 16 : 12;
    final double opacity = isTouched ? 1.0 : 0.85;

    return PieChartSectionData(
      color: color.withOpacity(opacity),
      value: value,
      title: isTouched ? title : '',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
      badgeWidget: isTouched 
        ? Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
            ),
            child: Icon(Icons.touch_app_rounded, size: 12, color: color),
          )
        : null,
      badgePositionPercentageOffset: 1.1,
    );
  }

  double _getTouchedValue(double p, double s, double pr) {
    if (_touchedMonthlyIndex == 0) return p;
    if (_touchedMonthlyIndex == 1) return s;
    return pr;
  }

  String _getTouchedLabel() {
    if (_touchedMonthlyIndex == 0) return 'Purchase';
    if (_touchedMonthlyIndex == 1) return 'Sales';
    return 'Gross Profit';
  }

  Color _getTouchedColor(Color p, Color s, Color pr) {
    if (_touchedMonthlyIndex == 0) return p;
    if (_touchedMonthlyIndex == 1) return s;
    return pr;
  }

  Widget _buildPieTooltip(double value, String label, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 4),
          Text('Rs ${_fmt.format(value)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color)),
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
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
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
                        color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
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
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.getTextPrimary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${move.movementType.toUpperCase()}  ·  ${DateFormat('MMM dd, HH:mm').format(move.createdAt.toLocal())}',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context)),
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
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 62, color: AppTheme.getBorder(context)),
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
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 2),
            Text(description,
                style: TextStyle(
                    fontSize: 11, color: AppTheme.getTextSecondary(context))),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimary(context),
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
            style: TextStyle(
                fontSize: 11, color: AppTheme.getTextSecondary(context))),
      ],
    );
  }

  Widget _chartSkeleton() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }

  Widget _chartEmpty(String msg) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Center(
        child: Text(msg,
            style:
                TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
      ),
    );
  }

  Widget _skeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
      ),
    );
  }

  // ── Latest Tasks ───────────────────────────────────────────────────────────

  Widget _buildLatestTasks() {
    if (_loadingTasks) {
      return Column(
        children: List.generate(3, (_) => _skeletonTile()),
      );
    }
    if (_tasksError != null) {
      return _chartEmpty(_tasksError!);
    }
    if (_latestTasks.isEmpty) {
      return _chartEmpty('No logistics tasks yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        children: _latestTasks.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          final isLast = i == _latestTasks.length - 1;

          Color statusColor = switch (task.status) {
            'pending' => const Color(0xFFF59E0B),
            'in_progress' => const Color(0xFF0EA5E9),
            'completed' => const Color(0xFF10B981),
            'cancelled' => const Color(0xFFEF4444),
            _ => AppTheme.textHint,
          };

          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  ).then((_) => _loadData(forceRefresh: true));
                },
                borderRadius: isLast 
                  ? const BorderRadius.vertical(bottom: Radius.circular(14))
                  : (i == 0 ? const BorderRadius.vertical(top: Radius.circular(14)) : null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_shipping_outlined, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.getTextPrimary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${task.supplierName ?? 'Direct'}  ·  ${DateFormat('MMM d').format(task.createdAt)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.getTextSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 66, color: AppTheme.getBorder(context)),
            ],
          );
        }).toList(),
      ),
    );
  }
}