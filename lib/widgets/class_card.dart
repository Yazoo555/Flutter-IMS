import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';

enum ClassStatus { upcoming, ongoing, ended }

class ClassCard extends StatelessWidget {
  final ClassSession session;
  final bool isToday;
  final ClassStatus status;
  final bool showActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClassCard({
    super.key,
    required this.session,
    this.isToday = false,
    this.status = ClassStatus.upcoming,
    this.showActions = true,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (status) {
      case ClassStatus.ongoing:
        return AppColors.primary; // indigo active glow
      case ClassStatus.ended:
        return AppColors.error;
      case ClassStatus.upcoming:
        return AppColors.subjectColor(session.subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = AppColors.subjectColor(session.subject);
    final typeColor = AppColors.typeColor(session.type);
    final isEnded = status == ClassStatus.ended;
    final isOngoing = status == ClassStatus.ongoing;

    return Opacity(
      opacity: isEnded ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: isOngoing
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                )
              : isToday && status == ClassStatus.upcoming
              ? Border.all(
                  color: subjectColor.withOpacity(0.25),
                  width: 1,
                )
              : null,
          boxShadow: AppTheme.cardShadows(context),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusLg - 0.5),
                    bottomLeft: Radius.circular(DesignTokens.radiusLg - 0.5),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: time + badges
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppTheme.textTertiary(context),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${session.startTime} – ${session.endTime}',
                            style: AppTypography.smallBold.copyWith(
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const Spacer(),

                          // Status badge for today
                          if (isToday) ...[
                            _StatusBadge(status: status),
                            const SizedBox(width: 6),
                          ],

                          // Type badge
                          _Badge(
                            label: session.type,
                            color: typeColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Subject name
                      Text(
                        session.subject,
                        style: AppTypography.headingMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Room & Lecturer
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: session.room,
                      ),
                      const SizedBox(height: 3),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: session.lecturer,
                      ),

                      // Ongoing indicator
                      if (isOngoing) ...[
                        const SizedBox(height: 10),
            Row(
              children: [
                _PulseDot(),
                const SizedBox(width: 8),
                Text(
                  'Happening now',
                  style: AppTypography.smallBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (showActions) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.primary,
                        onTap: onEdit,
                      ),
                      const SizedBox(height: 6),
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: DesignTokens.durationNormal,
      curve: Curves.easeOut,
    ).slideX(
      begin: 0.05,
      duration: DesignTokens.durationNormal,
      curve: Curves.easeOut,
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ClassStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ClassStatus.ongoing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      case ClassStatus.ended:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.10),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Text(
            'DONE',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        );
      case ClassStatus.upcoming:
        return const SizedBox.shrink();
    }
  }
}

// ── Pulse dot ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: AppTheme.textTertiary(context),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTypography.small.copyWith(
              color: AppTheme.textSecondary(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
