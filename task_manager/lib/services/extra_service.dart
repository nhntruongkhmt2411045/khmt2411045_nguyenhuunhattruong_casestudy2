import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ExtraService {
  static String get baseUrl => kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) throw Exception('Phiên đăng nhập đã hết hạn');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
  static dynamic _decode(http.Response r) {
    final data = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(data is Map ? data['message'] ?? 'Lỗi máy chủ' : 'Lỗi máy chủ');
    }
    return data;
  }  static Future<List<Map<String, dynamic>>> taskActivities(
      String taskId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/activities'),
      headers: await _headers(),
    );

    final data = _decode(response);

    return List<Map<String, dynamic>>.from(
      (data as List).map(
            (item) => Map<String, dynamic>.from(item),
      ),
    );
  }
  static Future<Map<String, dynamic>> taskStats() async => Map<String, dynamic>.from(_decode(await http.get(Uri.parse('$baseUrl/statistics/tasks'), headers: await _headers())));
  static Future<Map<String, dynamic>> assignmentStats() async => Map<String, dynamic>.from(_decode(await http.get(Uri.parse('$baseUrl/statistics/assignments'), headers: await _headers())));
  static Future<Map<String, dynamic>> deadlineStats() async => Map<String, dynamic>.from(_decode(await http.get(Uri.parse('$baseUrl/statistics/deadlines'), headers: await _headers())));
  // E2: Thống kê công việc được giao và đang phụ trách
  static Future<Map<String, dynamic>> assignmentDetailStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics/assignment-details'),
      headers: await _headers(),
    );

    return Map<String, dynamic>.from(_decode(response));
  }
  static Future<List<Map<String, dynamic>>> notifications() async => List<Map<String, dynamic>>.from((_decode(await http.get(Uri.parse('$baseUrl/notifications'), headers: await _headers())) as List).map((e) => Map<String, dynamic>.from(e)));
  static Future<int> unreadCount() async => ( _decode(await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: await _headers()))['count'] as num).toInt();
  static Future<void> markRead(String id) async => _decode(await http.patch(Uri.parse('$baseUrl/notifications/$id/read'), headers: await _headers()));
  static Future<void> markAllRead() async => _decode(await http.patch(Uri.parse('$baseUrl/notifications/read-all'), headers: await _headers()));
}
