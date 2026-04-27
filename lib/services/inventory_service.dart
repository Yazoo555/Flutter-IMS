// inventory_service.dart
// Caching service for the Inventory screen — mirrors the DashboardService pattern.
// Strategy:
//   1. Return in-memory cache immediately if fresh (< 5 min old).
//   2. Hydrate from SharedPreferences on first cold start, then return that.
//   3. Fetch from network when cache is missing or stale.
//   4. On pull-to-refresh: force network fetch, update both caches.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/inventory_models.dart';

class InventoryService {
  // ── Prefs Keys ─────────────────────────────────────────────────────────────
  static const _kItems = 'inv_cached_items';
  static const _kLastFetch = 'inv_last_fetch_time';

  // ── In-Memory Cache ────────────────────────────────────────────────────────
  static List<InventoryItem>? _cachedItems;
  static DateTime? _lastFetch;

  static bool get hasCache => _cachedItems != null;

  static bool get isCacheStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!).inMinutes > 5;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns items. Uses cache when fresh; fetches from network when stale.
  static Future<List<InventoryItem>> fetchItems(
      {bool forceRefresh = false}) async {
    // 1. Return valid in-memory cache immediately
    if (!forceRefresh && hasCache && !isCacheStale) {
      return _cachedItems!;
    }

    // 2. Try to hydrate from disk on first cold start
    if (!hasCache) {
      await _loadFromPrefs();
      if (!forceRefresh && hasCache && !isCacheStale) {
        return _cachedItems!;
      }
    }

    // 3. Fetch from network
    final data = await supabase
        .from('items')
        .select(
            'id, user_id, category_id, unit_id, name, sku, description, '
            'current_stock, opening_stock, low_stock_alert, purchase_price, '
            'sales_price, is_active, created_at, '
            'categories(id, name), units(id, name, abbreviation)')
        .order('name', ascending: true);

    final items = (data as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    _cachedItems = items;
    _lastFetch = DateTime.now();

    // Persist to disk asynchronously (don't await)
    _saveToPrefs();

    return items;
  }

  /// Force-invalidate in-memory cache (e.g., after add/edit/delete).
  static void invalidate() {
    _cachedItems = null;
    _lastFetch = null;
  }

  /// Clear both in-memory and persisted cache (e.g., on logout).
  static void clearCache() async {
    _cachedItems = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_kItems);
    prefs.remove(_kLastFetch);
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
    } catch (_) {
      // Silently ignore errors reading from prefs
    }
  }

  static Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedItems != null) {
        prefs.setString(_kItems, jsonEncode(_cachedItems!.map((e) => e.toJson()).toList()));
      }
      if (_lastFetch != null) {
        prefs.setInt(_kLastFetch, _lastFetch!.millisecondsSinceEpoch);
      }
    } catch (_) {
      // Silently ignore errors saving to prefs
    }
  }
}
