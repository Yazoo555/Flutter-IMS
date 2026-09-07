import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist_item.dart';
import '../models/fyp_event.dart';
import '../models/fyp_task.dart';
import '../models/meeting.dart';
import '../models/milestone.dart';
import '../models/project_info.dart';
import '../models/project_progress.dart';

/// Local-first persistence for the FYP Calendar.
///
/// Design principle: the OFFICIAL Cohort 11 event/milestone definitions in
/// `data/fyp_calendar_data.dart` are never written to storage. Storage holds
/// only *user state*. All decoders are failure-tolerant: malformed local
/// data degrades to an empty default instead of crashing the app.
class StorageService {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kCompletedEvents = 'fyp_completed_events';
  static const _kCustomEvents = 'fyp_custom_events';
  static const _kMilestoneProgress = 'fyp_milestone_progress';
  static const _kTasks = 'fyp_tasks';
  static const _kMeetings = 'fyp_meetings';
  static const _kProjectInfo = 'fyp_project_info';
  static const _kProjectProgress = 'fyp_project_progress';
  static const _kChecklists = 'fyp_checklists';
  static const _kThemeMode = 'fyp_theme_mode';

  // Notification preference keys.
  static const _kNotifEnabled = 'fyp_notif_enabled';
  static const _kNotifDeadlines = 'fyp_notif_deadlines';
  static const _kNotifPortals = 'fyp_notif_portals';
  static const _kNotifMeetings = 'fyp_notif_meetings';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Failure-tolerant JSON helpers ─────────────────────────────────────────

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // malformed data → empty default, never crash
    }
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Completed official events (id set) ────────────────────────────────────
  Future<Set<String>> loadCompletedEventIds() async {
    final prefs = await _prefs;
    try {
      return (prefs.getStringList(_kCompletedEvents) ?? []).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCompletedEventIds(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kCompletedEvents, ids.toList());
  }

  // ── Custom (user-created) events ──────────────────────────────────────────
  Future<List<FypEvent>> loadCustomEvents() async {
    final prefs = await _prefs;
    return _decodeList(prefs.getString(_kCustomEvents), FypEvent.fromJson);
  }

  Future<void> saveCustomEvents(List<FypEvent> events) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kCustomEvents,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addCustomEvent(FypEvent event, List<FypEvent> current) =>
      saveCustomEvents([...current, event]);

  Future<void> updateCustomEvent(FypEvent updated, List<FypEvent> current) =>
      saveCustomEvents(
        current.map((e) => e.id == updated.id ? updated : e).toList(),
      );

  Future<void> deleteCustomEvent(String id, List<FypEvent> current) =>
      saveCustomEvents(current.where((e) => e.id != id).toList());

  // ── Milestone progress ────────────────────────────────────────────────────
  Future<Map<String, MilestoneProgress>> loadMilestoneProgress() async {
    final prefs = await _prefs;
    final decoded = _decodeMap(prefs.getString(_kMilestoneProgress));
    if (decoded == null) return {};
    try {
      return decoded.map(
        (id, json) => MapEntry(
            id, MilestoneProgress.fromJson(json as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveMilestoneProgress(
      Map<String, MilestoneProgress> progress) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kMilestoneProgress,
      jsonEncode(progress.map((id, p) => MapEntry(id, p.toJson()))),
    );
  }

  // ── Preparation checklists ────────────────────────────────────────────────
  Future<List<ChecklistItem>> loadChecklistItems() async {
    final prefs = await _prefs;
    return _decodeList(
        prefs.getString(_kChecklists), ChecklistItem.fromJson);
  }

  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kChecklists,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────
  Future<List<FypTask>> loadTasks() async {
    final prefs = await _prefs;
    return _decodeList(prefs.getString(_kTasks), FypTask.fromJson);
  }

  Future<void> saveTasks(List<FypTask> tasks) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kTasks,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> addTask(FypTask t, List<FypTask> current) =>
      saveTasks([...current, t]);

  Future<void> updateTask(FypTask updated, List<FypTask> current) =>
      saveTasks(current.map((t) => t.id == updated.id ? updated : t).toList());

  Future<void> deleteTask(String id, List<FypTask> current) =>
      saveTasks(current.where((t) => t.id != id).toList());

  // ── Meetings ──────────────────────────────────────────────────────────────
  Future<List<Meeting>> loadMeetings() async {
    final prefs = await _prefs;
    return _decodeList(prefs.getString(_kMeetings), Meeting.fromJson);
  }

  Future<void> saveMeetings(List<Meeting> meetings) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kMeetings,
      jsonEncode(meetings.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> addMeeting(Meeting m, List<Meeting> current) =>
      saveMeetings([...current, m]);

  Future<void> updateMeeting(Meeting updated, List<Meeting> current) =>
      saveMeetings(
          current.map((m) => m.id == updated.id ? updated : m).toList());

  Future<void> deleteMeeting(String id, List<Meeting> current) =>
      saveMeetings(current.where((m) => m.id != id).toList());

  // ── Project info ──────────────────────────────────────────────────────────
  Future<ProjectInfo?> loadProjectInfo() async {
    final prefs = await _prefs;
    final decoded = _decodeMap(prefs.getString(_kProjectInfo));
    if (decoded == null) return null;
    try {
      return ProjectInfo.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProjectInfo(ProjectInfo info) async {
    final prefs = await _prefs;
    await prefs.setString(_kProjectInfo, jsonEncode(info.toJson()));
  }

  // ── Project progress (self-reported) ──────────────────────────────────────
  Future<ProjectProgress> loadProjectProgress() async {
    final prefs = await _prefs;
    final decoded = _decodeMap(prefs.getString(_kProjectProgress));
    if (decoded == null) return ProjectProgress();
    try {
      return ProjectProgress.fromJson(decoded);
    } catch (_) {
      return ProjectProgress();
    }
  }

  Future<void> saveProjectProgress(ProjectProgress progress) async {
    final prefs = await _prefs;
    await prefs.setString(
        _kProjectProgress, jsonEncode(progress.toJson()));
  }

  // ── Theme mode (system / light / dark) ────────────────────────────────────
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // dark-first, preserving the original default
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    await prefs.setString(_kThemeMode, mode.name);
  }

  // ── Notification preferences ──────────────────────────────────────────────
  Future<bool> loadNotifEnabled() async =>
      (await _prefs).getBool(_kNotifEnabled) ?? true;
  Future<void> saveNotifEnabled(bool v) async =>
      await (await _prefs).setBool(_kNotifEnabled, v);

  Future<bool> loadNotifDeadlines() async =>
      (await _prefs).getBool(_kNotifDeadlines) ?? true;
  Future<void> saveNotifDeadlines(bool v) async =>
      await (await _prefs).setBool(_kNotifDeadlines, v);

  Future<bool> loadNotifPortals() async =>
      (await _prefs).getBool(_kNotifPortals) ?? true;
  Future<void> saveNotifPortals(bool v) async =>
      await (await _prefs).setBool(_kNotifPortals, v);

  Future<bool> loadNotifMeetings() async =>
      (await _prefs).getBool(_kNotifMeetings) ?? true;
  Future<void> saveNotifMeetings(bool v) async =>
      await (await _prefs).setBool(_kNotifMeetings, v);
}

/// Per-milestone user progress overlay. `null` fields fall back to the
/// official definition.
class MilestoneProgress {
  final MilestoneStatus? status;
  final double? percentageComplete;
  final String? notes;

  const MilestoneProgress({this.status, this.percentageComplete, this.notes});

  Map<String, dynamic> toJson() => {
        'status': status?.name,
        'percentageComplete': percentageComplete,
        'notes': notes,
      };

  factory MilestoneProgress.fromJson(Map<String, dynamic> json) =>
      MilestoneProgress(
        status: json['status'] == null
            ? null
            : MilestoneStatus.values.firstWhere(
                (e) => e.name == json['status'],
                orElse: () => MilestoneStatus.notStarted,
              ),
        percentageComplete: (json['percentageComplete'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}
