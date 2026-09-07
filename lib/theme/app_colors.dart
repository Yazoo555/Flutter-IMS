import 'package:flutter/material.dart';
import '../models/fyp_event.dart';
import '../models/milestone.dart';
import '../models/fyp_task.dart';

/// FYP Calendar semantic color system.
///
/// Colors communicate meaning first (deadline vs session vs portal …) and
/// decorate second. One accent family (indigo) carries the brand; semantic
/// hues are reserved for their meanings.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF4F46E5); // deep indigo
  static const primaryHover = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFFEEF2FF);

  // ── Semantic: FYP event categories ────────────────────────────────────────
  static const deadline = Color(0xFFEF4444); // red

  /// Alias used by error states (shares the deadline red).
  static const error = deadline;
  static const assessment = Color(0xFFF97316); // orange — defense / viva
  static const portalOpening = Color(0xFFF59E0B); // amber
  static const googleForm = Color(0xFF0EA5E9); // sky — Google Form open/close

  /// Informational blue (shares the medium-priority hue).
  static const info = priorityMedium;
  static const session = Color(0xFF22C55E); // green
  static const supervisor = Color(0xFF14B8A6); // teal
  static const board = Color(0xFF8B5CF6); // purple — board / results
  static const milestone = Color(0xFF6366F1); // indigo-light
  static const holiday = Color(0xFF94A3B8); // neutral gray
  static const other = Color(0xFF94A3B8); // neutral gray

  // ── Semantic: milestone / task statuses ───────────────────────────────────
  static const statusNotStarted = Color(0xFF94A3B8);
  static const statusInProgress = Color(0xFF3B82F6);
  static const statusSubmitted = Color(0xFF22C55E);
  static const statusCompleted = Color(0xFF22C55E);

  // ── Semantic: priorities ──────────────────────────────────────────────────
  static const priorityLow = Color(0xFF22C55E);
  static const priorityMedium = Color(0xFF3B82F6);
  static const priorityHigh = Color(0xFFF59E0B);
  static const priorityCritical = Color(0xFFEF4444);

  // ── Dark surfaces (primary mode) ──────────────────────────────────────────
  static const surfaceDark = Color(0xFF0B0F19);
  static const surfaceDarkAlt = Color(0xFF101624);
  static const cardDark = Color(0xFF161D2E);
  static const cardDarkAlt = Color(0xFF1C2538);
  static const borderDark = Color(0x16FFFFFF);
  static const borderDarkStrong = Color(0x26FFFFFF);
  static const textPrimaryDark = Color(0xFFF4F6FB);
  static const textSecondaryDark = Color(0xFFC3CADC);
  static const textTertiaryDark = Color(0xFF8B95AC);

  // ── Light surfaces ────────────────────────────────────────────────────────
  static const surfaceLight = Color(0xFFF7F8FC);
  static const surfaceLightAlt = Color(0xFFEFF1F8);
  static const cardLight = Colors.white;
  static const borderLight = Color(0xFFE4E7F0);
  static const textPrimaryLight = Color(0xFF151A2C);
  static const textSecondaryLight = Color(0xFF5B6478);
  static const textTertiaryLight = Color(0xFF98A0B3);

  // ── Category → color mapping ──────────────────────────────────────────────
  static Color categoryColor(FypEventCategory category) {
    switch (category) {
      case FypEventCategory.deadline:
        return deadline;
      case FypEventCategory.assessment:
        return assessment;
      case FypEventCategory.portalOpening:
        return portalOpening;
      case FypEventCategory.googleForm:
        return googleForm;
      case FypEventCategory.session:
        return session;
      case FypEventCategory.supervisor:
        return supervisor;
      case FypEventCategory.board:
        return board;
      case FypEventCategory.holiday:
        return holiday;
      case FypEventCategory.milestone:
        return milestone;
      case FypEventCategory.other:
        return other;
    }
  }

  static Color milestoneStatusColor(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.notStarted:
        return statusNotStarted;
      case MilestoneStatus.inProgress:
        return statusInProgress;
      case MilestoneStatus.submitted:
        return statusSubmitted;
    }
  }

  static Color taskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return statusNotStarted;
      case TaskStatus.inProgress:
        return statusInProgress;
      case TaskStatus.done:
        return statusCompleted;
    }
  }

  static Color priorityColor(FypPriority priority) {
    switch (priority) {
      case FypPriority.low:
        return priorityLow;
      case FypPriority.medium:
        return priorityMedium;
      case FypPriority.high:
        return priorityHigh;
      case FypPriority.critical:
        return priorityCritical;
    }
  }

  /// Same scale, for milestones (which use the local [FypPriorityLevel]).
  static Color priorityLevelColor(FypPriorityLevel priority) {
    switch (priority) {
      case FypPriorityLevel.low:
        return priorityLow;
      case FypPriorityLevel.medium:
        return priorityMedium;
      case FypPriorityLevel.high:
        return priorityHigh;
      case FypPriorityLevel.critical:
        return priorityCritical;
    }
  }

  static Color taskPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return priorityLow;
      case TaskPriority.medium:
        return priorityMedium;
      case TaskPriority.high:
        return priorityHigh;
      case TaskPriority.critical:
        return priorityCritical;
    }
  }

  // ── Contextual neutrals ───────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textTertiaryDark
          : textTertiaryLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? borderDark
          : borderLight;

  static Color scaffold(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
