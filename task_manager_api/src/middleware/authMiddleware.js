// src/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    try {
        const token = req.headers.authorization.split(" ")[1]; // Lấy token từ header "Bearer <token>"
        const decoded = jwt.verify(token, process.env.JWT_SECRET); // Dùng biến môi trường cho JWT secret
        req.userId = decoded.userId; // Lưu userId vào request để controller sử dụng
        next();
    } catch (error) {
        return res.status(401).json({ message: 'Không có quyền truy cập. Token không hợp lệ hoặc đã hết hạn.' });
    }
};