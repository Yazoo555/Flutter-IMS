import 'package:flutter/material.dart';

/// Global design tokens for the FYP Calendar design system.
///
/// Keep every hardcoded value out of widgets — pull from here so the whole
/// app stays visually consistent.
class DesignTokens {
  DesignTokens._();

  // ── Spacing scale ─────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Corner radii ──────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 26;
  static const double radiusSheet = 30;
  static const double radiusFull = 999;

  // ── Motion ────────────────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ── Layout ────────────────────────────────────────────────────────────────
  /// Width at which the shell switches from bottom navigation to sidebar.
  static const double desktopBreakpoint = 900;

  /// Standard horizontal page padding.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);

  // ── Elevation (soft, ambient — avoid harsh drop shadows) ─────────────────
  static List<BoxShadow> cardShadows({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];

  static List<BoxShadow> glowShadows(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
