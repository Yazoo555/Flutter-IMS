import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../models/app_theme.dart';

enum ClassStatus { upcoming, ongoing, ended }

class ClassCard extends StatelessWidget {
  final ClassSession session;
  final bool isToday;
  final ClassStatus status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClassCard({
    super.key,
    required this.session,
    this.isToday = false,
    this.status = ClassStatus.upcoming,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (status) {
      case ClassStatus.ongoing:
        return const Color(0xFF22C55E); // green
      case ClassStatus.ended:
        return const Color(0xFFEF4444); // red
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
      opacity: isEnded ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOngoing
              ? Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.6),
                  width: 1.5,
                )
              : isToday && status == ClassStatus.upcoming
              ? Border.all(color: subjectColor.withOpacity(0.4), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: isOngoing
                  ? const Color(0xFF22C55E).withOpacity(0.15)
                  : isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isOngoing ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status bar — green if ongoing, red if ended, subject color otherwise
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: time + badges
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${session.startTime} – ${session.endTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),

                          // Status badge (only for today)
                          if (isToday) ...[
                            _StatusBadge(status: status),
                            const SizedBox(width: 6),
                          ],

                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: typeColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              session.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subject name
                      Text(
                        session.subject,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Room & Lecturer
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: session.room,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 3),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: session.lecturer,
                        isDark: isDark,
                      ),

                      // Ongoing pulse indicator
                      if (isOngoing) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _PulseDot(),
                            const SizedBox(width: 6),
                            const Text(
                              'Happening now',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF22C55E),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    onTap: onEdit,
                  ),
                  const SizedBox(height: 4),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFFF6D6D),
                    onTap: onDelete,
                  ),
                ],
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

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
            color: const Color(0xFF22C55E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: const Text(
            'ONGOING',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
              letterSpacing: 0.8,
            ),
          ),
        );
      case ClassStatus.ended:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ENDED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
              letterSpacing: 0.8,
            ),
          ),
        );
      case ClassStatus.upcoming:
        return const SizedBox.shrink();
    }
  }
}

// ── Animated pulse dot ────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
