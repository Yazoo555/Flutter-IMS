import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Material 3 ThemeData for the FYP Calendar, in dark (primary) and light
/// (complementary) variants. Both share the teal seed and Inter font.
class AppTheme {
  AppTheme._();

  static const seed = AppColors.primary;

  // ── Shared configuration ─────────────────────────────────────────────────
  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppColors.scaffoldOn(brightness),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),

      // Buttons — refined, calm, with clear hover/pressed states.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: isDark
                ? AppColors.borderDarkStrong
                : AppColors.borderLightStrong,
            width: 1.25,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondaryOn(brightness),
          padding: const EdgeInsets.all(10),
        ),
      ),

      // Cards: calm surface, no elevation by default.
      cardTheme: CardThemeData(
        color: AppColors.cardOn(brightness),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs: filled, calm, clear focus ring.
      inputDecorationTheme: _inputTheme(isDark: isDark, brightness: brightness),

      // Dialogs and bottom sheets
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceOn(brightness),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        backgroundColor: isDark
            ? AppColors.surfaceDarkAlt
            : AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),

      // Popups
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceOn(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        elevation: 0,
      ),

      // Toggles — crisp thumb, clear track.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white.withValues(alpha: 0.65);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.borderLight.withValues(alpha: 0.55);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Progress indicators — calm track, clear value.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.10),
        circularTrackColor: scheme.primary.withValues(alpha: 0.10),
        strokeWidth: 5,
        linearMinHeight: 4,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: AppColors.borderOn(brightness).withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),

      // Chips — subtle surface tint, clear but not heavy.
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.primaryContainer.withValues(alpha: 0.5)
            : AppColors.surfaceLightAlt,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),

      // Tab bar — clear selected state, restrained unselected.
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: AppColors.textTertiaryOn(brightness),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.15),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.08),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
    );
  }

  static ButtonStyle _buttonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return backgroundColor.withValues(alpha: 0.82);
        }
        if (states.contains(WidgetState.hovered)) {
          return backgroundColor.withValues(alpha: 0.93);
        }
        if (states.contains(WidgetState.focused)) {
          return backgroundColor.withValues(alpha: 0.95);
        }
        return null;
      }),
    );
  }

  static InputDecorationTheme _inputTheme({
    required bool isDark,
    required Brightness brightness,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackgroundOn(brightness),
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.borderDarkStrong
              : AppColors.borderLightStrong,
          width: 1.25,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.7)
              : AppColors.borderLight.withValues(alpha: 0.75),
          width: 1.25,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.35)
              : AppColors.borderLight.withValues(alpha: 0.45),
          width: 1.25,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      isDense: false,
    );
  }

  // ── Dark (primary mode) ─────────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary.withValues(alpha: 0.16),
      onPrimaryContainer: AppColors.textPrimaryDark,
      secondary: AppColors.supervisor,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceDarkAlt,
      onSurfaceVariant: AppColors.textSecondaryDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.textPrimaryDark,
    );

    return _base(scheme, Brightness.dark).copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      dividerColor: AppColors.borderDark,
    );
  }

  // ── Light (complementary mode) ──────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.textPrimaryLight,
      secondary: AppColors.supervisor,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceLightAlt,
      onSurfaceVariant: AppColors.textSecondaryLight,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainerLight,
      onErrorContainer: AppColors.textPrimaryLight,
    );

    return _base(scheme, Brightness.light).copyWith(
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.cardLight,
      dividerColor: AppColors.borderLight,
    );
  }
}
