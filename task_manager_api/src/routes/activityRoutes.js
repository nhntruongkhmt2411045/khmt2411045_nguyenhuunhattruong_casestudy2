const router = require('express').Router({ mergeParams: true });
const { protect } = require('../middleware/authMiddleware');
const c = require('../controllers/activityController');
router.use(protect);
router.get('/', c.getTaskActivities);
module.exports = router;
