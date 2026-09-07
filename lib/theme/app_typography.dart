import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Inter-based typography scale for FYP Calendar.
/// Keep the six text styles below as the app-wide standard.
class AppTypography {
  AppTypography._();

  // ── Core styles ───────────────────────────────────────────────────────────
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: AppColors.textPrimary(context),
      );

  static TextStyle headingLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary(context),
      );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary(context),
      );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary(context),
      );

  static TextStyle bodyBold(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.textPrimary(context),
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: AppColors.textTertiary(context),
      );

  // ── Specialty ─────────────────────────────────────────────────────────────
  /// Section overlines, e.g. "UPCOMING EVENTS".
  static TextStyle overline(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textTertiary(context),
      );

  static TextStyle button(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Colors.white,
      );

  /// Numbers in stat cards / countdowns.
  static TextStyle statValue(BuildContext context) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.3,
        color: AppColors.textPrimary(context),
      );
}
