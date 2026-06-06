import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart';

class StorageService {
  static const _sessionsKey = 'class_sessions';
  static const _themeKey = 'is_dark_mode';
  static const _seededKey = 'is_seeded';
  // ── Class Sessions ────────────────────────────────────────────────────────

  Future<List<ClassSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool(_seededKey) ?? false;
    if (!seeded) {
      await saveSessions(defaultRoutine);
      await prefs.setBool(_seededKey, true);
      return defaultRoutine;
    }
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => ClassSession.fromJson(e)).toList();
  }

  Future<void> saveSessions(List<ClassSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> addSession(ClassSession s, List<ClassSession> current) =>
      saveSessions([...current, s]);

  Future<void> updateSession(
    ClassSession updated,
    List<ClassSession> current,
  ) =>
      saveSessions(
        current.map((s) => s.id == updated.id ? updated : s).toList(),
      );

  Future<void> deleteSession(String id, List<ClassSession> current) =>
      saveSessions(current.where((s) => s.id != id).toList());

  // ── Tasks ─────────────────────────────────────────────────────────────────
  static const _tasksKey = 'tasks';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Task.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> addTask(Task t, List<Task> current) =>
      saveTasks([...current, t]);

  Future<void> updateTask(Task updated, List<Task> current) =>
      saveTasks(current.map((t) => t.id == updated.id ? updated : t).toList());

  Future<void> deleteTask(String id, List<Task> current) =>
      saveTasks(current.where((t) => t.id != id).toList());

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; // default dark
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}

// ── Task Model ──────────────────────────────────────────────────────────────

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, done }

enum TaskCategory { academic, personal, health, other }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskCategory category;
  final String? dueDate; // 'YYYY-MM-DD'
  final String? subject;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.category = TaskCategory.academic,
    this.dueDate,
    this.subject,
    this.completed = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    TaskCategory? category,
    String? dueDate,
    String? subject,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      subject: subject ?? this.subject,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.name,
    'status': status.name,
    'category': category.name,
    'dueDate': dueDate,
    'subject': subject,
    'completed': completed,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    priority: TaskPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => TaskPriority.medium,
    ),
    status: TaskStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TaskStatus.todo,
    ),
    category: TaskCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => TaskCategory.academic,
    ),
    dueDate: json['dueDate'],
    subject: json['subject'],
    completed: json['completed'] ?? false,
  );
}
