import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart';
import '../models/todo_item.dart';

class StorageService {
  static const _sessionsKey = 'class_sessions';
  static const _themeKey = 'is_dark_mode';
  static const _seededKey = 'is_seeded';
  static const _todosKey = 'todo_items';

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
  ) => saveSessions(
    current.map((s) => s.id == updated.id ? updated : s).toList(),
  );

  Future<void> deleteSession(String id, List<ClassSession> current) =>
      saveSessions(current.where((s) => s.id != id).toList());

  // ── Todo Items ────────────────────────────────────────────────────────────

  Future<List<TodoItem>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todosKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => TodoItem.fromJson(e)).toList();
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _todosKey,
      jsonEncode(todos.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> addTodo(TodoItem todo, List<TodoItem> current) =>
      saveTodos([...current, todo]);

  Future<void> updateTodo(TodoItem updated, List<TodoItem> current) =>
      saveTodos(current.map((t) => t.id == updated.id ? updated : t).toList());

  Future<void> deleteTodo(String id, List<TodoItem> current) =>
      saveTodos(current.where((t) => t.id != id).toList());

  Future<void> toggleTodo(String id, List<TodoItem> current) async {
    final todos = current
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
    await saveTodos(todos);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}
