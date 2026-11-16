const Task = require('../models/Task');
const TaskActivity = require('../models/TaskActivity');
exports.getTaskActivities = async (req, res) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, $or: [{ createdBy: req.userId }, { assigneeIds: req.userId }, { 'sharedWith.userId': req.userId }] }).select('_id');
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc hoặc không có quyền truy cập' });
    const items = await TaskActivity.find({ taskId: task._id }).populate('userId', 'fullName email').sort({ createdAt: -1 }).limit(100);
    res.json(items);
  } catch (e) { res.status(400).json({ message: e.message }); }
};
