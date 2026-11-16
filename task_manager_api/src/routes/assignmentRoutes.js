const router = require('express').Router({ mergeParams: true });
const { protect } = require('../middleware/authMiddleware');
const c = require('../controllers/assignmentController');
router.use(protect);
router.get('/', c.getAssignees);
router.post('/', c.setAssignees);
router.patch('/:userId', c.updateAssignee);
router.delete('/:userId', c.removeAssignee);
module.exports = router;
