import 'package:flutter/material.dart';

class AppColors {
  // Accent — indigo-teal
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFFEEEDFF);

  // Subject colors
  static const subjectColors = [
    Color(0xFF6C63FF), // indigo
    Color(0xFF00BFA5), // teal
    Color(0xFFFF6D6D), // coral
    Color(0xFFFFB347), // orange
  ];

  // Type badge colors
  static Color typeColor(String type) {
    switch (type) {
      case 'Lecture':
        return const Color(0xFF6C63FF);
      case 'Workshop':
        return const Color(0xFF00BFA5);
      case 'Tutorial':
        return const Color(0xFFFF6D6D);
      case 'Lab':
        return const Color(0xFFFFB347);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  static Color subjectColor(String subject) {
    switch (subject) {
      case 'Cloud Systems':
        return const Color(0xFF00BFA5);
      case 'Collaborative Development':
        return const Color(0xFF6C63FF);
      case 'Algorithms and Concurrency':
        return const Color(0xFFFF6D6D);
      default:
        return const Color(0xFF6C63FF);
    }
  }
}

class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F7FB),
    cardColor: Colors.white,
    fontFamily: 'Georgia',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F7FB),
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Color(0xFF1A1A2E),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Georgia',
      ),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F18),
    cardColor: const Color(0xFF1A1A2E),
    fontFamily: 'Georgia',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F18),
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Color(0xFFF0EDE6),
      titleTextStyle: TextStyle(
        color: Color(0xFFF0EDE6),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Georgia',
      ),
    ),
  );
}
