
const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Đăng ký
router.post('/register', authController.register);

// Đăng nhập
router.post('/login', authController.login);

// Lấy thông tin user hiện tại
router.get('/me', authMiddleware, authController.getMe);

// Cập nhật thông tin user
router.put('/me', authMiddleware, authController.updateProfile);

// Đổi mật khẩu
router.put(
    '/change-password',
    authMiddleware,
    authController.changePassword
);

module.exports = router;
