

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/logistics_models.dart';

class LogisticsService {
  static const String _baseUrl =
      'https://zinognrruckgcmrxgzro.supabase.co/rest/v1';

  // ── Cache Keys ─────────────────────────────────────────────────────────────
  static const _kSuppliers = 'log_cached_suppliers';
  static const _kTasks = 'log_cached_tasks';
  static const _kLastFetchSuppliers = 'log_last_fetch_suppliers';
  static const _kLastFetchTasks = 'log_last_fetch_tasks';

  // ── In-Memory Cache ────────────────────────────────────────────────────────
  static List<Supplier>? _cachedSuppliers;
  static List<LogisticsTask>? _cachedTasks;
  static DateTime? _lastFetchSuppliers;
  static DateTime? _lastFetchTasks;

  static bool get hasSuppliersCache => _cachedSuppliers != null;
  static bool get hasTasksCache => _cachedTasks != null;

  static bool get isSuppliersStale =>
      _lastFetchSuppliers == null ||
      DateTime.now().difference(_lastFetchSuppliers!).inMinutes > 5;

  static bool get isTasksStale =>
      _lastFetchTasks == null ||
      DateTime.now().difference(_lastFetchTasks!).inMinutes > 5;

  /// Invalidate in-memory cache (e.g. after mutations).
  static void invalidateSuppliers() {
    _cachedSuppliers = null;
    _lastFetchSuppliers = null;
  }

  static void invalidateTasks() {
    _cachedTasks = null;
    _lastFetchTasks = null;
  }

