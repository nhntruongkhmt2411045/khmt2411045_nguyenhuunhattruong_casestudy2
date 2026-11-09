
const express = require('express');
const router = express.Router();

const { protect } = require('../middleware/authMiddleware');

const {
    getTasks,
    createTask,
    getTaskById,
    updateTask,
    deleteTask
} = require('../controllers/taskController');

// Lấy danh sách công việc
router.get('/', protect, getTasks);

// Tạo công việc
router.post('/', protect, createTask);

// Xem chi tiết công việc
router.get('/:id', protect, getTaskById);

// Cập nhật công việc
router.put('/:id', protect, updateTask);

// Xóa công việc
router.delete('/:id', protect, deleteTask);

module.exports = router;
