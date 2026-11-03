
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Tạo token
const generateToken = (userId) => {
    if (!process.env.JWT_SECRET) {
        throw new Error('Chưa cấu hình JWT_SECRET');
    }

    return jwt.sign(
        { userId: userId.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
    );
};

// Đăng ký
exports.register = async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        // Kiểm tra dữ liệu
        if (!fullName || !email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ họ tên, email và mật khẩu'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                message: 'Mật khẩu phải có ít nhất 6 ký tự'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        // Kiểm tra email đã tồn tại
        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                message: 'Email đã được đăng ký'
            });
        }

        // Mã hóa mật khẩu
        const passwordHash = await bcrypt.hash(password, 10);

        // Tạo user
        const user = await User.create({
            fullName: fullName.trim(),
            email: normalizedEmail,
            passwordHash
        });

        // Tạo token
        const token = generateToken(user._id);

        return res.status(201).json({
            message: 'Đăng ký thành công',
            token,
            user: {
                _id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl
            }
        });

    } catch (error) {
        console.error('Register error:', error);

        if (error.code === 11000) {
            return res.status(409).json({
                message: 'Email đã được đăng ký'
            });
        }

        return res.status(500).json({
            message: 'Lỗi đăng ký tài khoản',
            error: error.message
        });
    }
};

// Đăng nhập
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập email và mật khẩu'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác'
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác'
            });
        }

        const token = generateToken(user._id);

        return res.status(200).json({
            message: 'Đăng nhập thành công',
            token,
            user: {
                _id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl
            }
        });

    } catch (error) {
        console.error('Login error:', error);

        return res.status(500).json({
            message: 'Lỗi đăng nhập',
            error: error.message
        });
    }
};

// Lấy thông tin người dùng
exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.userId)
            .select('-passwordHash');

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy người dùng'
            });
        }

        return res.status(200).json(user);

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi lấy thông tin người dùng',
            error: error.message
        });
    }
};

// Cập nhật thông tin cá nhân
exports.updateProfile = async (req, res) => {
    try {
        const { fullName, avatarUrl } = req.body;

        if (!fullName || !fullName.trim()) {
            return res.status(400).json({
                message: 'Họ tên không được để trống'
            });
        }

        const updateData = {
            fullName: fullName.trim()
        };

        if (avatarUrl !== undefined) {
            updateData.avatarUrl = avatarUrl;
        }

        const user = await User.findByIdAndUpdate(
            req.userId,
            updateData,
            {
                new: true,
                runValidators: true
            }
        ).select('-passwordHash');

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy người dùng'
            });
        }

        return res.status(200).json({
            message: 'Cập nhật thành công',
            user
        });

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi cập nhật thông tin',
            error: error.message
        });
    }
};

// Đổi mật khẩu
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ mật khẩu'
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                message: 'Mật khẩu mới phải có ít nhất 6 ký tự'
            });
        }

        const user = await User.findById(req.userId);

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy người dùng'
            });
        }

        const isMatch = await bcrypt.compare(
            currentPassword,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Mật khẩu hiện tại không đúng'
            });
        }

        user.passwordHash = await bcrypt.hash(newPassword, 10);

        await user.save();

        return res.status(200).json({
            message: 'Đổi mật khẩu thành công'
        });

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi đổi mật khẩu',
            error: error.message
        });
    }
};
