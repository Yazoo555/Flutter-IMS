import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'screens/suppliers_tab.dart';
import 'screens/purchase_orders_tab.dart';
import 'screens/shipments_tab.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});
  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Column(
      children: [
        // Tab bar container
        Container(
          color: surfaceColor,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                dividerColor: borderColor,
                tabs: const [
                  Tab(text: 'Suppliers'),
                  Tab(text: 'Purchase Orders'),
                  Tab(text: 'Shipments'),
                ],
              ),
            ],
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SuppliersTab(),
              PurchaseOrdersTab(),
              ShipmentsTab(),
            ],
          ),
        ),
      ],
    );
  }
}