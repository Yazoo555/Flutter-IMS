import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────

class DesignTokens {
  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;

  // Border radius — 12–16px for premium feel
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusSheet = 28;
  static const double radiusFull = 999;

  // Durations — 200–300ms smooth transitions
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ── Shadows ────────────────────────────────────────────────────────────────

  static List<BoxShadow> shadowsDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowsElevatedDark = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> indigoGlow = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.25),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowsLight = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowsElevatedLight = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

// ── Color System ──────────────────────────────────────────────────────────────
// Premium SaaS palette: Deep Indigo primary on dark matte surface.

class AppColors {
  // ── Primary — Deep Indigo ──────────────────────────────────────────────────
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFFEEF2FF);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryHover = Color(0xFF6366F1);

  // ── Secondary — Violet ─────────────────────────────────────────────────────
  static const secondary = Color(0xFF7C3AED);
  static const secondaryLight = Color(0xFFF5F3FF);

  // ── Accent — Cyan ──────────────────────────────────────────────────────────
  static const accent = Color(0xFF06B6D4);
  static const accentLight = Color(0xFFECFEFF);

  // ── Semantic Colors ────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);

  // ── Neutrals — Dark (Primary Mode) ─────────────────────────────────────────
  static const surfaceDark = Color(0xFF0B0F19);
  static const surfaceDarkAlt = Color(0xFF111827);
  static const surfaceDarkMid = Color(0xFF131A2A);
  static const cardDark = Color(0xFF171E2E);
  static const cardDarkAlt = Color(0xFF1E2838);
  static const cardDarkBorder = Color(0x14FFFFFF);

  // Dark text
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFD1D5DB);
  static const textTertiaryDark = Color(0xFF9CA3AF);
  static const textCaptionDark = Color(0xFF6B7280);

  // Dark borders
  static const borderDark = Color(0x14FFFFFF);
  static const borderDarkStrong = Color(0x1FFFFFFF);

  // ── Neutrals — Light (Complementary) ───────────────────────────────────────
  static const surfaceLight = Color(0xFFF8F7FC);
  static const surfaceLightAlt = Color(0xFFF0EEF7);
  static const cardLight = Colors.white;
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);
  static const borderLight = Color(0xFFE5E7EB);

  // ── Subject Colors ─────────────────────────────────────────────────────────
  static const subjectColors = [
    Color(0xFF4F46E5), // indigo
    Color(0xFF06B6D4), // cyan
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF10B981), // emerald
  ];

  static Color typeColor(String type) {
    switch (type) {
      case 'Lecture':
        return primary;
      case 'Workshop':
        return const Color(0xFF06B6D4);
      case 'Tutorial':
        return const Color(0xFF8B5CF6);
      case 'Lab':
        return const Color(0xFFF59E0B);
      default:
        return primary;
    }
  }

  static Color subjectColor(String subject) {
    switch (subject) {
      case 'Cloud Systems':
        return const Color(0xFF06B6D4);
      case 'Collaborative Development':
        return primary;
      case 'Algorithms and Concurrency':
        return const Color(0xFF8B5CF6);
      default:
        return primary;
    }
  }
}

// ── Typography ─────────────────────────────────────────────────────────────────

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get title => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondaryDark,
  );

  static TextStyle get bodyBold => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textSecondaryDark,
  );

  static TextStyle get small => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiaryDark,
  );

  static TextStyle get smallBold => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textTertiaryDark,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.textCaptionDark,
  );

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 1.5,
    color: AppColors.textCaptionDark,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,
    color: Colors.white,
  );
}

// ── Theme Data ─────────────────────────────────────────────────────────────────

class AppTheme {
  // ── Dark Theme (Primary) ───────────────────────────────────────────────────
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.borderDark,
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      headlineLarge: AppTypography.headingLarge,
      headlineMedium: AppTypography.headingMedium,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.bodyBold,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.small,
      labelLarge: AppTypography.button,
      labelSmall: AppTypography.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimaryDark,
      titleTextStyle: AppTypography.headingLarge.copyWith(
        color: AppColors.textPrimaryDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        textStyle: AppTypography.button,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textTertiaryDark,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardDarkAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
    ),
  );

  // ── Light Theme (Complementary) ────────────────────────────────────────────
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surfaceLight,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.surfaceLight,
    cardColor: AppColors.cardLight,
    dividerColor: AppColors.borderLight,
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      headlineLarge: AppTypography.headingLarge.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      headlineMedium: AppTypography.headingMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: AppTypography.title.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: AppTypography.bodyBold.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: AppTypography.body.copyWith(
        color: AppColors.textSecondaryLight,
      ),
      bodyMedium: AppTypography.small.copyWith(
        color: AppColors.textTertiaryLight,
      ),
      labelLarge: AppTypography.button.copyWith(
        color: Colors.white,
      ),
      labelSmall: AppTypography.caption.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimaryLight,
      titleTextStyle: AppTypography.headingLarge.copyWith(
        color: AppColors.textPrimaryLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        textStyle: AppTypography.button,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textTertiaryLight,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
    ),
  );

  // ── Contextual helpers ──────────────────────────────────────────────────────

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;

  static List<BoxShadow> cardShadows(BuildContext context) =>
      isDark(context) ? DesignTokens.shadowsDark : DesignTokens.shadowsLight;

  static List<BoxShadow> elevatedShadows(BuildContext context) =>
      isDark(context)
          ? DesignTokens.shadowsElevatedDark
          : DesignTokens.shadowsElevatedLight;

  static List<BoxShadow> primaryGlow(BuildContext context) =>
      DesignTokens.indigoGlow;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  static Color textSecondary(BuildContext context) => isDark(context)
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight;

  static Color textTertiary(BuildContext context) => isDark(context)
      ? AppColors.textTertiaryDark
      : AppColors.textTertiaryLight;

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.borderDark : AppColors.borderLight;
}
