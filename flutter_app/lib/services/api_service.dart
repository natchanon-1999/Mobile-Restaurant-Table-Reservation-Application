// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const BASE_URL = "http://localhost/Mobile-Restaurant-Table-Reservation-Application-main/php_api";

  static String? _token;

  // ─── TOKEN ─────────────────────────
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    print("🔑 TOKEN LOADED: $_token");
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print("🔑 TOKEN SAVED: $_token");
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<void> _ensureToken() async {
    if (_token == null) await loadToken();
  }

  // ─── HEADERS ───────────────────────
  static Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    print("📋 HEADERS: $h");
    return h;
  }

  // ─── CORE ──────────────────────────
  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    print("📥 STATUS: ${res.statusCode}");
    print("📥 BODY: ${res.body}");
    if (res.body.isEmpty) throw Exception("Empty response from server");
    try {
      return jsonDecode(res.body);
    } catch (e) {
      throw Exception("Invalid JSON response: ${res.body}");
    }
  }

  static Future<Map<String, dynamic>> _get(String url) async {
    await _ensureToken();
    print("📤 GET: $BASE_URL/$url");
    final res = await http.get(Uri.parse("$BASE_URL/$url"), headers: _headers);
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _post(String url, Map body) async {
    await _ensureToken();
    print("📤 POST: $BASE_URL/$url");
    print("📤 BODY: ${jsonEncode(body)}");
    final res = await http.post(
      Uri.parse("$BASE_URL/$url"),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _put(String url, Map body) async {
    await _ensureToken();
    print("📤 PUT: $BASE_URL/$url");
    final res = await http.put(
      Uri.parse("$BASE_URL/$url"),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _delete(String url) async {
    await _ensureToken();
    print("📤 DELETE: $BASE_URL/$url");
    final res =
        await http.delete(Uri.parse("$BASE_URL/$url"), headers: _headers);
    return _handle(res);
  }

  // ─── AUTH ─────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) {
    return _post('auth.php?action=login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String phone, String password) {
    return _post('auth.php?action=register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  static Future<UserModel?> getProfile() async {
    try {
      final data = await _get('auth.php?action=profile');
      if (data['success'] == true) return UserModel.fromJson(data['user']);
    } catch (e) {
      print("GET PROFILE ERROR: $e");
    }
    return null;
  }

  // ─── TABLES ───────────────────────
  static Future<List<TableModel>> getTables({String? zone}) async {
    final q = zone != null ? '&zone=$zone' : '';
    final data = await _get('tables.php?action=list$q');
    if (data['success'] == true) {
      return (data['tables'] as List)
          .map((e) => TableModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createTable(Map body) {
    return _post('tables.php?action=create', body);
  }

  static Future<Map<String, dynamic>> updateTable(int id, Map body) {
    return _put('tables.php?action=update&id=$id', body);
  }

  static Future<Map<String, dynamic>> deleteTable(int id) {
    return _delete('tables.php?action=delete&id=$id');
  }

  static Future<Map<String, dynamic>> getAvailability({
    required String date,
    required int slotId,
    required int guests,
  }) {
    return _get(
        'tables.php?action=availability&date=$date&slot_id=$slotId&guests=$guests');
  }

  // ─── TIME SLOT ─────────────────────
  static Future<List<TimeSlot>> getTimeSlots() async {
    final data = await _get('slots.php?action=list');
    if (data['success'] == true) {
      return (data['slots'] as List)
          .map((e) => TimeSlot.fromJson(e))
          .toList();
    }
    return [];
  }

  // ─── RESERVATION ──────────────────
  static Future<Map<String, dynamic>> createReservation({
    required int tableId,
    required int slotId,
    required String date,
    required int guests,
    String specialRequest = '',
    String occasion = '',
  }) async {
    await loadToken();
    return _post('reservations.php?action=create', {
      'table_id': tableId,
      'slot_id': slotId,
      'date': date,
      'guests': guests,
      'special_request': specialRequest,
      'occasion': occasion,
    });
  }

  static Future<List<ReservationModel>> getMyReservations(
      {String? status}) async {
    final q = status != null ? '&status=$status' : '';
    final data = await _get('reservations.php?action=my&limit=100$q');
    if (data['success'] == true) {
      return (data['reservations'] as List)
          .map((e) => ReservationModel.fromJson(e))
          .toList();
    }
    return [];
  }

  // ✅ FIXED จุดเดียว (กัน null + crash)
  static Future<Set<int>> getBookedTableIds() async {
    try {
      final data = await _get('reservations.php?action=booked');

      if (data['success'] == true) {
        final ids = data['booked_table_ids'];

        if (ids == null) return <int>{};

        if (ids is List) {
          return ids
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toSet();
        }
      }
    } catch (e) {
      print("GET BOOKED TABLE IDS ERROR: $e");
    }

    return <int>{};
  }

  static Future<List<ReservationModel>> getAllReservations(
      {String? status}) async {
    final q = status != null ? '&status=$status' : '';
    final data = await _get('reservations.php?action=list$q');
    if (data['success'] == true) {
      return (data['reservations'] as List)
          .map((e) => ReservationModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<ReservationModel>> searchReservations(String q) async {
    final data = await _get(
        'reservations.php?action=search&q=${Uri.encodeComponent(q)}');
    if (data['success'] == true) {
      return (data['reservations'] as List)
          .map((e) => ReservationModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> cancelReservation(int id) {
    return _put('reservations.php?action=cancel&id=$id', {});
  }

  static Future<Map<String, dynamic>> updateReservationStatus(
      int id, String status) {
    return _put('reservations.php?action=status&id=$id', {'status': status});
  }

  // ─── DASHBOARD ────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() {
    return _get('dashboard.php?action=stats');
  }
}