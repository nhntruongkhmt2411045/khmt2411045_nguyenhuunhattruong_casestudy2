
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();

  final nameController = TextEditingController();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String email = '';

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  // Lấy thông tin người dùng
  Future<void> loadProfile() async {
    try {
      final data = await authService.getProfile();

      if (!mounted) return;

      setState(() {
        nameController.text =
            data['fullName'] ?? '';

        email = data['email'] ?? '';

        isLoading = false;
      });

    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  // Cập nhật thông tin
  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ tên không được để trống'),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await authService.updateProfile(
        nameController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
        ),
      );

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Đổi mật khẩu
  Future<void> changePassword() async {
    if (oldPassController.text.isEmpty ||
        newPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mật khẩu'),
        ),
      );

      return;
    }

    if (newPassController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu mới phải có ít nhất 6 ký tự',
          ),
        ),
      );

      return;
    }

    try {
      await authService.changePassword(
        oldPassController.text,
        newPassController.text,
      );

      if (!mounted) return;

      oldPassController.clear();
      newPassController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
        ),
      );

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.of(context).popUntil(
          (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    oldPassController.dispose();
    newPassController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Center(
              child: CircleAvatar(
                radius: 45,
                child: Icon(
                  Icons.person,
                  size: 45,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Họ và tên'),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const Text('Email'),

            const SizedBox(height: 8),

            TextField(
              controller: TextEditingController(
                text: email,
              ),

              readOnly: true,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                isSaving ? null : updateProfile,

                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Cập nhật thông tin'),
              ),
            ),

            const Divider(height: 40),

            const Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: oldPassController,

              obscureText: true,

              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: newPassController,

              obscureText: true,

              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: changePassword,

                child: const Text('Đổi mật khẩu'),
              ),
            ),

            const Divider(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: logout,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),

                child: const Text('Đăng xuất'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
