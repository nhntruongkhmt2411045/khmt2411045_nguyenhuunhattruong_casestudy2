
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const taskController = require('../controllers/taskController');

// Tất cả API task đều cần đăng nhập
router.use(authMiddleware);

// Lấy danh sách
router.get('/', taskController.getTasks);

// Tạo công việc
router.post('/', taskController.createTask);

// Xem chi tiết
router.get('/:id', taskController.getTaskById);

// Cập nhật
router.put('/:id', taskController.updateTask);

// Xóa
router.delete('/:id', taskController.deleteTask);

module.exports = router;
