import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const AppLogo({super.key, this.iconSize = 22, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inventory_2_rounded,
          color: AppTheme.primary,
          size: iconSize,
        ),
        const SizedBox(width: 7),
        Text(
          'IMS',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
