import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2D6A2D);
  static const Color primaryDark = Color(0xFF1E4D1E);
  static const Color primaryLight = Color(0xFFE8F5E8);
  static const Color primaryLighter = Color(0xFFF0FAF0);
  static const Color accent = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color inputBackground = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color otpBackground = Color(0xFFDCEEDC);
  static const Color cardShadowColor = Color(0x0A000000);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF111318);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFF9AA0AB);
  static const Color darkTextHint = Color(0xFF5F6570);
  static const Color darkInputBackground = Color(0xFF22252E);
  static const Color darkBorder = Color(0xFF2A2E38);
  static const Color darkDivider = Color(0xFF2A2E38);
  static const Color darkPrimaryLight = Color(0xFF1A2E1A);
  static const Color darkPrimaryLighter = Color(0xFF162416);
  static const Color darkOtpBackground = Color(0xFF1A2E1A);
  static const Color darkCardShadowColor = Color(0x33000000);
  static const Color darkErrorColor = Color(0xFFEF5350);

  // ── Text Styles (light-mode defaults — use context.heading1 etc.) ────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: primary,
  );

  // ── Input Decoration (context-aware) ──────────────────────────────────────
  static InputDecoration inputDecorationOf(
    BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final c = AppColors.of(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: c.textHint,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: c.inputBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  // Keep old signature for backward compatibility (light-mode only)
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textHint,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  // ── Button Style ───────────────────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 0,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get theme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBackground : background;
    final surf = isDark ? darkSurface : surface;
    final txt = isDark ? darkTextPrimary : textPrimary;
    final txtSec = isDark ? darkTextSecondary : textSecondary;
    final brd = isDark ? darkBorder : border;
    final inputBg = isDark ? darkInputBackground : inputBackground;

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surf,
        error: isDark ? darkErrorColor : errorColor,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surf,
      dividerColor: brd,
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        foregroundColor: txt,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: txt),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surf),
      bottomNavigationBarTheme:
          BottomNavigationBarThemeData(backgroundColor: surf),
      dialogTheme: DialogThemeData(backgroundColor: surf),
      listTileTheme: ListTileThemeData(textColor: txt),
      popupMenuTheme: PopupMenuThemeData(
        color: surf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: TextStyle(color: isDark ? darkTextHint : textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: txt),
        bodySmall: TextStyle(color: txtSec),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withAlpha(80)
              : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Theme-aware color accessor ──────────────────────────────────────────────
/// Use `AppColors.of(context)` or the `context.colors` extension to get
/// adaptive colors that automatically switch between light and dark mode.
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.dark);
  }

  // Surfaces
  Color get background =>
      isDark ? AppTheme.darkBackground : AppTheme.background;
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.surface;

  // Text
  Color get textPrimary =>
      isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get textSecondary =>
      isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get textHint => isDark ? AppTheme.darkTextHint : AppTheme.textHint;

  // Input
  Color get inputBackground =>
      isDark ? AppTheme.darkInputBackground : AppTheme.inputBackground;

  // Borders
  Color get border => isDark ? AppTheme.darkBorder : AppTheme.border;
  Color get divider => isDark ? AppTheme.darkDivider : AppTheme.divider;

  // Brand shades
  Color get primaryLight =>
      isDark ? AppTheme.darkPrimaryLight : AppTheme.primaryLight;
  Color get primaryLighter =>
      isDark ? AppTheme.darkPrimaryLighter : AppTheme.primaryLighter;

  // OTP
  Color get otpBackground =>
      isDark ? AppTheme.darkOtpBackground : AppTheme.otpBackground;

  // Shadow
  Color get cardShadow =>
      isDark ? AppTheme.darkCardShadowColor : AppTheme.cardShadowColor;

  // Adaptive text styles
  TextStyle get heading1 =>
      AppTheme.heading1.copyWith(color: textPrimary);
  TextStyle get heading2 =>
      AppTheme.heading2.copyWith(color: textPrimary);
  TextStyle get bodyMedium =>
      AppTheme.bodyMedium.copyWith(color: textSecondary);
  TextStyle get labelSmall =>
      AppTheme.labelSmall.copyWith(color: textSecondary);
  TextStyle get linkText => AppTheme.linkText;
}

/// Convenient extension so you can write `context.colors.surface` etc.
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors.of(this);
}
