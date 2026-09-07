import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Material 3 ThemeData for the FYP Calendar, in dark (primary) and light
/// (complementary) variants. Both share the indigo seed and Inter font, and
/// both use the same structural decisions: calm surfaces, restrained
/// elevation, coherent controls.
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

      // App bars are transparent so the shell owns the surface layout.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.dark
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

      // Primary button: filled/elevated share one coherent treatment.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          isDark: isDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          isDark: isDark,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: const BorderSide(color: AppColors.borderLightStrong, width: 1.25),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      // Icon buttons: consistent hit target + tooltip-friendly defaults.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondaryOn(brightness),
          padding: const EdgeInsets.all(10),
        ),
      ),

      // Cards: calm surface, very subtle elevation only where used.
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

      // Dialogs and bottom sheets share the same surface and radius.
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
        ),
      ),

      // Snackbars float with a calm shape, no harsh behavior.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        backgroundColor: isDark
            ? AppColors.surfaceDarkAlt
            : AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),

      // Popups (menus, etc.) use the same surface.
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceOn(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        elevation: 0,
      ),

      // Toggles: clear, calm, consistent thumb.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.borderLight.withValues(alpha: 0.5);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Progress: calm tracks, brand color for value.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.15),
        circularTrackColor: scheme.primary.withValues(alpha: 0.15),
        strokeWidth: 6,
      ),

      // Divider: subtle, not a visible line everywhere.
      dividerTheme: DividerThemeData(
        color: AppColors.borderOn(brightness),
        thickness: 1,
        space: 1,
      ),

      // Chip: calm defaults (we often style chips per-context anyway).
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
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

      // Tab bar: calm, not a loud indicator bar.
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: AppColors.textTertiaryOn(brightness),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    required bool isDark,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return backgroundColor.withValues(alpha: 0.85);
        }
        if (states.contains(WidgetState.hovered)) {
          return backgroundColor.withValues(alpha: 0.92);
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
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderLightStrong, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.6)
              : AppColors.borderLight.withValues(alpha: 0.8),
          width: 1,
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
              ? AppColors.borderDark.withValues(alpha: 0.4)
              : AppColors.borderLight.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
