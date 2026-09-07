/// Deadline Health — a single, calm answer to "how am I doing?".
///
/// Simple rules (documented so the student understands the result):
///   • Overdue   — any critical-priority official deadline has passed unfinished
///   • Needs Attention — a critical deadline is within 3 days, OR any
///     overdue items exist at all
///   • On Track  — otherwise
library;

import '../models/fyp_event.dart';

enum DeadlineHealthStatus { onTrack, needsAttention, overdue }

class DeadlineHealth {
  final DeadlineHealthStatus status;
  final int upcomingCount;
  final int overdueCount;
  final int completedCount;

  const DeadlineHealth({
    required this.status,
    required this.upcomingCount,
    required this.overdueCount,
    required this.completedCount,
  });

  (String, String) get labelAndHint => switch (status) {
        DeadlineHealthStatus.onTrack => (
          'On Track',
          'No overdue items and nothing critical within 3 days.'
        ),
        DeadlineHealthStatus.needsAttention => (
          'Needs Attention',
          'A critical deadline is close — plan the next few days carefully.'
        ),
        DeadlineHealthStatus.overdue => (
          'Overdue',
          'One or more critical deadlines have passed unfinished.'
        ),
      };
}

/// Computes deadline health from official + custom events.
DeadlineHealth computeDeadlineHealth(List<FypEvent> events) {
  var upcoming = 0, overdue = 0, completed = 0;
  var criticalSoon = false, criticalOverdue = false;

  for (final e in events) {
    if (e.isCompleted) {
      completed++;
      continue;
    }
    if (e.hasEnded) {
      if (e.category != FypEventCategory.holiday) overdue++;
      if (e.category == FypEventCategory.deadline) criticalOverdue = true;
      continue;
    }
    upcoming++;
    if (e.category == FypEventCategory.deadline && e.daysRemaining <= 3) {
      criticalSoon = true;
    }
  }

  final status = criticalOverdue
      ? DeadlineHealthStatus.overdue
      : (criticalSoon || overdue > 0)
          ? DeadlineHealthStatus.needsAttention
          : DeadlineHealthStatus.onTrack;

  return DeadlineHealth(
    status: status,
    upcomingCount: upcoming,
    overdueCount: overdue,
    completedCount: completed,
  );
}
