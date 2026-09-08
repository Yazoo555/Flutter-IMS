import 'package:flutter/material.dart';

/// Global design tokens for the FYP Calendar design system.
///
/// Design intent:
///  • calm academic command center, not a glowing "premium" dashboard
///  • hierarchy through spacing, surface, typography, and borders first;
///    shadows only where layering is meaningful
///  • one refined teal accent for actions/selection/links
///  • semantic category colors stay meaningful but share a common saturation
///    so they read as a system, not a rainbow
class DesignTokens {
  DesignTokens._();

  // ── Spacing scale ────────────────────────────────────────────────────────
  // A small, disciplined scale. Avoid inventing values between these.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ── Rhythm helpers (derived) ─────────────────────────────────────────────
  /// Standard reading line-height for body text.
  static const double bodyLineHeight = 1.5;

  /// Tight line-height for titles/labels/numbers.
  static const double tightLineHeight = 1.2;

  // ── Corner radii ─────────────────────────────────────────────────────────
  // Restrained. Full-radius only for chips/toggles/segmented controls.
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusSheet = 18;
  static const double radiusPill = 999;

  // ── Motion ───────────────────────────────────────────────────────────────
  // Fast, predictable, interruptible. No bouncing, pulsing, or "wow" motion.
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ── Layout / responsiveness ──────────────────────────────────────────────
  /// Width at which the shell switches from bottom navigation to a side rail.
  static const double navRailBreakpoint = 900;

  /// Standard horizontal page padding for narrow/medium content.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);

  /// Constrained content max-width for wide windows so text lines don't
  /// become unreadably long and cards don't stretch across the whole screen.
  static const double contentMaxWidth = 1180;

  // ── Elevation ────────────────────────────────────────────────────────────
  /// No elevation — most cards/sections in a calm dashboard.
  static List<BoxShadow> none() => const [];

  /// Subtle lift for the few components that deserve it.
  static List<BoxShadow> subtle({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];

  /// Slightly stronger lift for raised interactive surfaces (rare).
  static List<BoxShadow> raised({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  // ── Dividers ─────────────────────────────────────────────────────────────
  /// Subtle full-width divider used between grouped rows/sections.
  static BoxDecoration divider({required bool isDark}) => BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? borderDark : borderLight,
            width: 1,
          ),
        ),
      );

  // ── Internal helpers ─────────────────────────────────────────────────────
  // These mirror AppColors borders and are kept here only because the
  // elevation/divider helpers reference them directly.
  static const Color borderLight = Color(0xFFD8DCE3);
  static const Color borderDark = Color(0xFF263042);
}
