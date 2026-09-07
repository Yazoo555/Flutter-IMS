import 'package:shared_preferences/shared_preferences.dart';

import '../data/fyp_calendar_data.dart';
import '../models/checklist_item.dart';
import '../models/fyp_event.dart';
import '../models/fyp_task.dart';
import '../models/meeting.dart';
import '../models/milestone.dart';
import '../models/project_info.dart';
import '../models/project_progress.dart';
import 'storage_service.dart';

/// Facade over the official Cohort 11 dataset + local user state.
///
/// Screens never read `fyp_calendar_data.dart` directly; they ask the
/// repository, which:
///   • merges official events with user-created events,
///   • applies completion flags without touching official definitions,
///   • overlays milestone progress on the official milestones,
///   • provides "today" queries (next deadline, overdue, upcoming).
class FypRepository {
  final StorageService _storage = StorageService();

  // ── Events ────────────────────────────────────────────────────────────────

  /// All events (official + custom) with completion state applied,
  /// sorted chronologically.
  Future<List<FypEvent>> loadAllEvents() async {
    final results = await Future.wait([
      loadOfficialEvents(),
      _storage.loadCustomEvents(),
    ]);
    return [...results[0], ...results[1]]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Official events with user completion flags applied.
  Future<List<FypEvent>> loadOfficialEvents() async {
    final completed = await _storage.loadCompletedEventIds();
    return officialEvents
        .map((e) =>
            completed.contains(e.id) ? e.copyWith(isCompleted: true) : e)
        .toList();
  }

  Future<void> toggleEventCompleted(FypEvent event) async {
    final completed = await _storage.loadCompletedEventIds();
    if (completed.contains(event.id)) {
      completed.remove(event.id);
    } else {
      completed.add(event.id);
    }
    await _storage.saveCompletedEventIds(completed);
  }

  /// Adds a user-created personal event (stored separately from officials).
  Future<void> addCustomEvent(FypEvent event) async {
    final current = await _storage.loadCustomEvents();
    await _storage.addCustomEvent(event, current);
  }

  Future<void> updateCustomEvent(FypEvent event) async {
    final current = await _storage.loadCustomEvents();
    await _storage.updateCustomEvent(event, current);
  }

  Future<void> deleteCustomEvent(String id) async {
    final current = await _storage.loadCustomEvents();
    await _storage.deleteCustomEvent(id, current);
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  /// Official milestones with user progress overlaid, sorted by deadline.
  Future<List<Milestone>> loadMilestones() async {
    final progress = await _storage.loadMilestoneProgress();
    return officialMilestones.map((m) {
      final p = progress[m.id];
      if (p == null) return m;
      return m.copyWith(
        status: p.status,
        percentageComplete: p.percentageComplete,
        notes: p.notes != null && p.notes!.isNotEmpty ? p.notes : m.notes,
      );
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  /// Saves status/progress for one milestone.
  Future<void> saveMilestoneProgress(
    String milestoneId, {
    MilestoneStatus? status,
    double? percentageComplete,
    String? notes,
  }) async {
    final all = await _storage.loadMilestoneProgress();
    final existing = all[milestoneId] ?? const MilestoneProgress();
    all[milestoneId] = MilestoneProgress(
      status: status ?? existing.status,
      percentageComplete: percentageComplete ?? existing.percentageComplete,
      notes: notes ?? existing.notes,
    );
    await _storage.saveMilestoneProgress(all);
  }

  // ── "Today" queries (real DateTime logic) ─────────────────────────────────

  /// Next unfinished deadline/assessment from today onward.
  Future<FypEvent?> nextDeadline() async {
    final events = await loadAllEvents();
    final upcoming = events
        .where((e) =>
            !e.isCompleted &&
            (e.category == FypEventCategory.deadline ||
                e.category == FypEventCategory.assessment) &&
            !e.hasEnded)
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first;
  }

  /// Events that are due today (started today, not completed).
  Future<List<FypEvent>> eventsToday() async {
    final events = await loadAllEvents();
    return events.where((e) => e.isToday && !e.hasEnded).toList();
  }

  /// Next upcoming events (today onward), newest first, limited.
  Future<List<FypEvent>> upcomingEvents({int limit = 10}) async {
    final events = await loadAllEvents();
    return events
        .where((e) => !e.hasEnded && e.date.isBefore(
              DateTime.now().add(const Duration(days: 400)),
            ))
        .where((e) => e.endDay.isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            ))
        .take(limit)
        .toList();
  }

  /// Unfinished events whose deadline has fully passed.
  Future<List<FypEvent>> overdueEvents() async {
    final events = await loadAllEvents();
    return events
        .where((e) =>
            !e.isCompleted &&
            e.category != FypEventCategory.holiday &&
            e.hasEnded)
        .toList();
  }

  // ── Preparation checklists (personal, per milestone) ──────────────────

  Future<List<ChecklistItem>> loadChecklistItems() =>
      _storage.loadChecklistItems();

  Future<void> addChecklistItem(String milestoneId, String title) async {
    final items = await _storage.loadChecklistItems();
    items.add(ChecklistItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      milestoneId: milestoneId,
      title: title,
    ));
    await _storage.saveChecklistItems(items);
  }

  Future<void> toggleChecklistItem(ChecklistItem item) async {
    final items = await _storage.loadChecklistItems();
    final updated =
        items.map((i) => i.id == item.id ? i.copyWith(done: !i.done) : i).toList();
    await _storage.saveChecklistItems(updated);
  }

  Future<void> deleteChecklistItem(ChecklistItem item) async {
    final items = await _storage.loadChecklistItems();
    await _storage.saveChecklistItems(
        items.where((i) => i.id != item.id).toList());
  }

  // ── Dashboard helpers ──────────────────────────────────────────────────────

  /// Next 5 important events (deadline > assessment > milestone-linked >
  /// portal > other), then other events. Everything unfinished and not ended.
  Future<List<FypEvent>> importantUpcoming({int limit = 5}) async {
    final events = await loadAllEvents();
    int rank(FypEvent e) => switch (e.category) {
          FypEventCategory.deadline => 0,
          FypEventCategory.assessment => 1,
          FypEventCategory.milestone => 2,
          FypEventCategory.portalOpening => 3,
          FypEventCategory.googleForm => 3,
          _ => 4,
        };
    final upcoming = events
        .where((e) => !e.isCompleted && !e.hasEnded)
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        final r = rank(a) - rank(b);
        return r != 0 ? r : byDate;
      });
    return upcoming.take(limit).toList();
  }

  /// Milestone completion summary: (completed, total, percentage).
  Future<(int, int, double)> milestoneStats() async {
    final milestones = await loadMilestones();
    final done = milestones.where((m) => m.isComplete).length;
    final pct = milestones.isEmpty ? 0.0 : done / milestones.length;
    return (done, milestones.length, pct);
  }

  /// Average of milestone percentageComplete values (project-completion
  /// proxy computed from user-tracked progress, not from milestone counts).
  Future<double> milestoneProgressAverage() async {
    final milestones = await loadMilestones();
    if ( milestones.isEmpty) return 0;
    final sum = milestones
        .map((m) => m.percentageComplete)
        .reduce((a, b) => a + b);
    return sum / milestones.length;
  }

  /// Events linked to a milestone, sorted by date.
  Future<List<FypEvent>> eventsForMilestone(String milestoneId) async {
    final events = await loadAllEvents();
    return events.where((e) => e.relatedMilestoneId == milestoneId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Tasks ────────────────────────────────────────────────────────────────

  Future<List<FypTask>> loadTasks() => _storage.loadTasks();

  Future<void> addTask(FypTask task) async {
    final current = await _storage.loadTasks();
    await _storage.addTask(task, current);
  }

  Future<void> updateTask(FypTask task) async {
    final current = await _storage.loadTasks();
    await _storage.updateTask(task, current);
  }

  Future<void> deleteTask(String id) async {
    final current = await _storage.loadTasks();
    await _storage.deleteTask(id, current);
  }

  /// Task completion summary: done / total / overdue (past-due, not done).
  Future<(int, int, int)> taskStats() async {
    final tasks = await _storage.loadTasks();
    final done = tasks.where((t) => t.isComplete).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = tasks
        .where((t) =>
            !t.isComplete &&
            t.dueDate != null &&
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day)
                .isBefore(today))
        .length;
    return (done, tasks.length, overdue);
  }

  /// Number of open (not done) tasks linked to a milestone.
  Future<int> openTaskCountForMilestone(String milestoneId) async {
    final tasks = await _storage.loadTasks();
    return tasks
        .where((t) => t.relatedMilestoneId == milestoneId && !t.isComplete)
        .length;
  }

  // ── Meetings ────────────────────────────────────────────────────────────

  Future<List<Meeting>> loadMeetings() => _storage.loadMeetings();

  Future<void> addMeeting(Meeting meeting) async {
    final current = await _storage.loadMeetings();
    await _storage.addMeeting(meeting, current);
  }

  Future<void> updateMeeting(Meeting meeting) async {
    final current = await _storage.loadMeetings();
    await _storage.updateMeeting(meeting, current);
  }

  Future<void> deleteMeeting(String id) async {
    final current = await _storage.loadMeetings();
    await _storage.deleteMeeting(id, current);
  }

  // ── Project progress (self-reported) ──────────────────────────────────────

  Future<ProjectProgress> loadProjectProgress() =>
      _storage.loadProjectProgress();

  Future<void> saveProjectProgress(ProjectProgress progress) =>
      _storage.saveProjectProgress(progress);

  // ── Settings passthrough ──────────────────────────────────────────────────

  // ── Project info (user-editable metadata) ─────────────────────────────────

  Future<ProjectInfo?> loadProjectInfo() => _storage.loadProjectInfo();
  Future<void> saveProjectInfo(ProjectInfo info) =>
      _storage.saveProjectInfo(info);

  /// Test/dev helper: wipe user state (official data is code-defined).
  Future<void> resetUserState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Summary of everything stored locally (for the Settings export view).
  Future<Map<String, String>> exportSummary() async {
    final results = await Future.wait([
      loadAllEvents(),
      loadMilestones(),
      loadTasks(),
      loadMeetings(),
      loadChecklistItems(),
      loadProjectProgress(),
      loadProjectInfo(),
    ]);
    final events = results[0] as List<FypEvent>;
    final tasks = results[2] as List<FypTask>;
    final progress = results[5] as ProjectProgress;
    final info = results[6] as ProjectInfo?;
    return {
      'Official events': '${events.length}',
      'Completed events': '${events.where((e) => e.isCompleted).length}',
      'Milestones': '${(results[1] as List<Milestone>).length}',
      'Tasks': '${tasks.length} (${tasks.where((t) => t.isComplete).length} done)',
      'Meetings': '${(results[3] as List<Meeting>).length}',
      'Checklist items': '${(results[4] as List<ChecklistItem>).length}',
      'Project progress': '${progress.overallPercent}%',
      'Project title': info?.title.isEmpty ?? true ? '(not set)' : info!.title,
    };
  }
}
