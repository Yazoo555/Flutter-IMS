import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class DaySectionHeader extends StatelessWidget {
  final String day;
  final bool isToday;
  final int classCount;

  const DaySectionHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.classCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          if (isToday)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            day.toUpperCase(),
            style: AppTypography.overline.copyWith(
              fontSize: isToday ? 13 : 11,
              color: isToday
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              ),
              child: Text(
                'TODAY',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$classCount ${classCount == 1 ? 'class' : 'classes'}',
            style: AppTypography.small.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
