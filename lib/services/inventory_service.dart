import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/inventory_models.dart';

class InventoryService {
  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kItems = 'inventory_cached_items';
  static const _kLastFetch = 'inventory_last_fetch_time';

  // ── Cache ──────────────────────────────────────────────────────────────────
  static List<InventoryItem>? _cachedItems;
  static DateTime? _lastFetch;

  static bool get hasCache => _cachedItems != null;

  static bool get isCacheStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!).inMinutes > 5;

  // ── Data Fetching ──────────────────────────────────────────────────────────

  static Future<List<InventoryItem>> fetchItems({bool forceRefresh = false}) async {
    // 1. If not forcing refresh, try to return valid in-memory cache
    if (!forceRefresh && hasCache && !isCacheStale) {
      return _cachedItems!;
    }

    // 2. Try to load from SharedPreferences if memory cache is empty
    if (!hasCache) {
      await _loadFromPrefs();
      if (!forceRefresh && hasCache && !isCacheStale) {
        return _cachedItems!;
      }
    }

    // 3. Fetch from API
    final data = await supabase
        .from('items')
        .select('id, user_id, category_id, unit_id, name, sku, description, current_stock, opening_stock, low_stock_alert, purchase_price, sales_price, is_active, created_at, categories(id, name), units(id, name, abbreviation)')
        .order('name', ascending: true);

    _cachedItems = (data as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastFetch = DateTime.now();

    // Save to disk asynchronously
    _saveToPrefs();

    return _cachedItems!;
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString(_kItems);
      final lastFetchMillis = prefs.getInt(_kLastFetch);

      if (itemsJson != null) {
        _cachedItems = (jsonDecode(itemsJson) as List)
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
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
      if (_cachedItems != null) {
        prefs.setString(_kItems, jsonEncode(_cachedItems));
      }
      if (_lastFetch != null) {
        prefs.setInt(_kLastFetch, _lastFetch!.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Ignore errors saving to prefs
    }
  }

  static void clearCache() async {
    _cachedItems = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_kItems);
    prefs.remove(_kLastFetch);
  }
}