  /// Clear both in-memory and on-disk cache (e.g. on logout).
  static void clearCache() async {
    _cachedSuppliers = null;
    _cachedTasks = null;
    _lastFetchSuppliers = null;
    _lastFetchTasks = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_kSuppliers);
    prefs.remove(_kTasks);
    prefs.remove(_kLastFetchSuppliers);
    prefs.remove(_kLastFetchTasks);
  }

  static String? get _authToken => supabase.auth.currentSession?.accessToken != null
      ? 'Bearer ${supabase.auth.currentSession!.accessToken}'
      : null;

  static String get _apiKey => supabaseAnonKey;

  static String? get userId => supabase.auth.currentUser?.id;

  // ── Session-wait helper ────────────────────────────────────────────────────
  /// Returns true when the current access token exists and won't expire within
  /// the next 60 seconds.
  static bool _isTokenValid() {
    if (_authToken == null) return false;
    final expiresAt = supabase.auth.currentSession?.expiresAt; // seconds since epoch
    if (expiresAt == null) return true; // no expiry info → assume valid
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt > nowSecs + 60;
  }

  /// Waits up to ~5 s for Supabase to restore the persisted session on cold
  /// start, and refreshes an expired token before returning.
  /// Returns the Bearer token, or null if the session never arrived.
  static Future<String?> _waitForAuthToken() async {
    // Fast path: session already present and not expired.
    if (_isTokenValid()) return _authToken;

    // Token exists but is expired (or about to expire) — refresh it now.
    // This is the main cause of the post-idle "Retry" state: after a long
    // break Supabase restores the session from storage but the access token
    // has expired.  Raw http calls don't trigger the SDK's auto-refresh, so
    // we must do it explicitly.
    if (_authToken != null && !_isTokenValid()) {
      try {
        await supabase.auth.refreshSession();
        if (_isTokenValid()) return _authToken;
      } catch (_) {
        // Refresh failed — fall through to the polling loop.
      }
    }

    // Slow path: session not yet restored on cold start — poll up to 5 s.
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_isTokenValid()) return _authToken;
      // Mid-poll refresh attempt if a session appeared but is already expired.
      if (_authToken != null && !_isTokenValid()) {
        try {
          await supabase.auth.refreshSession();
          if (_isTokenValid()) return _authToken;
        } catch (_) {}
      }
    }
    return null;
  }

  // ── Shared headers ──────────────────────────────────────────────────────────

  static Map<String, String> _buildHeaders(String? token) => {
        if (token != null) 'Authorization': token,
        'apikey': _apiKey,
        'Content-Type': 'application/json',
      };

  static Map<String, String> _buildHeadersWithReturn(String? token) => {
        ..._buildHeaders(token),
        'Prefer': 'return=representation',
      };

  // ── Suppliers ───────────────────────────────────────────────────────────────

  /// Fetch all suppliers.
  ///
  /// Strategy (cache-first):
  ///   • Fresh in-memory cache  → return immediately.
  ///   • Stale or missing       → load disk cache if needed, then:
  ///       – If stale cache exists and forceRefresh=false → return stale data
  ///         NOW so the UI is never empty; the screen's background-refresh
  ///         will update it silently.
  ///       – If no cache at all, or forceRefresh=true    → hit network.
  static Future<List<Supplier>> getSuppliers({bool forceRefresh = false}) async {
    // 1. Return valid in-memory cache immediately.
    if (!forceRefresh && hasSuppliersCache && !isSuppliersStale) {
      return _cachedSuppliers!;
    }

    // 2. Hydrate in-memory cache from disk if needed.
    if (!hasSuppliersCache) {
      await _loadSuppliersFromPrefs();
    }

    // 3. Cache-first: return stale data immediately so the UI always has
    //    something to show.  The screen's _refreshSuppliersInBackground()
    //    (triggered when isSuppliersStale is true after this return) will
    //    fetch fresh data silently — fixing the post-idle "Retry" state.
    if (!forceRefresh && hasSuppliersCache) {
      return _cachedSuppliers!;
    }

    // 4. No cache at all, or forceRefresh=true → fetch from network.
    final token = await _waitForAuthToken();
    final uri = Uri.parse('$_baseUrl/suppliers?order=name.asc');
    final response = await http.get(uri, headers: _buildHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Failed to load suppliers: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    final suppliers = data
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();

    _cachedSuppliers = suppliers;
    _lastFetchSuppliers = DateTime.now();
    _saveSuppliersToPrefs();

    return suppliers;
  }

  /// Create a new supplier.
  static Future<Supplier> createSupplier({
    required String name,
    String? contactName,
    required String email,
    required String phone,
    required String address,
  }) async {
    final uri = Uri.parse('$_baseUrl/suppliers');
    final body = jsonEncode({
      'user_id': userId,
      'name': name,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'address': address,
    });

    final token = await _waitForAuthToken();
    final response =
        await http.post(uri, headers: _buildHeadersWithReturn(token), body: body);

    if (response.statusCode != 201) {
      throw Exception('Failed to create supplier: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return Supplier.fromJson(data.first as Map<String, dynamic>);
  }

  /// Update an existing supplier.
  static Future<void> updateSupplier(
    String supplierId,
    Map<String, dynamic> fields,
  ) async {
    final uri = Uri.parse('$_baseUrl/suppliers?id=eq.$supplierId');
    final token = await _waitForAuthToken();
    final response =
        await http.patch(uri, headers: _buildHeaders(token), body: jsonEncode(fields));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update supplier: ${response.body}');
    }
  }

  /// Delete a supplier.
  static Future<void> deleteSupplier(String supplierId) async {
    final uri = Uri.parse('$_baseUrl/suppliers?id=eq.$supplierId');
    final token = await _waitForAuthToken();
    final response = await http.delete(uri, headers: _buildHeaders(token));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete supplier: ${response.body}');
    }
  }

  // ── Logistics Tasks ─────────────────────────────────────────────────────────

  /// Fetch all tasks.
  ///
  /// Strategy (cache-first, same as getSuppliers):
  ///   • Filtered views (non-"all") always bypass cache and hit network.
  ///   • For the "all" view:
  ///       – Fresh cache           → return immediately.
  ///       – Stale cache available → return stale data NOW (cache-first) so
  ///         the UI is never empty; background-refresh handles the update.
  ///       – No cache              → hit network.
  ///       – forceRefresh=true     → always hit network.
  static Future<List<LogisticsTask>> getAllTasksDetail({String? status, bool forceRefresh = false}) async {
    final isFiltered = status != null && status != 'all';

    // Cache logic only applies to the unfiltered "all" view.
    if (!isFiltered) {
      // 1. Fresh in-memory cache.
      if (!forceRefresh && hasTasksCache && !isTasksStale) {
        return _cachedTasks!;
      }

      // 2. Hydrate from disk if needed.
      if (!hasTasksCache) {
        await _loadTasksFromPrefs();
      }

      // 3. Cache-first: return stale data immediately (see getSuppliers comment).
      if (!forceRefresh && hasTasksCache) {
        return _cachedTasks!;
      }
    }

    // 4. Filtered view, no cache, or forceRefresh=true → fetch from network.
    String query = 'order=created_at.desc';
    if (isFiltered) {
      query += '&status=eq.$status';
    }
    final token = await _waitForAuthToken();
    final uri = Uri.parse('$_baseUrl/logistics_tasks_detail?$query');
    final response = await http.get(uri, headers: _buildHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks detail: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    final tasks = data
        .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
        .toList();

    // Only cache the full unfiltered list.
    if (!isFiltered) {
      _cachedTasks = tasks;
      _lastFetchTasks = DateTime.now();
      _saveTasksToPrefs();
    }

    return tasks;
  }

  /// Fetch a specific task by ID from the detail view.
  static Future<LogisticsTask> getTaskDetail(String taskId) async {
    final token = await _waitForAuthToken();
    final uri = Uri.parse('$_baseUrl/logistics_tasks_detail?id=eq.$taskId&limit=1');
    final headers = {
      ..._buildHeaders(token),
      'Accept': 'application/vnd.pgrst.object+json',
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load task: ${response.body}');
    }

    return LogisticsTask.fromJson(jsonDecode(response.body));
  }

  /// Fetch tasks for a specific supplier.
  static Future<List<LogisticsTask>> getTasksForSupplier(
      String supplierId, {String? status}) async {
    String query = 'supplier_id=eq.$supplierId&order=scheduled_date.desc';
    if (status != null && status != 'all') {
      query += '&status=eq.$status';
    }
    final token = await _waitForAuthToken();
    final uri = Uri.parse('$_baseUrl/logistics_tasks?$query');
    final response = await http.get(uri, headers: _buildHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new logistics task.
  static Future<LogisticsTask> createTask({
    required String supplierId,
    required String title,
    String? description,
    required String status,
    String? scheduledDate,
    String? notes,
  }) async {
    final uri = Uri.parse('$_baseUrl/logistics_tasks');
    final body = jsonEncode({
      'user_id': userId,
      'supplier_id': supplierId,
      'title': title,
      'description': description ?? '',
      'status': status,
      'scheduled_date': scheduledDate,
      'notes': notes ?? '',
    });

    final token = await _waitForAuthToken();
    final response =
        await http.post(uri, headers: _buildHeadersWithReturn(token), body: body);

    if (response.statusCode != 201) {
      throw Exception('Failed to create task: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return LogisticsTask.fromJson(data.first as Map<String, dynamic>);
  }

  /// Update a logistics task.
  static Future<void> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  ) async {
    final uri = Uri.parse('$_baseUrl/logistics_tasks?id=eq.$taskId');
    final token = await _waitForAuthToken();
    final response =
        await http.patch(uri, headers: _buildHeaders(token), body: jsonEncode(fields));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  /// Delete a logistics task.
  static Future<void> deleteTask(String taskId) async {
    final uri = Uri.parse('$_baseUrl/logistics_tasks?id=eq.$taskId');
    final token = await _waitForAuthToken();
    final response = await http.delete(uri, headers: _buildHeaders(token));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }

  // ── Task Items (Inventory Integration) ──────────────────────────────────────

  /// Load all active inventory items for the picker.
  static Future<List<Map<String, dynamic>>> getAvailableItems(
      {String? search}) async {
    // We use the supabase client for complex queries to simplify joins
    var query = supabase
        .from('items')
        .select(
            'id, name, sku, current_stock, purchase_price, sales_price, expiry_date, categories(name), units(name, abbreviation)')
        .eq('is_active', true);

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final data = await query.order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Returns item_ids already on a task.
  static Future<Set<String>> getAssignedItemIds(String taskId) async {
    final data = await supabase
        .from('logistics_task_items')
        .select('item_id')
        .eq('task_id', taskId);

    return {for (final row in data) row['item_id'] as String};
  }

  /// Sync items for a logistics task (Add new, remove deselected) with quantities.
  static Future<void> syncTaskItems(
      String taskId, List<Map<String, dynamic>> items) async {
    // items should be a list of maps: {'id': String, 'quantity': double}
    
    // 1. Get current items
    final currentIds = await getAssignedItemIds(taskId);
    final newItemIds = items.map((i) => i['id'] as String).toSet();

    // 2. Determine what to add and what to remove
    final toAdd = items.where((i) => !currentIds.contains(i['id'])).toList();
    final toRemove = currentIds.where((id) => !newItemIds.contains(id)).toList();

    // 3. Perform operations
    if (toRemove.isNotEmpty) {
      await supabase
          .from('logistics_task_items')
          .delete()
          .eq('task_id', taskId)
          .inFilter('item_id', toRemove);
    }

    if (toAdd.isNotEmpty) {
      final rows = toAdd.map((i) => {
        'task_id': taskId,
        'item_id': i['id'],
        'quantity': i['quantity'] ?? 0.0,
      }).toList();
      await supabase.from('logistics_task_items').insert(rows);
    }
  }

  /// Add items to a logistics task with quantities.
  static Future<void> addTaskItems(
      String taskId, List<Map<String, dynamic>> items) async {
    await syncTaskItems(taskId, items);
  }

  /// Adjust stock for multiple items at once.
  static Future<void> adjustStockBulk({
    required List<Map<String, dynamic>> items,
    required String movementType,
    String? reference,
    String? notes,
  }) async {
    for (final item in items) {
      await supabase.rpc('adjust_stock', params: {
        'p_item_id': item['id'],
        'p_movement_type': movementType,
        'p_quantity': item['quantity'],
        'p_notes': notes,
        'p_reference': reference,
      });
    }
  }

  /// Remove an item from a logistics task.
  static Future<void> removeTaskItem(String taskId, String itemId) async {
    await supabase
        .from('logistics_task_items')
        .delete()
        .eq('task_id', taskId)
        .eq('item_id', itemId);
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<void> _loadSuppliersFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kSuppliers);
      final millis = prefs.getInt(_kLastFetchSuppliers);
      if (json != null) {
        _cachedSuppliers = (jsonDecode(json) as List)
            .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (millis != null) {
        _lastFetchSuppliers = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {}
  }

  static Future<void> _saveSuppliersToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedSuppliers != null) {
        prefs.setString(_kSuppliers,
            jsonEncode(_cachedSuppliers!.map((e) => e.toJson()).toList()));
      }
      if (_lastFetchSuppliers != null) {
        prefs.setInt(_kLastFetchSuppliers,
            _lastFetchSuppliers!.millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  static Future<void> _loadTasksFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kTasks);
      final millis = prefs.getInt(_kLastFetchTasks);
      if (json != null) {
        _cachedTasks = (jsonDecode(json) as List)
            .map((e) => LogisticsTask.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (millis != null) {
        _lastFetchTasks = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {}
  }

  static Future<void> _saveTasksToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedTasks != null) {
        prefs.setString(
            _kTasks, jsonEncode(_cachedTasks!.map((e) => e.toJson()).toList()));
      }
      if (_lastFetchTasks != null) {
        prefs.setInt(
            _kLastFetchTasks, _lastFetchTasks!.millisecondsSinceEpoch);
      }
    } catch (_) {}
  }
}
