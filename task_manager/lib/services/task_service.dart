
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import 'auth_service.dart';

class TaskService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }

  // Headers có JWT
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập hoặc phiên đăng nhập đã hết hạn');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Xử lý phản hồi API
  static dynamic _decodeResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? body['message'] ?? body['error']
          : null;

      throw Exception(message ?? 'Lỗi API: ${response.statusCode}');
    }

    return body;
  }

  // 1. Lấy danh sách công việc
  static Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? q,
  }) async {
    final query = <String, String>{};

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    if (priority != null && priority.isNotEmpty) {
      query['priority'] = priority;
    }

    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }

    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Dữ liệu danh sách công việc không hợp lệ');
    }

    return data
        .map((item) => Task.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();
  }

  // 2. Lấy chi tiết công việc
  static Future<Task> getTaskById(String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    final taskData = data is Map && data['task'] != null
        ? data['task']
        : data;

    return Task.fromJson(
      Map<String, dynamic>.from(taskData),
    );
  }

  // 3. Tạo công việc
  static Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers(),
      body: jsonEncode(task.toJson()),
    );

    final data = _decodeResponse(response);

    final taskData = data is Map && data['task'] != null
        ? data['task']
        : data;

    return Task.fromJson(
      Map<String, dynamic>.from(taskData),
    );
  }

  // 4. Cập nhật công việc
  static Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: await _headers(),
      body: jsonEncode(task.toJson()),
    );

    final data = _decodeResponse(response);

    final taskData = data is Map && data['task'] != null
        ? data['task']
        : data;

    return Task.fromJson(
      Map<String, dynamic>.from(taskData),
    );
  }

  // 5. Xóa công việc
  static Future<void> deleteTask(String taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await _headers(),
    );

    _decodeResponse(response);
  }

  // 6. Tìm kiếm người dùng
  static Future<List<Map<String, dynamic>>> searchUsers(
      String keyword,
      ) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: {'q': keyword},
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    if (data is Map && data['users'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['users'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );
    }

    return [];
  }

  // 7. Chia sẻ công việc
  static Future<void> shareTask(
      String taskId,
      String userId, {
        String permission = 'view',
      }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/share'),
      headers: await _headers(),
      body: jsonEncode({
        'userId': userId,
        'permission': permission,
      }),
    );

    _decodeResponse(response);
  }

  // 8. Lấy danh sách người được chia sẻ
  static Future<List<TaskShare>> getTaskShares(
      String taskId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/shares'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    final shares = data is List
        ? data
        : data is Map
        ? data['shares'] ?? data['sharedWith'] ?? []
        : [];

    return (shares as List)
        .map((item) => TaskShare.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();
  }

  // 9. Thay đổi quyền chia sẻ
  static Future<void> updateTaskShare(
      String taskId,
      String userId,
      String permission,
      ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/share/$userId'),
      headers: await _headers(),
      body: jsonEncode({
        'permission': permission,
      }),
    );

    _decodeResponse(response);
  }

  // 10. Thu hồi quyền chia sẻ
  static Future<void> removeTaskShare(
      String taskId,
      String userId,
      ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/share/$userId'),
      headers: await _headers(),
    );

    _decodeResponse(response);
  }
}
