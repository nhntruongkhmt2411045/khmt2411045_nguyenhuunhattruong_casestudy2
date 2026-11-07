
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// ==================== ĐĂNG KÝ ====================
exports.register = async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        // Kiểm tra dữ liệu đầu vào
        if (!fullName || !email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ họ tên, email và mật khẩu'
            });
        }

        if (password.length < 8) {
            return res.status(400).json({
                message: 'Mật khẩu phải có ít nhất 8 ký tự'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        // Kiểm tra email đã tồn tại
        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(400).json({
                message: 'Email đã tồn tại'
            });
        }

        // Mã hóa mật khẩu
        const passwordHash = await bcrypt.hash(password, 10);

        // Tạo tài khoản mới
        const newUser = new User({
            fullName: fullName.trim(),
            email: normalizedEmail,
            passwordHash
        });

        await newUser.save();

        return res.status(201).json({
            message: 'Đăng ký tài khoản thành công'
        });

    } catch (err) {
        if (err.code === 11000) {
            return res.status(400).json({
                message: 'Email đã tồn tại'
            });
        }

        console.error('Lỗi đăng ký:', err);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi đăng ký tài khoản'
        });
    }
};


// ==================== ĐĂNG NHẬP ====================
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Kiểm tra dữ liệu đầu vào
        if (!email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập email và mật khẩu'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        // Tìm tài khoản
        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(400).json({
                message: 'Tài khoản không tồn tại'
            });
        }

        // Kiểm tra mật khẩu
        const isMatch = await bcrypt.compare(
            password,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Mật khẩu không chính xác'
            });
        }

        // Kiểm tra JWT_SECRET
        if (!process.env.JWT_SECRET) {
            throw new Error('Chưa cấu hình JWT_SECRET trong file .env');
        }

        // Tạo JWT token
        const token = jwt.sign(
            { userId: user._id.toString() },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        return res.status(200).json({
            message: 'Đăng nhập thành công',
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email
            }
        });

    } catch (err) {
        console.error('Lỗi đăng nhập:', err);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi đăng nhập'
        });
    }
};

// ==================== LẤY THÔNG TIN CÁ NHÂN ====================
exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.userId)
            .select('-passwordHash');

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy tài khoản'
            });
        }

        return res.status(200).json({
            user
        });

    } catch (err) {
        console.error('Lỗi lấy thông tin:', err);

        return res.status(500).json({
            message: 'Lỗi máy chủ'
        });
    }
};


// ==================== CẬP NHẬT HỒ SƠ ====================
exports.updateProfile = async (req, res) => {
    try {
        const { fullName, avatarUrl } = req.body;

        const updateData = {};

        if (fullName !== undefined) {
            if (!fullName.trim()) {
                return res.status(400).json({
                    message: 'Họ tên không được để trống'
                });
            }

            updateData.fullName = fullName.trim();
        }

        if (avatarUrl !== undefined) {
            updateData.avatarUrl = avatarUrl;
        }

        const user = await User.findByIdAndUpdate(
            req.userId,
            { $set: updateData },
            {
                new: true,
                runValidators: true
            }
        ).select('-passwordHash');

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy tài khoản'
            });
        }

        return res.status(200).json({
            message: 'Cập nhật hồ sơ thành công',
            user
        });

    } catch (err) {
        console.error('Lỗi cập nhật hồ sơ:', err);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi cập nhật hồ sơ'
        });
    }
};


// ==================== ĐỔI MẬT KHẨU ====================
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ mật khẩu hiện tại và mật khẩu mới'
            });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({
                message: 'Mật khẩu mới phải có ít nhất 8 ký tự'
            });
        }

        const user = await User.findById(req.userId);

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy tài khoản'
            });
        }

        const isMatch = await bcrypt.compare(
            currentPassword,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Mật khẩu hiện tại không chính xác'
            });
        }

        user.passwordHash = await bcrypt.hash(newPassword, 10);

        await user.save();

        return res.status(200).json({
            message: 'Đổi mật khẩu thành công'
        });

    } catch (err) {
        console.error('Lỗi đổi mật khẩu:', err);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi đổi mật khẩu'
        });
    }
};
