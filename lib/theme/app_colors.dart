import 'package:flutter/material.dart';

import '../models/fyp_event.dart';
import '../models/milestone.dart';
import '../models/fyp_task.dart';

/// FYP Calendar semantic color system.
///
/// Design intent:
///  • deep teal primary — academic, calm, distinctive (NOT purple/blue AI gradient)
///  • warm, restrained accents for categories
///  • dark is the primary mode, layered surfaces not pure black
///  • light mode is a real, intentional surface hierarchy
///  • color is never the only status indicator
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  // Refined teal — calm, academic, professional.
  // A cooler, more saturated teal that reads as intentional rather than
  // arbitrary. Paired with a deliberate hover/pressed scale.
  static const primary = Color(0xFF0E7C7D);
  static const primaryHover = Color(0xFF149698);
  static const primaryPressed = Color(0xFF0A5C5D);
  static const primarySoft = Color(0xFF5BA9A8);
  static const primaryContainer = Color(0xFF1A3D3E);

  // ── Semantic: FYP event categories ───────────────────────────────────────
  // A coherent, restrained palette. Each hue is distinct but shares a common
  // saturation level so they read as a system, not a rainbow.
  // Red is the only truly "urgent" color; everything else is informational.
  static const deadline = Color(0xFFC5302C); // Warm red — real urgency
  static const assessment = Color(0xFFC26A1E); // Burnt amber — defense/viva
  static const portalOpening = Color(0xFF9A7B14); // Deep gold — portal opens
  static const googleForm = Color(0xFF3578C5); // Clear blue — forms
  static const session = Color(0xFF2E8B57); // Seafoam green — workshops/lectures
  static const supervisor = Color(0xFF355E9B); // Deep blue — supervisor
  static const board = Color(0xFF5C6B7A); // Muted slate — results, grounded
  static const milestone = Color(0xFF3A7CA5); // Steel blue — milestones
  static const holiday = Color(0xFF6E7B8B); // Cool grey — non-teaching
  static const other = Color(0xFF6E7B8B); // Cool grey — uncategorized

  // ── Semantic: milestone / task statuses ──────────────────────────────────
  // Statuses use a clear progression: neutral → in-progress accent → done.
  static const statusNotStarted = Color(0xFF6E7B8B);
  static const statusInProgress = Color(0xFF0E7C7D); // Teal — matches primary
  static const statusSubmitted = Color(0xFF2E8B57);
  static const statusCompleted = Color(0xFF2E8B57);

  // ── Semantic: priorities ─────────────────────────────────────────────────
  // A clear priority ladder. Low is muted, critical is the only red.
  static const priorityLow = Color(0xFF5C7A5E);
  static const priorityMedium = Color(0xFF3A7CA5);
  static const priorityHigh = Color(0xFFC26A1E);
  static const priorityCritical = Color(0xFFC5302C);

  // ── Semantic: deadline health ────────────────────────────────────────────
  static const healthOnTrack = Color(0xFF2E8B57);
  static const healthNeedsAttention = Color(0xFFC26A1E);
  static const healthOverdue = Color(0xFFC5302C);

  // ── Semantic: neutral text roles ─────────────────────────────────────────
  // Dark mode — slightly warm, readable tones that complement the teal.
  static const textPrimaryDark = Color(0xFFEDEFF4);
  static const textSecondaryDark = Color(0xFFB0BACC);
  static const textTertiaryDark = Color(0xFF768294);
  static const textInverseDark = Color(0xFF0B0F19);

  // Light mode
  static const textPrimaryLight = Color(0xFF141822);
  static const textSecondaryLight = Color(0xFF4F5868);
  static const textTertiaryLight = Color(0xFF6E7B8B);
  static const textInverseLight = Color(0xFFFFFFFF);

  // ── Dark surfaces (primary mode) ─────────────────────────────────────────
  // A refined layered surface scale. The base is not pure black — it has a
  // subtle cool undertone that works with the teal accent.
  static const backgroundDark = Color(0xFF0B0F18);
  static const surfaceDark = Color(0xFF121926);
  static const surfaceDarkAlt = Color(0xFF182131);
  static const cardDark = Color(0xFF182131);
  static const cardDarkAlt = Color(0xFF1E283C);
  static const inputDark = Color(0xFF101826);

  // ── Light surfaces ───────────────────────────────────────────────────────
  // Warmer, more refined light surfaces. The background is a soft warm grey
  // that lets white cards sit with clear separation. Avoids the cold "system
  // grey" feel.
  static const backgroundLight = Color(0xFFF1F2F5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFF5F6F9);
  static const cardLight = Color(0xFFFFFFFF);
  static const inputLight = Color(0xFFF5F6F9);

  // ── Borders ──────────────────────────────────────────────────────────────
  // Borders are deliberate but quiet. In dark mode they have a cool tone;
  // in light mode they're a soft warm grey that reads clearly without feeling
  // heavy.
  static const borderDark = Color(0xFF263042);
  static const borderDarkStrong = Color(0xFF3A465C);
  static const borderLight = Color(0xFFD8DCE3);
  static const borderLightStrong = Color(0xFFC3C9D3);

  // ── Error / destructive ──────────────────────────────────────────────────
  static const error = deadline;
  static const errorContainerDark = Color(0xFF3A171C);
  static const errorContainerLight = Color(0xFFFBEAEA);

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

  /// A calm, neutral tint for chips/labels that should not carry semantic
  /// weight (e.g. the 'None' chip in editors).
  static const neutralChip = Color(0xFF6E7B8B);

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

  // ── Ranked lists (calendar filter, timeline sections) ──────────────────────
  // A single, calm "secondary" accent for unselected/timeline-upcoming roles
  // so the UI doesn't fragment into too many independent hues.
  static const secondary = Color(0xFF355E9B);
  static const secondaryContainer = Color(0xFF1A2A4A);

  // ── Brightness-based helpers (for theme construction, no BuildContext)

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

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      textPrimaryOn(Theme.of(context).brightness);

  static Color textSecondary(BuildContext context) =>
      textSecondaryOn(Theme.of(context).brightness);

  static Color textTertiary(BuildContext context) =>
      textTertiaryOn(Theme.of(context).brightness);

  static Color card(BuildContext context) =>
      cardOn(Theme.of(context).brightness);

  static Color surface(BuildContext context) =>
      surfaceOn(Theme.of(context).brightness);

  static Color surfaceAlt(BuildContext context) =>
      surfaceAltOn(Theme.of(context).brightness);

  static Color border(BuildContext context) =>
      borderOn(Theme.of(context).brightness);

  static Color borderStrong(BuildContext context) =>
      borderStrongOn(Theme.of(context).brightness);

  static Color scaffold(BuildContext context) =>
      scaffoldOn(Theme.of(context).brightness);

  static Color inputBackground(BuildContext context) =>
      inputBackgroundOn(Theme.of(context).brightness);
}
