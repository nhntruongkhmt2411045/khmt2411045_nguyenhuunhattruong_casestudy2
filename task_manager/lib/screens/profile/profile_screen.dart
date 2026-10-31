import 'package:flutter/material.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await AuthService().getProfile();
    if (data != null) {
      setState(() {
        _nameController.text = data['fullName'] ?? '';
        _email = data['email'] ?? '';
        _isLoading = false;
      });
    } else {
      _handleLogout();
    }
  }

  void _handleUpdateProfile() async {
    final success = await AuthService().updateProfile(_nameController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Cập nhật thành công' : 'Cập nhật thất bại')),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu cũ')),
            TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final success = await AuthService().changePassword(oldPassCtrl.text, newPassCtrl.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Đổi mật khẩu thành công' : 'Mật khẩu cũ không đúng')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: TextEditingController(text: _email), enabled: false, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleUpdateProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Cập nhật thông tin'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _showChangePasswordDialog,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Đổi mật khẩu'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _handleLogout,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}