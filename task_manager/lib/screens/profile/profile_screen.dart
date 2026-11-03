import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();

  final nameController = TextEditingController();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isChangingPassword = false;
  bool isLoggingOut = false;

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;

  String email = '';

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  // =========================
  // LẤY THÔNG TIN CÁ NHÂN
  // =========================
  Future<void> loadProfile() async {
    try {
      final data = await authService.getProfile();

      if (!mounted) return;

      // API có thể trả dữ liệu người dùng bên trong user
      final user = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : data;

      setState(() {
        nameController.text = user['fullName']?.toString() ?? '';
        email = user['email']?.toString() ?? '';
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

  // =========================
  // CẬP NHẬT THÔNG TIN
  // =========================
  Future<void> updateProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
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
      await authService.updateProfile(name);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
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

  // =========================
  // ĐỔI MẬT KHẨU
  // =========================
  Future<void> changePassword() async {
    final oldPassword = oldPassController.text;
    final newPassword = newPassController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mật khẩu'),
        ),
      );

      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu mới phải có ít nhất 6 ký tự',
          ),
        ),
      );

      return;
    }

    if (oldPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu mới phải khác mật khẩu hiện tại',
          ),
        ),
      );

      return;
    }

    setState(() {
      isChangingPassword = true;
    });

    try {
      await authService.changePassword(
        oldPassword,
        newPassword,
      );

      if (!mounted) return;

      oldPassController.clear();
      newPassController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isChangingPassword = false;
        });
      }
    }
  }

  // =========================
  // ĐĂNG XUẤT
  // =========================
  Future<void> logout() async {
    if (isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    // Người dùng chọn Hủy
    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      // Xóa token đã lưu
      await authService.logout();

      if (!mounted) return;

      // Xóa các màn hình trước đó và quay về Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thất bại: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  // =========================
  // GIẢI PHÓNG CONTROLLER
  // =========================
  @override
  void dispose() {
    nameController.dispose();
    oldPassController.dispose();
    newPassController.dispose();

    super.dispose();
  }

  // =========================
  // GIAO DIỆN
  // =========================
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
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // AVATAR
            const Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF2878E8),
                child: Icon(
                  Icons.person,
                  size: 45,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // HỌ TÊN
            const Text(
              'Họ và tên',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,

              decoration: const InputDecoration(
                hintText: 'Nhập họ và tên',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // EMAIL
            const Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              initialValue: email,
              readOnly: true,

              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // NÚT CẬP NHẬT
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: isSaving ? null : updateProfile,

                icon: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),

                label: Text(
                  isSaving
                      ? 'Đang cập nhật...'
                      : 'Cập nhật thông tin',
                ),
              ),
            ),

            const Divider(height: 40),

            // ĐỔI MẬT KHẨU
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // MẬT KHẨU CŨ
            TextField(
              controller: oldPassController,
              obscureText: obscureOldPassword,

              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),

                suffixIcon: IconButton(
                  icon: Icon(
                    obscureOldPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureOldPassword = !obscureOldPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // MẬT KHẨU MỚI
            TextField(
              controller: newPassController,
              obscureText: obscureNewPassword,

              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),

                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureNewPassword = !obscureNewPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // NÚT ĐỔI MẬT KHẨU
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed:
                isChangingPassword ? null : changePassword,

                icon: isChangingPassword
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.password),

                label: Text(
                  isChangingPassword
                      ? 'Đang đổi mật khẩu...'
                      : 'Đổi mật khẩu',
                ),
              ),
            ),

            const Divider(height: 40),

            // NÚT ĐĂNG XUẤT
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: isLoggingOut ? null : logout,

                icon: isLoggingOut
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.logout),

                label: Text(
                  isLoggingOut
                      ? 'Đang đăng xuất...'
                      : 'Đăng xuất',
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}