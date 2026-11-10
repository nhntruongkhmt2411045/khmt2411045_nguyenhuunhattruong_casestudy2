const express = require('express');
const router = express.Router();

const {
    getTasks,
    getTaskById,
    createTask,
    updateTask,
    deleteTask,
    shareTask,
    getTaskShares,
    updateTaskShare,
    removeTaskShare
} = require('../controllers/taskController');

const { protect } = require('../middleware/authMiddleware');

router.use(protect);

// API chia sẻ công việc
router.post('/:id/share', shareTask);
router.get('/:id/shares', getTaskShares);
router.put('/:id/share/:userId', updateTaskShare);
router.delete('/:id/share/:userId', removeTaskShare);

// API quản lý công việc
router.get('/', getTasks);
router.get('/:id', getTaskById);
router.post('/', createTask);
router.put('/:id', updateTask);
router.delete('/:id', deleteTask);

module.exports = router;