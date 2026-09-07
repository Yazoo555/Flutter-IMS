import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Overline-style section header with optional trailing widget
/// (e.g. "See all" link or a count badge).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sm + 4),
      child: Row(
        children: [
          Text(title, style: AppTypography.overline(context)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
