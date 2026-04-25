import '../main.dart';
import '../models/inventory_models.dart';
import '../models/logistics_models.dart';

class DashboardService {
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
    if (!forceRefresh && hasCache && !isCacheStale) {
      return (_cachedMonthly!, _cachedRecent!, _cachedTasks!);
    }

    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Run all three requests in parallel
    final results = await Future.wait([
      _fetchMonthly(user.id),
      _fetchRecent(),
      _fetchLatestTasks(),
    ]);

    _cachedMonthly = results[0] as List<MonthlyStockReport>;
    _cachedRecent = results[1] as List<RecentMovement>;
    _cachedTasks = results[2] as List<LogisticsTask>;
    _lastFetch = DateTime.now();

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
    // Optimization: Select only required columns for the dashboard preview
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
    // Optimization: Select only required columns for the dashboard preview
    final data = await supabase
        .from('logistics_tasks_detail')
        .select('id, title, status, created_at, supplier_name, user_id, supplier_id, updated_at')
        .order('created_at', ascending: false)
        .limit(5);

    return (data as List)
        .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static void clearCache() {
    _cachedMonthly = null;
    _cachedRecent = null;
    _cachedTasks = null;
    _lastFetch = null;
  }
}
