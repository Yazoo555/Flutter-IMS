import 'package:flutter/material.dart';

import '../data/fyp_phase_logic.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Horizontal FYP journey visualization: Title → Proposal → … → Results.
/// Nodes are colored by state — completed (green), current (indigo ring),
/// upcoming (neutral). Auto-computed from the official phase logic.
class JourneyStrip extends StatelessWidget {
  final String currentPhaseTitle;

  const JourneyStrip({super.key, required this.currentPhaseTitle});

  @override
  Widget build(BuildContext context) {
    final currentIndex = journeyNodeIndexFor(currentPhaseTitle);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.md),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('FYP JOURNEY', style: AppTypography.overline(context)),
              const Spacer(),
              Text(
                '${currentIndex + 1} of ${fypJourneyNodes.length}',
                style: AppTypography.caption(context),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // start scrolled to the current node
            child: Row(
              children: List.generate(fypJourneyNodes.length, (i) {
                final state = i < currentIndex
                    ? _NodeState.completed
                    : i == currentIndex
                        ? _NodeState.current
                        : _NodeState.upcoming;
                return _JourneyNode(
                  label: fypJourneyNodes[i],
                  state: state,
                  isLast: i == fypJourneyNodes.length - 1,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { completed, current, upcoming }

class _JourneyNode extends StatelessWidget {
  final String label;
  final _NodeState state;
  final bool isLast;

  const _JourneyNode({
    required this.label,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _NodeState.completed => AppColors.statusCompleted,
      _NodeState.current => AppColors.primary,
      _NodeState.upcoming => AppColors.textTertiary(context),
    };

    return Row(
      children: [
        Column(
          children: [
            // Dot (with ring for current)
            Stack(
              alignment: Alignment.center,
              children: [
                if (state == _NodeState.current)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: state == _NodeState.upcoming
                        ? Colors.transparent
                        : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: state == _NodeState.completed
                      ? const Icon(Icons.check_rounded,
                          size: 8, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.caption(context).copyWith(
                  fontSize: 9,
                  fontWeight:
                      state == _NodeState.current ? FontWeight.w800 : FontWeight.w500,
                  color: state == _NodeState.current
                      ? color
                      : AppColors.textTertiary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!isLast)
          Container(
            width: 22,
            height: 2,
            margin: const EdgeInsets.only(bottom: 30),
            color: state == _NodeState.completed
                ? AppColors.statusCompleted.withValues(alpha: 0.5)
                : AppColors.border(context),
          ),
      ],
    );
  }
}
