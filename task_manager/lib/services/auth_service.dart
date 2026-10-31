import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api/auth';

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return null;
  }

  Future<bool> updateProfile(String fullName) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/updateProfile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'fullName': fullName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/changePassword'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}