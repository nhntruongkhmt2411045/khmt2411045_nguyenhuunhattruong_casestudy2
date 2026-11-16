const router = require('express').Router();
const { protect } = require('../middleware/authMiddleware');
const c = require('../controllers/notificationController');
router.use(protect);
router.get('/', c.getNotifications);
router.get('/unread-count', c.getUnreadCount);
router.patch('/read-all', c.markAllRead);
router.patch('/:id/read', c.markRead);
module.exports = router;
