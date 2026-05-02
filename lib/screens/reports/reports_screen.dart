import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/report_widgets.dart';
import 'recent_movements_report_screen.dart';
import 'item_movements_report_screen.dart';
import 'daily_summary_report_screen.dart';
import 'monthly_stock_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('Reports',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: c.textPrimary)),
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Text(
            'Analytics & Records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: c.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ReportDashboardCard(
            title: 'Recent Movements',
            subtitle: 'View all simple inventory transactions',
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF6366F1),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecentMovementsReportScreen()));
            },
          ),
          ReportDashboardCard(
            title: 'Item Movements',
            subtitle: 'Detailed movements for an item by date',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF10B981),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ItemMovementsReportScreen()));
            },
          ),
          ReportDashboardCard(
            title: 'Daily Summary',
            subtitle: 'Day-by-day stock summaries for items',
            icon: Icons.insert_chart_rounded,
            iconColor: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DailySummaryReportScreen()));
            },
          ),
          ReportDashboardCard(
            title: 'Monthly Report',
            subtitle: 'Total purchases, sales and adjustments per month',
            icon: Icons.poll_rounded,
            iconColor: const Color(0xFF0EA5E9),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MonthlyStockReportScreen()));
            },
          ),
        ],
      ),
    );
  }
}