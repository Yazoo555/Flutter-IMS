// logistics_service.dart
// Service layer for all logistics-related Supabase API calls.
// Follows the same direct supabase client pattern used in the rest of the app.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/shipment.dart';

class LogisticsService {
  // ── Suppliers ────────────────────────────────────────────────────────────

  static Future<List<Supplier>> getSuppliers() async {
    final data = await supabase
        .from('suppliers')
        .select('*')
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List)
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getSupplierDropdown() async {
    final data = await supabase
        .from('suppliers')
        .select('id,name')
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> createSupplier(Map<String, dynamic> payload) async {
    await supabase.from('suppliers').insert(payload);
  }

  static Future<void> updateSupplier(
      String id, Map<String, dynamic> payload) async {
    payload['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('suppliers').update(payload).eq('id', id);
  }

  static Future<void> deleteSupplier(String id) async {
    await supabase.from('suppliers').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Purchase Orders ──────────────────────────────────────────────────────

  static Future<List<PurchaseOrder>> getPurchaseOrders(
      {String? status}) async {
    var query = supabase
        .from('purchase_orders')
        .select('*,suppliers(name,phone)');
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<PurchaseOrder> getPurchaseOrder(String id) async {
    final data = await supabase
        .from('purchase_orders')
        .select(
            '*,suppliers(name,phone,contact_name),purchase_order_items(*,items(name,sku,current_stock,units(abbreviation)))')
        .eq('id', id)
        .single();
    return PurchaseOrder.fromJson(data);
  }

  static Future<void> createPurchaseOrder(
      Map<String, dynamic> payload) async {
    await supabase.from('purchase_orders').insert(payload);
  }

  static Future<void> updatePOStatus(String id, String status) async {
    await supabase.from('purchase_orders').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── PO Items ─────────────────────────────────────────────────────────────

  static Future<void> addPOItem(Map<String, dynamic> payload) async {
    await supabase.from('purchase_order_items').insert(payload);
  }

  static Future<void> updatePOItem(
      String id, Map<String, dynamic> payload) async {
    await supabase
        .from('purchase_order_items')
        .update(payload)
        .eq('id', id);
  }

  static Future<void> deletePOItem(String id) async {
    await supabase.from('purchase_order_items').delete().eq('id', id);
  }

  // ── Items dropdown ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getItemsDropdown() async {
    final data = await supabase
        .from('items')
        .select('id,name,sku,purchase_price')
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Shipments ────────────────────────────────────────────────────────────

  static Future<List<Shipment>> getShipments() async {
    final data = await supabase
        .from('shipments')
        .select(
            '*,purchase_orders(po_number,expected_date,suppliers(name,phone))')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Shipment> getShipment(String id) async {
    final data = await supabase
        .from('shipments')
        .select(
            '*,purchase_orders(po_number,suppliers(name,contact_name,phone))')
        .eq('id', id)
        .single();
    return Shipment.fromJson(data);
  }

  static Future<void> createShipment(Map<String, dynamic> payload) async {
    await supabase.from('shipments').insert(payload);
  }

  static Future<void> updateShipmentStatus(
      String id, Map<String, dynamic> payload) async {
    payload['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('shipments').update(payload).eq('id', id);
  }

  // ── Confirmed POs for shipment dropdown ──────────────────────────────────

  static Future<List<PurchaseOrder>> getConfirmedPOs() async {
    final data = await supabase
        .from('purchase_orders')
        .select('*,suppliers(name,phone)')
        .inFilter('status', ['confirmed', 'partially_received'])
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Receive Goods RPC ────────────────────────────────────────────────────
  // This RPC requires the extra `content-profile: public` header,
  // which the supabase client doesn't support directly, so we use raw HTTP.

  static Future<void> receiveGoods({
    required String purchaseOrderId,
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final url = Uri.parse('$supabaseUrl/rest/v1/rpc/receive_purchase_order');
    final response = await http.post(
      url,
      headers: {
        'apikey': supabaseAnonKey,
        'authorization': 'Bearer ${session.accessToken}',
        'content-type': 'application/json',
        'content-profile': 'public',
      },
      body: jsonEncode({
        'p_purchase_order_id': purchaseOrderId,
        'p_user_id': userId,
        'p_items': items,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception(
          body['message'] ?? body['error'] ?? 'Receive goods failed');
    }
  }
}
