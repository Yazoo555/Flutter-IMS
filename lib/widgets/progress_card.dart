import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Generic progress card: a circular ring showing [value] (0.0–1.0) with a
/// center label, plus title/detail text.
class ProgressCard extends StatelessWidget {
  final String title;
  final String? detail;
  final double value;
  final String centerLabel;
  final Color color;
  final Widget? trailing;

  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.centerLabel,
    this.color = AppColors.primary,
    this.detail,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  centerLabel,
                  style: AppTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyEmphasized(context)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: AppTypography.caption(context)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
