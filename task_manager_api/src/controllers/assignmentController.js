const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const { activity, notify, logEmailIntent } = require('../services/taskEvents');
const ownerTask = (id, userId) => Task.findOne({ _id: id, createdBy: userId });
exports.getAssignees = async (req, res) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, $or: [{ createdBy: req.userId }, { assigneeIds: req.userId }, { 'sharedWith.userId': req.userId }] }).populate('assigneeIds', 'fullName email').populate('primaryAssigneeId', 'fullName email');
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc hoặc không có quyền truy cập' });
    res.json({ assignees: task.assigneeIds, primaryAssignee: task.primaryAssigneeId });
  } catch (e) { res.status(400).json({ message: e.message }); }
};
exports.setAssignees = async (req, res) => {
  try {
    const { userIds = [], primaryAssigneeId = null } = req.body;
    if (!Array.isArray(userIds) || userIds.some(id => !mongoose.Types.ObjectId.isValid(id))) return res.status(400).json({ message: 'Danh sách người được giao không hợp lệ' });
    const ids = [...new Set(userIds.map(String))];
    if (primaryAssigneeId && !ids.includes(String(primaryAssigneeId))) return res.status(400).json({ message: 'Người phụ trách chính phải nằm trong danh sách được giao' });
    const task = await ownerTask(req.params.id, req.userId);
    if (!task) return res.status(404).json({ message: 'Chỉ người tạo công việc mới được giao việc' });
    const users = await User.find({ _id: { $in: ids } }).select('_id fullName email');
    if (users.length !== ids.length) return res.status(400).json({ message: 'Có người dùng không tồn tại' });
    task.assigneeIds = ids; task.primaryAssigneeId = primaryAssigneeId || undefined;
    await task.save();
    const notifyIds = ids.filter(id => id !== String(req.userId));
    await notify(notifyIds, task._id, 'assigned', 'Bạn được giao công việc', `Bạn được giao công việc: ${task.title}`);
    await activity(task._id, req.userId, 'assigned', { assigneeIds: ids, primaryAssigneeId });
    await Promise.all(users.filter(u => notifyIds.includes(String(u._id))).map(u => logEmailIntent(task._id, u, 'assigned', `Bạn được giao công việc: ${task.title}`)));
    await task.populate('assigneeIds', 'fullName email'); await task.populate('primaryAssigneeId', 'fullName email');
    res.json({ message: 'Giao công việc thành công', assignees: task.assigneeIds, primaryAssignee: task.primaryAssigneeId });
  } catch (e) { res.status(400).json({ message: e.message }); }
};
exports.removeAssignee = async (req, res) => {
  try {
    const task = await ownerTask(req.params.id, req.userId);
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc hoặc bạn không có quyền' });
    task.assigneeIds = task.assigneeIds.filter(x => String(x) !== req.params.userId);
    if (String(task.primaryAssigneeId || '') === req.params.userId) task.primaryAssigneeId = undefined;
    await task.save(); await activity(task._id, req.userId, 'unassigned', { userId: req.params.userId });
    res.json({ message: 'Đã hủy giao việc' });
  } catch (e) { res.status(400).json({ message: e.message }); }
};
exports.updateAssignee = async (req, res) => {
  try {
    const task = await ownerTask(req.params.id, req.userId);
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc hoặc bạn không có quyền' });
    if (!task.assigneeIds.some(x => String(x) === req.params.userId)) return res.status(404).json({ message: 'Người dùng không nằm trong danh sách được giao' });
    if (req.body.primary !== undefined) task.primaryAssigneeId = req.body.primary ? req.params.userId : (String(task.primaryAssigneeId || '') === req.params.userId ? undefined : task.primaryAssigneeId);
    await task.save(); await activity(task._id, req.userId, 'assignee_updated', { userId: req.params.userId, primary: req.body.primary });
    res.json({ message: 'Cập nhật người phụ trách thành công', primaryAssigneeId: task.primaryAssigneeId });
  } catch (e) { res.status(400).json({ message: e.message }); }
};
