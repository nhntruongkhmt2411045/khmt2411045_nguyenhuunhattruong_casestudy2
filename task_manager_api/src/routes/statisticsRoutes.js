const router = require('express').Router();
const { protect } = require('../middleware/authMiddleware');
const c = require('../controllers/statisticsController');
router.use(protect);
router.get('/tasks', c.taskStatistics);
router.get('/assignments', c.assignmentStatistics);
router.get('/deadlines', c.deadlineStatistics);
module.exports = router;
