
const express = require('express');
const router = express.Router();

const {
    register,
    login,
    getMe,
    updateProfile,
    changePassword
} = require('../controllers/authController');

const { protect } = require('../middleware/authMiddleware');

// Đăng ký và đăng nhập
router.post('/register', register);
router.post('/login', login);

// Các chức năng yêu cầu đăng nhập
router.get('/me', protect, getMe);
router.put('/me', protect, updateProfile);
router.put('/change-password', protect, changePassword);

module.exports = router;
