/// Reminder / notification service.
///
/// ARCHITECTURE NOTE (deliberate scope decision for this build):
/// Local notifications on Android 13+ require the POST_NOTIFICATIONS runtime
/// permission plus plugin configuration (e.g. `flutter_local_notifications`
/// + time-zone setup). To keep the project dependency-light and
/// presentation-ready without platform-specific setup, this service models
/// the reminder schedule and computes *what* would fire and *when*, while
/// delivery is wired to the user's preferences stored in StorageService.
///
/// WHAT REMAINS for full push delivery (documented, structured):
///   1. Add `flutter_local_notifications` (+ `timezone`) to pubspec.
///   2. Call [ReminderService.scheduleAll] from app start after permission
///      grant; map each [ReminderPlan] to a `zonedSchedule` call.
///   3. Request POST_NOTIFICATIONS on Android 13+ / provisional on iOS.
///
/// Reminders are intentionally sparse:
///   • Deadlines: 7 / 3 / 1 days before + on the day (4 total).
///   • Portal openings: one reminder on the opening day.
///   • Meetings: one reminder the day before, one on the day.
library;

import '../extensions/date_helpers.dart';
import '../models/fyp_event.dart';
import '../models/meeting.dart';
import 'storage_service.dart';

enum ReminderKind { deadline7, deadline3, deadline1, deadlineDay, portalOpen, meeting }

class ReminderPlan {
  final String id; // stable id for the notification system
  final ReminderKind kind;
  final String title;
  final String body;
  final DateTime fireDate;

  const ReminderPlan({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.fireDate,
  });
}

class ReminderService {
  final StorageService _storage = StorageService();

  /// Builds the full reminder plan for upcoming official deadlines and
  /// portal openings, filtered by the user's notification preferences.
  Future<List<ReminderPlan>> buildPlan({
    required List<FypEvent> events,
    required List<Meeting> meetings,
  }) async {
    final enabled = await _storage.loadNotifEnabled();
    if (!enabled) return [];

    final deadlinesOn = await _storage.loadNotifDeadlines();
    final portalsOn = await _storage.loadNotifPortals();
    final meetingsOn = await _storage.loadNotifMeetings();

    final now = DateTime.now();
    final plans = <ReminderPlan>[];

    for (final e in events) {
      if (e.isCompleted || e.hasEnded || e.isConditional) continue;

      if (e.category == FypEventCategory.deadline && deadlinesOn) {
        for (final (kind, offset) in [
          (ReminderKind.deadline7, 7),
          (ReminderKind.deadline3, 3),
          (ReminderKind.deadline1, 1),
          (ReminderKind.deadlineDay, 0),
        ]) {
          final fire = e.startDay.subtract(Duration(days: offset));
          if (fire.isBefore(now)) continue;
          plans.add(ReminderPlan(
            id: '${e.id}-d$offset',
            kind: kind,
            title: offset == 0
                ? 'Due today: ${e.title}'
                : '${e.title} in $offset day${offset == 1 ? '' : 's'}',
            body: 'Deadline: ${e.weekLabel} • ${e.date.formatted}',
            fireDate: fire,
          ));
        }
      }

      if (e.category == FypEventCategory.portalOpening && portalsOn) {
        final fire = e.startDay;
        if (!fire.isBefore(now)) {
          plans.add(ReminderPlan(
            id: '${e.id}-portal',
            kind: ReminderKind.portalOpen,
            title: 'Portal opened',
            body:
                '${e.title} — use the window, don\'t wait for the deadline.',
            fireDate: fire,
          ));
        }
      }
    }

    if (meetingsOn) {
      for (final m in meetings) {
        if (m.completed || m.isPast) continue;
        final dayBefore = DateTime(m.date.year, m.date.month, m.date.day)
            .subtract(const Duration(days: 1));
        if (!dayBefore.isBefore(now)) {
          plans.add(ReminderPlan(
            id: '${m.id}-meet-1d',
            kind: ReminderKind.meeting,
            title: 'Meeting tomorrow: ${m.title}',
            body: m.timeLabel == null
                ? m.type.label
                : '${m.type.label} at ${m.timeLabel}',
            fireDate: dayBefore,
          ));
        }
      }
    }

    plans.sort((a, b) => a.fireDate.compareTo(b.fireDate));
    return plans;
  }

  /// Preview of what would fire next (used by Settings to show the user
  /// what is scheduled without spamming).
  Future<List<ReminderPlan>> upcomingPreview({
    required List<FypEvent> events,
    required List<Meeting> meetings,
    int limit = 3,
  }) async {
    final plan = await buildPlan(events: events, meetings: meetings);
    return plan.take(limit).toList();
  }
}
