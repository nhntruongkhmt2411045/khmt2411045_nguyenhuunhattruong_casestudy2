
import 'package:flutter/material.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String _fullName = '';
  String _email = '';
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF5F3FA);
  static const Color orangeColor = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // LAY THONG TIN TAI KHOAN
  Future<void> _loadProfile() async {
    try {
      final response = await _authService.getProfile();

      if (!mounted) return;

      if (response != null) {
        Map<String, dynamic> userData = response;

        if (response['user'] is Map) {
          userData = Map<String, dynamic>.from(response['user']);
        } else if (response['data'] is Map) {
          userData = Map<String, dynamic>.from(response['data']);
        }

        setState(() {
          _fullName = userData['fullName']?.toString() ?? '';
          _email = userData['email']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải thông tin tài khoản'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // CHINH SUA THONG TIN
  void _showEditDialog() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập họ và tên'),
                    ),
                  );
                  return;
                }

                final success =
                await _authService.updateProfile(newName);

                if (!mounted) return;

                Navigator.pop(dialogContext);

                if (success) {
                  setState(() {
                    _fullName = newName;
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Cập nhật thông tin thành công'
                          : 'Cập nhật thông tin thất bại',
                    ),
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // DOI MAT KHAU
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final oldPassword = oldPasswordController.text;
                final newPassword = newPasswordController.text;

                if (oldPassword.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ mật khẩu'),
                    ),
                  );
                  return;
                }

                if (newPassword.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mật khẩu mới phải có ít nhất 8 ký tự',
                      ),
                    ),
                  );
                  return;
                }

                final success = await _authService.changePassword(
                  oldPassword,
                  newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đổi mật khẩu thành công'
                          : 'Đổi mật khẩu thất bại. Vui lòng kiểm tra mật khẩu cũ.',
                    ),
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // DANG XUAT
  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // THE THONG TIN
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 27,
            color: Colors.black54,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Chưa có thông tin' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 25,
        ),
        child: Column(
          children: [
            const SizedBox(height: 25),

            // AVATAR
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 85,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            // TEN TAI KHOAN
            Text(
              _fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 42),

            // THONG TIN HO VA TEN
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Họ và tên',
              value: _fullName,
            ),

            const SizedBox(height: 14),

            // THONG TIN EMAIL
            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: _email,
            ),

            const SizedBox(height: 25),

            // NUT CHINH SUA
            SizedBox(
              width: double.infinity,
              height: 63,
              child: ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit),
                label: const Text(
                  'CHỈNH SỬA THÔNG TIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // NUT DOI MAT KHAU
            SizedBox(
              width: double.infinity,
              height: 63,
              child: ElevatedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset),
                label: const Text(
                  'ĐỔI MẬT KHẨU',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DANG XUAT
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              label: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
