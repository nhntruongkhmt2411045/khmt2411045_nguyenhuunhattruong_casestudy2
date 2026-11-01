
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Flutter Web chạy trên Edge
  static const String baseUrl =
      'http://localhost:3000/api/auth';

  // Nếu chạy Android Emulator thì đổi thành:
  // static const String baseUrl =
  //     'http://10.0.2.2:3000/api/auth';

  // Timeout request
  static const Duration timeout =
  Duration(seconds: 15);

  // Lấy token đã lưu
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // Lưu token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
  }

  // Xóa token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
  }

  // Header cho API cần đăng nhập
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token',
    };
  }

  // Đăng ký
  Future<void> register(
      String fullName,
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        }),
      )
          .timeout(timeout);

      final data = _decodeResponse(response);

      if (response.statusCode == 201) {
        final token = data['token'];

        if (token != null) {
          await saveToken(token.toString());
        }

        return;
      }

      throw Exception(
        data['message'] ?? 'Đăng ký thất bại',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Không thể kết nối API: $error');
    }
  }

  // Đăng nhập
  Future<bool> login(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      )
          .timeout(timeout);

      final data = _decodeResponse(response);

      if (response.statusCode == 200) {
        final token = data['token'];

        if (token == null) {
          throw Exception('API không trả về token');
        }

        await saveToken(token.toString());

        return true;
      }

      throw Exception(
        data['message'] ?? 'Đăng nhập thất bại',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Không thể kết nối API: $error');
    }
  }

  // Lấy thông tin Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/me'),
      headers: await getAuthHeaders(),
    )
        .timeout(timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy thông tin cá nhân',
    );
  }

  // Cập nhật Profile
  Future<bool> updateProfile(String name) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/me'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        'fullName': name.trim(),
      }),
    )
        .timeout(timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(
      data['message'] ?? 'Cập nhật thông tin thất bại',
    );
  }

  // Đổi mật khẩu
  Future<bool> changePassword(
      String oldPass,
      String newPass,
      ) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/change-password'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        'currentPassword': oldPass,
        'newPassword': newPass,
      }),
    )
        .timeout(timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(
      data['message'] ?? 'Đổi mật khẩu thất bại',
    );
  }

  // Đăng xuất
  Future<void> logout() async {
    await removeToken();
  }

  // Xử lý JSON trả về từ API
  Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      throw Exception(
        'API trả về dữ liệu không hợp lệ: '
            '${response.statusCode}',
      );
    }
  }
}
