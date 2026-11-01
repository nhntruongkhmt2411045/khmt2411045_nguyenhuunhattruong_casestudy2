// Thêm thư viện jwt ở đầu file
const jwt = require('jsonwebtoken');

// ... (code hàm register ở trên)

exports.login = async (req, res) => {
    try {
        // Nhận email và mật khẩu từ client[cite: 1, 2]
        const { email, password } = req.body;

        // 1. Kiểm tra xem tài khoản có tồn tại không
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ message: 'Email hoặc mật khẩu không chính xác.' });
        }

        // 2. So sánh mật khẩu client gửi lên với mật khẩu đã băm trong database
        const isMatch = await bcrypt.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({ message: 'Email hoặc mật khẩu không chính xác.' });
        }

        // 3. Tạo token xác thực
        // Dùng biến môi trường cho JWT secret (không hardcode trong source)
        const payload = { userId: user._id };
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });

        // 4. Trả về token và thông tin người dùng (không trả về mật khẩu)
        res.status(200).json({
            message: 'Đăng nhập thành công.',
            token,
            user: {
                _id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl
            }
        });
    } catch (error) {
        // Xử lý lỗi nhất quán[cite: 1]
        res.status(500).json({ message: 'Đã xảy ra lỗi hệ thống.', error: error.message });
    }
};
// src/controllers/authController.js
// ... (giữ nguyên register và login ở trên)

// Lấy thông tin người dùng hiện tại
exports.getMe = async (req, res) => {
    try {
        // Tìm user dựa vào req.userId từ authMiddleware, loại bỏ trường passwordHash
        const user = await User.findById(req.userId).select('-passwordHash');
        if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi hệ thống.', error: error.message }); // Xử lý lỗi nhất quán
    }
};

// Xem và cập nhật thông tin cá nhân
exports.updateProfile = async (req, res) => {
    try {
        const { fullName, avatarUrl } = req.body;
        const updatedUser = await User.findByIdAndUpdate(
            req.userId,
            { fullName, avatarUrl },
            { new: true, runValidators: true }
        ).select('-passwordHash');

        res.status(200).json({ message: 'Cập nhật thành công.', user: updatedUser });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi hệ thống.', error: error.message });
    }
};

// Đổi mật khẩu[cite: 1, 2]
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const user = await User.findById(req.userId);

        // Kiểm tra mật khẩu cũ
        const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
        if (!isMatch) return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng.' });

        // Băm mật khẩu mới (Mật khẩu phải được băm bằng thư viện phù hợp)
        const salt = await bcrypt.genSalt(10);
        user.passwordHash = await bcrypt.hash(newPassword, salt);
        await user.save();

        res.status(200).json({ message: 'Đổi mật khẩu thành công.' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi hệ thống.', error: error.message });
    }
};