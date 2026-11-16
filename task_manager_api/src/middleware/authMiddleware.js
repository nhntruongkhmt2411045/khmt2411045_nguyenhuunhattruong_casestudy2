
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');

const protect = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                message: 'Không tìm thấy token truy cập'
            });
        }

        const token = authHeader.split(' ')[1];

        if (!process.env.JWT_SECRET) {
            return res.status(500).json({
                message: 'Máy chủ chưa cấu hình JWT_SECRET'
            });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        if (!decoded.userId || !mongoose.Types.ObjectId.isValid(decoded.userId)) {
            return res.status(401).json({
                message: 'Token không chứa userId hợp lệ'
            });
        }

        const user = await User.findById(decoded.userId)
            .select('-passwordHash');

        if (!user) {
            return res.status(401).json({
                message: 'Tài khoản không tồn tại'
            });
        }

        req.user = user;
        req.userId = user._id.toString();

        next();

    } catch (error) {
        return res.status(401).json({
            message: 'Token không hợp lệ hoặc đã hết hạn'
        });
    }
};

module.exports = { protect };
