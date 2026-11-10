
const express = require('express');
const router = express.Router();

const { searchUsers } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

// Tất cả API người dùng đều yêu cầu đăng nhập
router.use(protect);

// Tìm kiếm người dùng
router.get('/search', searchUsers);

module.exports = router;
