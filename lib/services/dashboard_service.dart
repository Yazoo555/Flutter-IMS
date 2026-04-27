import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/inventory_models.dart';
import '../models/logistics_models.dart';

class DashboardService {
  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kMonthly = 'dash_cached_monthly';
  static const _kRecent = 'dash_cached_recent';
  static const _kTasks = 'dash_cached_tasks';
  static const _kLastFetch = 'dash_last_fetch_time';

  // ── Cache ──────────────────────────────────────────────────────────────────
  static List<MonthlyStockReport>? _cachedMonthly;
  static List<RecentMovement>? _cachedRecent;
  static List<LogisticsTask>? _cachedTasks;
  static DateTime? _lastFetch;

  static bool get hasCache =>
      _cachedMonthly != null && _cachedRecent != null && _cachedTasks != null;

  static bool get isCacheStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!).inMinutes > 5;

  // ── Data Fetching ──────────────────────────────────────────────────────────

  static Future<(List<MonthlyStockReport>, List<RecentMovement>, List<LogisticsTask>)>
      fetchDashboardData({bool forceRefresh = false}) async {
    
    // 1. If not forcing refresh, try to return valid in-memory cache
    if (!forceRefresh && hasCache && !isCacheStale) {
      return (_cachedMonthly!, _cachedRecent!, _cachedTasks!);
    }

    // 2. Try to load from SharedPreferences if memory cache is empty
    if (!hasCache) {
      await _loadFromPrefs();
      // If we found valid data on disk and not forcing, return it
      if (!forceRefresh && hasCache && !isCacheStale) {
        return (_cachedMonthly!, _cachedRecent!, _cachedTasks!);
      }
    }

    // 3. Fetch from API
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final results = await Future.wait([
      _fetchMonthly(user.id),
      _fetchRecent(),
      _fetchLatestTasks(),
    ]);

    _cachedMonthly = results[0] as List<MonthlyStockReport>;
    _cachedRecent = results[1] as List<RecentMovement>;
    _cachedTasks = results[2] as List<LogisticsTask>;
    _lastFetch = DateTime.now();

    // Save to disk asynchronously
    _saveToPrefs();

    return (_cachedMonthly!, _cachedRecent!, _cachedTasks!);
  }

  static Future<List<MonthlyStockReport>> _fetchMonthly(String userId) async {
    final data = await supabase.rpc('get_monthly_report_with_value', params: {
      'p_user_id': userId,
      'p_year': DateTime.now().year,
    });
    return (data as List)
        .map((e) => MonthlyStockReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RecentMovement>> _fetchRecent() async {
    final data = await supabase
        .from('recent_movements_with_value')
        .select('created_at, item_name, movement_type, quantity, transaction_value')
        .order('created_at', ascending: false)
        .limit(5);

    return (data as List)
        .map((e) => RecentMovement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LogisticsTask>> _fetchLatestTasks() async {
    final data = await supabase
        .from('logistics_tasks_detail')
        .select('id, title, status, created_at, supplier_name, user_id, supplier_id, updated_at')
        .order('created_at', ascending: false)
        .limit(5);

    return (data as List)
        .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyJson = prefs.getString(_kMonthly);
      final recentJson = prefs.getString(_kRecent);
      final tasksJson = prefs.getString(_kTasks);
      final lastFetchMillis = prefs.getInt(_kLastFetch);

      if (monthlyJson != null) {
        _cachedMonthly = (jsonDecode(monthlyJson) as List)
            .map((e) => MonthlyStockReport.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (recentJson != null) {
        _cachedRecent = (jsonDecode(recentJson) as List)
            .map((e) => RecentMovement.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (tasksJson != null) {
        _cachedTasks = (jsonDecode(tasksJson) as List)
            .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (lastFetchMillis != null) {
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
      }
    } catch (e) {
      // Ignore errors loading from prefs
    }
  }

  static Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedMonthly != null) {
        prefs.setString(_kMonthly, jsonEncode(_cachedMonthly));
      }
      if (_cachedRecent != null) {
        prefs.setString(_kRecent, jsonEncode(_cachedRecent));
      }
      if (_cachedTasks != null) {
        prefs.setString(_kTasks, jsonEncode(_cachedTasks));
      }
      if (_lastFetch != null) {
        prefs.setInt(_kLastFetch, _lastFetch!.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Ignore errors saving to prefs
    }
  }

  static void clearCache() async {
    _cachedMonthly = null;
    _cachedRecent = null;
    _cachedTasks = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_kMonthly);
    prefs.remove(_kRecent);
    prefs.remove(_kTasks);
    prefs.remove(_kLastFetch);
  }
}
