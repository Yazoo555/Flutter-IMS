// logistics_service.dart
// API service for Suppliers and Logistics Tasks using REST endpoints.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../models/logistics_models.dart';

class LogisticsService {
  static const String _baseUrl =
      'https://zinognrruckgcmrxgzro.supabase.co/rest/v1';

  static String? get _authToken => supabase.auth.currentSession?.accessToken != null 
      ? 'Bearer ${supabase.auth.currentSession!.accessToken}' 
      : null;

  static String get _apiKey => supabaseAnonKey;

  static String? get userId => supabase.auth.currentUser?.id;

  // ── Shared headers ──────────────────────────────────────────────────────────

  static Map<String, String> get _headers {
    final token = _authToken;
    return {
      if (token != null) 'Authorization': token,
      'apikey': _apiKey,
      'Content-Type': 'application/json',
    };
  }

  static Map<String, String> get _headersWithReturn => {
        ..._headers,
        'Prefer': 'return=representation',
      };

  // ── Suppliers ───────────────────────────────────────────────────────────────

  /// Fetch all suppliers ordered by name.
  static Future<List<Supplier>> getSuppliers() async {
    final uri = Uri.parse('$_baseUrl/suppliers?order=name.asc');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load suppliers: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
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

    final response =
        await http.post(uri, headers: _headersWithReturn, body: body);

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
    final response =
        await http.patch(uri, headers: _headers, body: jsonEncode(fields));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update supplier: ${response.body}');
    }
  }

  /// Delete a supplier.
  static Future<void> deleteSupplier(String supplierId) async {
    final uri = Uri.parse('$_baseUrl/suppliers?id=eq.$supplierId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete supplier: ${response.body}');
    }
  }

  // ── Logistics Tasks ─────────────────────────────────────────────────────────

  /// Fetch tasks for a specific supplier.
  static Future<List<LogisticsTask>> getTasksForSupplier(
      String supplierId) async {
    final uri = Uri.parse(
        '$_baseUrl/logistics_tasks?supplier_id=eq.$supplierId&order=scheduled_date.desc');
    final response = await http.get(uri, headers: _headers);

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

    final response =
        await http.post(uri, headers: _headersWithReturn, body: body);

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
    final response =
        await http.patch(uri, headers: _headers, body: jsonEncode(fields));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  /// Delete a logistics task.
  static Future<void> deleteTask(String taskId) async {
    final uri = Uri.parse('$_baseUrl/logistics_tasks?id=eq.$taskId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }
}
