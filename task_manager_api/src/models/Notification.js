const mongoose = require('mongoose');
const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', default: null },
  type: { type: String, enum: ['assigned', 'shared', 'task_updated', 'status_changed', 'completed', 'deadline'], default: 'task_updated' },
  title: { type: String, required: true },
  message: { type: String, default: '' },
  isRead: { type: Boolean, default: false, index: true }
}, { timestamps: true });
module.exports = mongoose.model('Notification', notificationSchema);
