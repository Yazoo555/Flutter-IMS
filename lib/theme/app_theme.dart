import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2D6A2D);
  static const Color primaryDark = Color(0xFF1E4D1E);
  static const Color primaryLight = Color(0xFFE8F5E8);
  static const Color primaryLighter = Color(0xFFF0FAF0);
  static const Color accent = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF10B981);

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
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1C1F26);
  static const Color darkTextPrimary = Color(0xFFF1F3F5);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextHint = Color(0xFF6B7280);
  static const Color darkInputBackground = Color(0xFF252830);
  static const Color darkBorder = Color(0xFF2E323C);
  static const Color darkDivider = Color(0xFF2E323C);
  static const Color darkPrimaryLight = Color(0xFF1A2E1A);
  static const Color darkPrimaryLighter = Color(0xFF162416);

  // ── Text Styles ────────────────────────────────────────────────────────────
  static TextStyle heading1(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: getTextPrimary(context),
        letterSpacing: -0.5,
      );

  static TextStyle heading2(BuildContext context) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: getTextPrimary(context),
        letterSpacing: -0.3,
      );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: getTextSecondary(context),
        height: 1.5,
      );

  static TextStyle labelSmall(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: getTextSecondary(context),
        letterSpacing: 0.8,
      );

  static TextStyle linkText(BuildContext context) => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primary,
      );

  // ── Input Decoration ───────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    required BuildContext context,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: getTextHint(context),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? darkInputBackground : inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final brd = isDark ? darkBorder : border;

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surf,
        onSurface: txt,
        background: bg,
        onBackground: txt,
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
        titleTextStyle: TextStyle(
          color: txt,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surf,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? darkTextHint : textHint,
        elevation: 0,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: isDark ? darkTextHint : textHint,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: txt,
        iconColor: isDark ? darkTextSecondary : textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: brd,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withAlpha(80)
              : null,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurface : surface,
        selectedColor: primary.withAlpha(50),
        secondarySelectedColor: primary.withAlpha(50),
        labelStyle: TextStyle(
          color: isDark ? darkTextPrimary : textPrimary,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: brd),
        ),
      ),
    );
  }

  // ── Helper Getters ──────────────────────────────────────────────────────────
  static Color getBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color getSurface(BuildContext context) => Theme.of(context).cardColor;
  static Color getBorder(BuildContext context) =>
      Theme.of(context).dividerColor;
  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : textPrimary;
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : textSecondary;
  static Color getTextHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextHint : textHint;
}
