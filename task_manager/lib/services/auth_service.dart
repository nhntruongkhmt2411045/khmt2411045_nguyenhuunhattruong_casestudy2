
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Dia chi Backend
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/auth';
    }
    return 'http://10.0.2.2:5000/api/auth';
  }

  // DANG NHAP
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] == null) {
          debugPrint('Backend khong tra ve token');
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      return false;
    }
  }

  // DANG KY
  Future<bool> register(
      String fullName,
      String email,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      debugPrint('REGISTER STATUS: ${response.statusCode}');
      debugPrint('REGISTER RESPONSE: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      return false;
    }
  }

  // LAY TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // DANG XUAT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // LAY THONG TIN CA NHAN
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('PROFILE STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
    }

    return null;
  }

  // CAP NHAT HO SO
  Future<bool> updateProfile(String fullName) async {
    final token = await getToken();

    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
        }),
      );

      debugPrint('UPDATE PROFILE STATUS: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('UPDATE PROFILE ERROR: $e');
      return false;
    }
  }

  // DOI MAT KHAU
  Future<bool> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    final token = await getToken();

    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint('CHANGE PASSWORD STATUS: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('CHANGE PASSWORD ERROR: $e');
      return false;
    }
  }
}
