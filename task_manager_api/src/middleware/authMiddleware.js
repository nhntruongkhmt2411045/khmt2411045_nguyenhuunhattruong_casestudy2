
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    try {
        // Lấy token từ Header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                message: 'Không có quyền truy cập, không tìm thấy token'
            });
        }

        const token = authHeader.split(' ')[1];

        // Kiểm tra JWT_SECRET
        if (!process.env.JWT_SECRET) {
            return res.status(500).json({
                message: 'Máy chủ chưa cấu hình JWT_SECRET'
            });
        }

        // Xác thực token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Lấy thông tin người dùng từ userId
        const user = await User.findById(decoded.userId)
            .select('-passwordHash');

        if (!user) {
            return res.status(401).json({
                message: 'Tài khoản không tồn tại'
            });
        }

        // Gắn thông tin người dùng vào request
        req.user = user;
        req.userId = user._id.toString();

        next();

    } catch (error) {
        return res.status(401).json({
            message: 'Không có quyền truy cập, token không hợp lệ'
        });
    }
};

module.exports = { protect };
