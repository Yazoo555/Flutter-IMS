import 'package:flutter/material.dart';

import '../models/fyp_event.dart';
import '../theme/app_colors.dart';

/// Urgency buckets used across the dashboard and cards.
enum Urgency { overdue, today, tomorrow, thisWeek, upcoming }

/// Computes the urgency of an event from the real clock.
Urgency urgencyOf(FypEvent event) {
  if (!event.isCompleted && event.hasEnded) return Urgency.overdue;
  if (event.isToday) return Urgency.today;
  final days = event.daysRemaining;
  if (days == 1) return Urgency.tomorrow;
  if (days > 1 && days <= 7) return Urgency.thisWeek;
  return Urgency.upcoming;
}

/// Label + color per urgency bucket (no animations — just calm emphasis).
(String, Color) urgencyStyle(BuildContext context, Urgency u) => switch (u) {
      Urgency.overdue => ('Overdue', AppColors.error),
      Urgency.today => ('Today', AppColors.deadline),
      Urgency.tomorrow => ('Tomorrow', AppColors.priorityHigh),
      Urgency.thisWeek => ('This week', AppColors.priorityHigh),
      Urgency.upcoming => ('Upcoming', AppColors.primary),
    };

/// Central mapping of event categories to icons and priority display labels,
/// following the source sheet's taxonomy (deadline = highest urgency,
/// holiday = informational).
class EventVisuals {
  EventVisuals._();

  static IconData categoryIcon(FypEventCategory category) =>
      switch (category) {
        FypEventCategory.deadline => Icons.alarm_rounded,
        FypEventCategory.assessment => Icons.school_rounded,
        FypEventCategory.portalOpening => Icons.app_registration_rounded,
        FypEventCategory.googleForm => Icons.fact_check_rounded,
        FypEventCategory.session => Icons.co_present_rounded,
        FypEventCategory.supervisor => Icons.supervisor_account_rounded,
        FypEventCategory.board => Icons.gavel_rounded,
        FypEventCategory.holiday => Icons.beach_access_rounded,
        FypEventCategory.milestone => Icons.flag_rounded,
        FypEventCategory.other => Icons.event_rounded,
      };

  /// Display label for a priority; holidays show as informational.
  static String priorityLabel(FypEventCategory category, FypPriority priority) =>
      category == FypEventCategory.holiday
          ? 'Info'
          : switch (priority) {
              FypPriority.low => 'Low',
              FypPriority.medium => 'Medium',
              FypPriority.high => 'High',
              FypPriority.critical => 'Critical',
            };

  static Color categoryColor(FypEventCategory category) =>
      AppColors.categoryColor(category);

  static Color priorityColor(FypPriority priority) =>
      AppColors.priorityColor(priority);
}
