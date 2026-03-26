import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          if (isToday)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            day.toUpperCase(),
            style: TextStyle(
              fontSize: isToday ? 15 : 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isToday
                  ? const Color(0xFF6C63FF)
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.07),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$classCount ${classCount == 1 ? 'class' : 'classes'}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
