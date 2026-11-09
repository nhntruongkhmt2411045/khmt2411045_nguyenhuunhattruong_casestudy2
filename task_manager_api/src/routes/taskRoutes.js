
const express = require('express');
const router = express.Router();

const {
    getTasks,
    getTaskById,
    createTask,
    updateTask,
    deleteTask
} = require('../controllers/taskController');

const { protect } = require('../middleware/authMiddleware');

// Tất cả API công việc đều yêu cầu đăng nhập
router.use(protect);

// Lấy danh sách công việc
router.get('/', getTasks);

// Xem chi tiết công việc
router.get('/:id', getTaskById);

// Tạo công việc
router.post('/', createTask);

// Cập nhật công việc
router.put('/:id', updateTask);

// Xóa công việc
router.delete('/:id', deleteTask);

module.exports = router;
