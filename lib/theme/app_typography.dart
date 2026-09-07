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
///
/// The six-to-twelve styles below are the app-wide standard. If a widget
/// needs a style not here, prefer adjusting weight/size within this system
/// rather than inventing an ad-hoc GoogleFonts.inter(...) call.
class AppTypography {
  AppTypography._();

  // ── Scale ────────────────────────────────────────────────────────────────

  /// Rare, large moments only (e.g. an onboarding hero — not a normal page
  /// title). In this product, use sparingly.
  static TextStyle displayLarge(BuildContext context) => _inter(
        fontSize: 30,
        weight: FontWeight.w800,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.6,
        color: AppColors.textPrimary(context),
      );

  /// Page title. Strong, calm, not overwhelming.
  static TextStyle pageTitle(BuildContext context) => _inter(
        fontSize: 22,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.3,
        color: AppColors.textPrimary(context),
      );

  /// Section title inside a screen (e.g. "UPCOMING IMPORTANT" over a list).
  static TextStyle sectionTitle(BuildContext context) => _inter(
        fontSize: 15,
        weight: FontWeight.w700,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0.2,
        color: AppColors.textPrimary(context),
      );

  /// Card/row headline (primary information inside a card).
  static TextStyle cardTitle(BuildContext context) => _inter(
        fontSize: 15,
        weight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0,
        color: AppColors.textPrimary(context),
      );

  /// Primary body text.
  static TextStyle body(BuildContext context) => _inter(
        fontSize: 14,
        weight: FontWeight.w400,
        height: DesignTokens.bodyLineHeight,
        letterSpacing: 0,
        color: AppColors.textSecondary(context),
      );

  /// Emphasized body (primary within a row, but not a title).
  static TextStyle bodyEmphasized(BuildContext context) => _inter(
        fontSize: 14,
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
  /// Never use smaller than this for readable content.
  static TextStyle caption(BuildContext context) => _inter(
        fontSize: 12,
        weight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.1,
        color: AppColors.textTertiary(context),
      );

  /// Even smaller metadata, e.g. a count next to a section overline.
  static TextStyle metadata(BuildContext context) => _inter(
        fontSize: 11,
        weight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: AppColors.textTertiary(context),
      );

  /// Overline: small, uppercase, letter-spaced section labels (all-caps).
  static TextStyle overline(BuildContext context) => _inter(
        fontSize: 11,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 1.4,
        color: AppColors.textTertiary(context),
      );

  /// Button label.
  static TextStyle button(BuildContext context) => _inter(
        fontSize: 14,
        weight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
        letterSpacing: 0.2,
        color: Colors.white,
      );

  /// Stat/number style for compact numeric emphasis (counts, percentages,
  /// countdown numbers) without resorting to giant display text everywhere.
  static TextStyle statValue(BuildContext context) => _inter(
        fontSize: 20,
        weight: FontWeight.w800,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.3,
        color: AppColors.textPrimary(context),
      );

  /// Largish stat value for a "hero number" moment where the number itself
  /// is the point (e.g. self-reported overall %). Calmer than displayLarge.
  static TextStyle statLarge(BuildContext context) => _inter(
        fontSize: 34,
        weight: FontWeight.w800,
        height: DesignTokens.tightLineHeight,
        letterSpacing: -0.5,
        color: AppColors.textPrimary(context),
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
