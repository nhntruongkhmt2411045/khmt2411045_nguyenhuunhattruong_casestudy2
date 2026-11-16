const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const EmailLog = require('../models/EmailLog');
const User = require('../models/User');

exports.activity = async (taskId, userId, action, details = {}) =>
  TaskActivity.create({ taskId, userId, action, details });

exports.notify = async (userIds, taskId, type, title, message) => {
  const ids = [...new Set((userIds || []).map(String))].filter(Boolean);
  if (!ids.length) return;
  await Notification.insertMany(ids.map(userId => ({ userId, taskId, type, title, message })));
};

// Email logs are always recorded. SMTP delivery can be enabled later via environment config.
exports.logEmailIntent = async (taskId, recipientUser, eventType, subject) => {
  const user = typeof recipientUser === 'string' ? await User.findById(recipientUser) : recipientUser;
  if (!user?.email) return null;
  return EmailLog.create({ taskId, recipientEmail: user.email, eventType, subject, status: 'pending' });
};
