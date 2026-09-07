import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

/// Material 3 ThemeData for the FYP Calendar, in dark (primary) and light
/// (complementary) variants. Both share the indigo seed and Inter font.
class AppTheme {
  AppTheme._();

  static const seed = AppColors.primary;

  // ── Dark (primary mode) ───────────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.supervisor,
      surface: AppColors.surfaceDark,
      error: AppColors.deadline,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.surfaceDark,
      cardColor: AppColors.cardDark,
      dividerColor: AppColors.borderDark,
      textTheme: _textTheme(Brightness.dark),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white.withValues(alpha: 0.05),
        hint: AppColors.textTertiaryDark,
        focus: AppColors.primary,
        error: AppColors.deadline,
      ),
    );
  }

  // ── Light (complementary mode) ────────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.supervisor,
      surface: AppColors.surfaceLight,
      error: AppColors.deadline,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.surfaceLight,
      cardColor: AppColors.cardLight,
      dividerColor: AppColors.borderLight,
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: _inputTheme(
        fill: Colors.black.withValues(alpha: 0.03),
        hint: AppColors.textTertiaryLight,
        focus: AppColors.primary,
        error: AppColors.deadline,
      ),
    );
  }

  // ── Shared component themes ───────────────────────────────────────────────
  static ThemeData _base(ColorScheme scheme) {
    final radiusMd = BorderRadius.circular(DesignTokens.radiusMd);
    final radiusLg = BorderRadius.circular(DesignTokens.radiusLg);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.brightness == Brightness.dark
            ? AppColors.cardDarkAlt
            : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : (scheme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.borderLight),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color hint,
    required Color focus,
    required Color error,
  }) {
    final radiusMd = BorderRadius.circular(DesignTokens.radiusMd);
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: hint),
      border: OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static TextTheme _textTheme(Brightness brightness) => TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: brightness == Brightness.dark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: brightness == Brightness.dark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
      );
}
