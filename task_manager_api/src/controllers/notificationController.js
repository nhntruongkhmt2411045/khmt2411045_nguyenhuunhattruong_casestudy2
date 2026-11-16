const Notification = require('../models/Notification');
exports.getNotifications = async (req, res) => {
  try {
    const items = await Notification.find({ userId: req.userId }).populate('taskId', 'title status').sort({ createdAt: -1 }).limit(100);
    res.json(items);
  } catch (e) { res.status(500).json({ message: e.message }); }
};
exports.getUnreadCount = async (req, res) => {
  try { res.json({ count: await Notification.countDocuments({ userId: req.userId, isRead: false }) }); }
  catch (e) { res.status(500).json({ message: e.message }); }
};
exports.markRead = async (req, res) => {
  try {
    const item = await Notification.findOneAndUpdate({ _id: req.params.id, userId: req.userId }, { isRead: true }, { new: true });
    if (!item) return res.status(404).json({ message: 'Không tìm thấy thông báo' });
    res.json(item);
  } catch (e) { res.status(400).json({ message: e.message }); }
};
exports.markAllRead = async (req, res) => {
  try {
    const result = await Notification.updateMany({ userId: req.userId, isRead: false }, { isRead: true });
    res.json({ message: 'Đã đánh dấu tất cả thông báo đã đọc', modifiedCount: result.modifiedCount });
  } catch (e) { res.status(500).json({ message: e.message }); }
};
