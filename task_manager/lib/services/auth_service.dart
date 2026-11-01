import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> register(String fullName, String email, String password) async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:3000/api/auth/register'), // Dùng 10.0.2.2 nếu chạy Emulator Android, hoặc localhost nếu chạy Web
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fullName': fullName, // Chú ý tên key phải khớp 100% với req.body backend
      'email': email,
      'password': password,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 201) {
    // Ném lỗi chính xác do Backend trả về
    throw Exception(data['message'] ?? 'Đăng ký thất bại');
  }
}