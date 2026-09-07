import 'package:flutter/material.dart';

import '../models/fyp_event.dart';
import '../models/milestone.dart';
import '../models/fyp_task.dart';

/// FYP Calendar semantic color system.
///
/// Design intent:
///  • one brand accent (indigo) for actions, selection, links, selected states
///  • semantic category colors stay meaningful but quieter in shared UI
///  • dark is the primary mode, but dark surfaces are layered, not "pure black"
///  • light mode is a real, intentional surface hierarchy (not a swapped palette)
///  • color is never the only status indicator
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  // The single brand accent. Used for primary actions, selected nav,
  // links, focus rings, and a few "this is the thing to look at" moments.
  // It is NOT used as a gradient or a glow.
  static const primary = Color(0xFF4F46E5);
  static const primaryHover = Color(0xFF6366F1);
  static const primaryPressed = Color(0xFF3730A3);

  // A slightly softer indigo used only for very small selected accents
  // (e.g. a selected chip text tint) where full primary would feel heavy.
  static const primarySoft = Color(0xFF818CF8);

  // ── Semantic: FYP event categories ───────────────────────────────────────
  // Meaning is preserved. Loudness is reduced: these are now muted "text and
  // small indicator" colors, not default card-fill colors.
  //
  // In shared UI, most events are read by label + icon + structure first,
  // color second. Deadline remains the most visually urgent, but it no longer
  // glows around every card that mentions a deadline.
  static const deadline = Color(0xFFDC2626); // red — real urgency
  static const assessment = Color(0xFFEA580C); // orange — defense / viva
  static const portalOpening = Color(0xFFCA8A04); // amber — portal opens
  static const googleForm = Color(0xFF0284C7); // sky — Google Form open/close
  static const session = Color(0xFF16A34A); // green — session/workshop
  static const supervisor = Color(0xFF0D9488); // teal — supervisor/reader
  static const board = Color(0xFF7C3AED); // purple — board / results
  static const milestone = Color(0xFF6366F1); // indigo — milestone marker
  static const holiday = Color(0xFF94A3B8); // neutral — non-teaching
  static const other = Color(0xFF94A3B8); // neutral — uncategorized

  // ── Semantic: milestone / task statuses ──────────────────────────────────
  // These are status text/indicator colors, not decorative fills.
  static const statusNotStarted = Color(0xFF94A3B8);
  static const statusInProgress = Color(0xFF2563EB);
  static const statusSubmitted = Color(0xFF16A34A);
  static const statusCompleted = Color(0xFF16A34A);

  // ── Semantic: priorities ─────────────────────────────────────────────────
  // Intentionally restrained: critical/red is the only "stop and pay attention"
  // color; the rest are quiet enough to sit in a list without shouting.
  static const priorityLow = Color(0xFF16A34A);
  static const priorityMedium = Color(0xFF2563EB);
  static const priorityHigh = Color(0xFFCA8A04);
  static const priorityCritical = Color(0xFFDC2626);

  // ── Semantic: deadline health ────────────────────────────────────────────
  static const healthOnTrack = Color(0xFF16A34A);
  static const healthNeedsAttention = Color(0xFFCA8A04);
  static const healthOverdue = Color(0xFFDC2626);

  // ── Semantic: neutral text roles ─────────────────────────────────────────
  // These are the main text colors. Prefer them over arbitrary whites/grays.
  // They are fixed so text stays readable regardless of theme gymnastics.
  //
  // Dark mode
  static const textPrimaryDark = Color(0xFFF4F6FB);
  static const textSecondaryDark = Color(0xFFC3CADC);
  static const textTertiaryDark = Color(0xFF8B95AC);
  static const textInverseDark = Color(0xFF0B0F19);

  // Light mode
  static const textPrimaryLight = Color(0xFF151A2C);
  static const textSecondaryLight = Color(0xFF5B6478);
  static const textTertiaryLight = Color(0xFF8A93A6);
  static const textInverseLight = Color(0xFFFFFFFF);

  // ── Dark surfaces (primary mode) ─────────────────────────────────────────
  // A layered surface scale. The background is dark; surfaces sit at a few
  // distinct levels so we can separate things with surface, not only shadow.
  static const backgroundDark = Color(0xFF0B0F19);
  static const surfaceDark = Color(0xFF101624);
  static const surfaceDarkAlt = Color(0xFF161D2E);
  static const cardDark = Color(0xFF161D2E);
  static const cardDarkAlt = Color(0xFF1C2538);
  static const inputDark = Color(0xFF0E1420);

  // ── Light surfaces ───────────────────────────────────────────────────────
  // Calm off-white background; surfaces are slightly cooler/warmer as needed.
  // Cards are NOT pure white everywhere — that creates a "floating white card
  // on everything" look. Use surfaceLight as the main content surface.
  static const backgroundLight = Color(0xFFF4F5F8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFF7F8FC);
  static const cardLight = Color(0xFFFFFFFF);
  static const inputLight = Color(0xFFF7F8FC);

  // ── Borders ──────────────────────────────────────────────────────────────
  // Subtle, not harsh. Useful for grouping/separation and for input focus.
  static const borderDark = Color(0xFF2A3247);
  static const borderDarkStrong = Color(0xFF3A445C);
  static const borderLight = Color(0xFFE4E7F0);
  static const borderLightStrong = Color(0xFFD2D7E3);

  // ── Error / destructive ──────────────────────────────────────────────────
  // Shares deadline red intentionally — error and overdue deadline are the
  // same visual urgency in this product.
  static const error = deadline;
  static const errorContainerDark = Color(0xFF3B161C);
  static const errorContainerLight = Color(0xFFFCE4E4);

  // ── Category → color mapping ─────────────────────────────────────────────
  static Color categoryColor(FypEventCategory category) {
    return switch (category) {
      FypEventCategory.deadline => deadline,
      FypEventCategory.assessment => assessment,
      FypEventCategory.portalOpening => portalOpening,
      FypEventCategory.googleForm => googleForm,
      FypEventCategory.session => session,
      FypEventCategory.supervisor => supervisor,
      FypEventCategory.board => board,
      FypEventCategory.holiday => holiday,
      FypEventCategory.milestone => milestone,
      FypEventCategory.other => other,
    };
  }

  static Color milestoneStatusColor(MilestoneStatus status) {
    return switch (status) {
      MilestoneStatus.notStarted => statusNotStarted,
      MilestoneStatus.inProgress => statusInProgress,
      MilestoneStatus.submitted => statusSubmitted,
    };
  }

  static Color taskStatusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => statusNotStarted,
      TaskStatus.inProgress => statusInProgress,
      TaskStatus.done => statusCompleted,
    };
  }

  static Color priorityColor(FypPriority priority) {
    return switch (priority) {
      FypPriority.low => priorityLow,
      FypPriority.medium => priorityMedium,
      FypPriority.high => priorityHigh,
      FypPriority.critical => priorityCritical,
    };
  }

  static Color priorityLevelColor(FypPriorityLevel priority) {
    return switch (priority) {
      FypPriorityLevel.low => priorityLow,
      FypPriorityLevel.medium => priorityMedium,
      FypPriorityLevel.high => priorityHigh,
      FypPriorityLevel.critical => priorityCritical,
    };
  }

  static Color taskPriorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => priorityLow,
      TaskPriority.medium => priorityMedium,
      TaskPriority.high => priorityHigh,
      TaskPriority.critical => priorityCritical,
    };
  }

  // ── Brightness-based helpers (for theme construction, no BuildContext)
  // These are used by AppTheme internals where there is no BuildContext yet.
  // They carry an "On" suffix because Dart has no overloading: the
  // BuildContext helpers below keep the plain names.
  // Widget code should prefer the BuildContext helpers below.

  static bool _isDark(Brightness brightness) => brightness == Brightness.dark;

  static Color textPrimaryOn(Brightness brightness) =>
      _isDark(brightness) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondaryOn(Brightness brightness) =>
      _isDark(brightness) ? textSecondaryDark : textSecondaryLight;

  static Color textTertiaryOn(Brightness brightness) =>
      _isDark(brightness) ? textTertiaryDark : textTertiaryLight;

  static Color scaffoldOn(Brightness brightness) =>
      _isDark(brightness) ? backgroundDark : backgroundLight;

  static Color cardOn(Brightness brightness) =>
      _isDark(brightness) ? cardDark : cardLight;

  static Color surfaceOn(Brightness brightness) =>
      _isDark(brightness) ? surfaceDark : surfaceLight;

  static Color surfaceAltOn(Brightness brightness) =>
      _isDark(brightness) ? surfaceDarkAlt : surfaceLightAlt;

  static Color borderOn(Brightness brightness) =>
      _isDark(brightness) ? borderDark : borderLight;

  static Color borderStrongOn(Brightness brightness) =>
      _isDark(brightness) ? borderDarkStrong : borderLightStrong;

  static Color inputBackgroundOn(Brightness brightness) =>
      _isDark(brightness) ? inputDark : inputLight;

  // ── BuildContext helpers (for widgets)
  // Prefer these inside widget trees. They delegate to the brightness-based
  // helpers above so the values stay consistent.

  /// True when the current theme is dark.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Main text color for the current theme.
  static Color textPrimary(BuildContext context) =>
      textPrimaryOn(Theme.of(context).brightness);

  /// Secondary/muted text color.
  static Color textSecondary(BuildContext context) =>
      textSecondaryOn(Theme.of(context).brightness);

  /// Tertiary/captions/placeholder text color.
  static Color textTertiary(BuildContext context) =>
      textTertiaryOn(Theme.of(context).brightness);

  /// Surface color for card/section backgrounds in the current theme.
  static Color card(BuildContext context) =>
      cardOn(Theme.of(context).brightness);

  /// Slightly cooler surface alt (e.g. section backgrounds, sheet body).
  static Color surface(BuildContext context) =>
      surfaceOn(Theme.of(context).brightness);

  /// A surface that's intended to be very slightly distinct from [card].
  static Color surfaceAlt(BuildContext context) =>
      surfaceAltOn(Theme.of(context).brightness);

  /// Border color for the current theme.
  static Color border(BuildContext context) =>
      borderOn(Theme.of(context).brightness);

  /// Stronger border for emphasis (selected state, focused input, etc.).
  static Color borderStrong(BuildContext context) =>
      borderStrongOn(Theme.of(context).brightness);

  /// Scaffold background for the current theme.
  static Color scaffold(BuildContext context) =>
      scaffoldOn(Theme.of(context).brightness);

  /// Input fill color for the current theme.
  static Color inputBackground(BuildContext context) =>
      inputBackgroundOn(Theme.of(context).brightness);
}
