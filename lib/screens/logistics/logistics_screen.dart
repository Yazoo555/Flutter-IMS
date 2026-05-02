import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LogisticsScreen extends StatelessWidget {
  const LogisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Logistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track shipments and manage deliveries.',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}