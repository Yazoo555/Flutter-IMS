import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Inter-based typography scale for FYP Calendar.
///
/// Design intent:
///  • hierarchy through weight + line-height first, size second
///  • page titles are NOT giant display headings
///  • captions/overline are readable, not 9px bold hacks
///  • font weight is used deliberately — not bold everywhere
class AppTypography {
  AppTypography._();

  // ── Scale ────────────────────────────────────────────────────────────────

  /// Page title. Strong, calm, not overwhelming.
  static TextStyle pageTitle(BuildContext context) => _inter(
        fontSize: 20,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.3,
        color: AppColors.textPrimary(context),
      );

  /// Section title inside a screen (e.g. "UPCOMING IMPORTANT" over a list).
  static TextStyle sectionTitle(BuildContext context) => _inter(
        fontSize: 14,
        weight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0.1,
        color: AppColors.textPrimary(context),
      );

  /// Card/row headline (primary information inside a card).
  static TextStyle cardTitle(BuildContext context) => _inter(
        fontSize: 14,
        weight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0,
        color: AppColors.textPrimary(context),
      );

  /// Primary body text. Readable, calm — but not so muted that it recedes.
  static TextStyle body(BuildContext context) => _inter(
        fontSize: 13,
        weight: FontWeight.w400,
        height: DesignTokens.bodyLineHeight,
        letterSpacing: 0,
        color: AppColors.textSecondary(context),
      );

  /// Subdued body — metadata, secondary info that should recede slightly.
  static TextStyle bodySubdued(BuildContext context) => _inter(
        fontSize: 13,
        weight: FontWeight.w400,
        height: DesignTokens.bodyLineHeight,
        letterSpacing: 0,
        color: AppColors.textTertiary(context),
      );

  /// Emphasized body (primary within a row, but not a title).
  static TextStyle bodyEmphasized(BuildContext context) => _inter(
        fontSize: 13,
        weight: FontWeight.w500,
        height: DesignTokens.bodyLineHeight,
        letterSpacing: 0,
        color: AppColors.textPrimary(context),
      );

  /// Small readable label (metadata, secondary info, table cells).
  static TextStyle label(BuildContext context) => _inter(
        fontSize: 12,
        weight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
        color: AppColors.textSecondary(context),
      );

  /// Caption: smallest readable text — dates, hints, counts, footnotes.
  /// Slightly heavier weight so it stays legible at small sizes.
  static TextStyle caption(BuildContext context) => _inter(
        fontSize: 12,
        weight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.05,
        color: AppColors.textTertiary(context),
      );

  /// Caption in primary color — for labels that need to be readable but small.
  static TextStyle captionPrimary(BuildContext context) => _inter(
        fontSize: 12,
        weight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.05,
        color: AppColors.textPrimary(context),
      );

  /// Even smaller metadata, e.g. a count next to a section overline.
  static TextStyle metadata(BuildContext context) => _inter(
        fontSize: 11,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.2,
        color: AppColors.textTertiary(context),
      );

  /// Overline: small, uppercase, letter-spaced section labels (all-caps).
  /// A touch more contrast so section labels feel intentional, not faded.
  static TextStyle overline(BuildContext context) => _inter(
        fontSize: 11,
        weight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 1.1,
        color: AppColors.textTertiary(context),
      );

  /// Overline in primary — for active/selected section labels.
  static TextStyle overlinePrimary(BuildContext context) => _inter(
        fontSize: 11,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 1.1,
        color: AppColors.primary,
      );

  /// Button label.
  static TextStyle button(BuildContext context) => _inter(
        fontSize: 13,
        weight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0.2,
        color: Colors.white,
      );

  /// Stat/number style for compact numeric emphasis.
  static TextStyle statValue(BuildContext context) => _inter(
        fontSize: 20,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.3,
        color: AppColors.textPrimary(context),
      );

  /// Stat value colored by a semantic color (e.g. milestone progress).
  static TextStyle statValueColored(Color color, BuildContext context) => _inter(
        fontSize: 20,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.3,
        color: color,
      );

  /// Countdown number style for the deadline card.
  static TextStyle countdown(BuildContext context) => _inter(
        fontSize: 32,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.5,
        color: AppColors.textPrimary(context),
      );

  /// Countdown colored by urgency.
  static TextStyle countdownColored(Color color, BuildContext context) => _inter(
        fontSize: 32,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.5,
        color: color,
      );

  // ── Shared builder ───────────────────────────────────────────────────────
  static TextStyle _inter({
    required double fontSize,
    required FontWeight weight,
    required double height,
    required double letterSpacing,
    required Color color,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
}
