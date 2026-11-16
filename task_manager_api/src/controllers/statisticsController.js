const mongoose = require('mongoose');
const Task = require('../models/Task');
const scopeForUser = userId => { const id = new mongoose.Types.ObjectId(userId); return { $or: [{ createdBy: id }, { assigneeIds: id }, { 'sharedWith.userId': id }] }; };
exports.taskStatistics = async (req, res) => {
  try {
    const rows = await Task.aggregate([
      { $match: scopeForUser(req.userId) },
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);
    const result = { todo: 0, in_progress: 0, completed: 0, total: 0 };
    rows.forEach(r => { result[r._id] = r.count; result.total += r.count; });
    result.completionRate = result.total ? Math.round(result.completed * 100 / result.total) : 0;
    res.json(result);
  } catch (e) { res.status(500).json({ message: e.message }); }
};
exports.assignmentStatistics = async (req, res) => {
  try {
    const [created, assigned, primary] = await Promise.all([
      Task.countDocuments({ createdBy: req.userId }),
      Task.countDocuments({ assigneeIds: req.userId }),
      Task.countDocuments({ primaryAssigneeId: req.userId })
    ]);
    res.json({ created, assigned, primary });
  } catch (e) { res.status(500).json({ message: e.message }); }
};
exports.deadlineStatistics = async (req, res) => {
  try {
    const now = new Date(); const nextDay = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const base = { ...scopeForUser(req.userId), status: { $ne: 'completed' }, dueDate: { $ne: null } };
    const [overdue, dueSoon, overdueTasks, dueSoonTasks] = await Promise.all([
      Task.countDocuments({ ...base, dueDate: { $lt: now } }),
      Task.countDocuments({ ...base, dueDate: { $gte: now, $lte: nextDay } }),
      Task.find({ ...base, dueDate: { $lt: now } }).select('title dueDate status').sort({ dueDate: 1 }).limit(10),
      Task.find({ ...base, dueDate: { $gte: now, $lte: nextDay } }).select('title dueDate status').sort({ dueDate: 1 }).limit(10)
    ]);
    res.json({ overdue, dueSoon, overdueTasks, dueSoonTasks });
  } catch (e) { res.status(500).json({ message: e.message }); }
};
