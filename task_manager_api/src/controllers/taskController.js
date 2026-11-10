
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
// Điều kiện xác định người dùng có liên quan đến công việc
const accessCondition = (userId) => ({
    $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { 'sharedWith.userId': userId }
    ]
});

// 1. Lấy danh sách công việc
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, q } = req.query;

        const conditions = [accessCondition(req.userId)];

        if (status) {
            conditions.push({ status });
        }

        if (priority) {
            conditions.push({ priority });
        }

        if (q) {
            conditions.push({
                title: { $regex: q, $options: 'i' }
            });
        }

        const tasks = await Task.find({
            $and: conditions
        })
            .populate('createdBy', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .populate('assigneeIds', 'fullName email')
            .sort({ createdAt: -1 });

        res.json(tasks);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 2. Tạo công việc mới
exports.createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            startDate,
            dueDate,
            priority,
            status,
            assigneeIds,
            primaryAssigneeId
        } = req.body;

        const newTask = new Task({
            title,
            description,
            startDate,
            dueDate,
            priority: priority || 'medium',
            status: status || 'todo',
            assigneeIds: assigneeIds || [],
            primaryAssigneeId: primaryAssigneeId || undefined,
            createdBy: req.userId
        });

        await newTask.save();

        res.status(201).json({
            message: 'Tạo công việc thành công',
            task: newTask
        });

    } catch (err) {
        res.status(400).json({ error: err.message });
    }
};

// 3. Xem chi tiết công việc
exports.getTaskById = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ'
            });
        }

        const task = await Task.findOne({
            _id: id,
            ...accessCondition(req.userId)
        })
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email');

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền truy cập'
            });
        }

        res.json(task);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 4. Cập nhật công việc
exports.updateTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ'
            });
        }

        // Các trường được phép cập nhật
        const allowedFields = [
            'title',
            'description',
            'startDate',
            'dueDate',
            'priority',
            'status',
            'assigneeIds',
            'primaryAssigneeId'
        ];

        const updateData = {};

        allowedFields.forEach(field => {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({
                message: 'Không có thông tin cần cập nhật'
            });
        }

        // Chủ sở hữu hoặc người được chia sẻ quyền edit
        const task = await Task.findOneAndUpdate(
            {
                _id: id,
                $or: [
                    { createdBy: req.userId },
                    {
                        sharedWith: {
                            $elemMatch: {
                                userId: req.userId,
                                permission: 'edit'
                            }
                        }
                    }
                ]
            },
            { $set: updateData },
            {
                new: true,
                runValidators: true
            }
        );

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền sửa'
            });
        }

        res.json({
            message: 'Cập nhật công việc thành công',
            task
        });

    } catch (err) {
        res.status(400).json({
            error: err.message
        });
    }
};

// 5. Xóa công việc
exports.deleteTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ'
            });
        }

        const task = await Task.findOneAndDelete({
            _id: id,
            createdBy: req.userId
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền xóa'
            });
        }

        res.json({
            message: 'Đã xóa công việc thành công'
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 6. Chia sẻ công việc
exports.shareTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId, permission = 'view' } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({
                message: 'ID công việc hoặc người dùng không hợp lệ'
            });
        }

        if (!['view', 'edit'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyền phải là view hoặc edit'
            });
        }

        const task = await Task.findOne({
            _id: id,
            createdBy: req.userId
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền chia sẻ'
            });
        }

        if (userId === req.userId.toString()) {
            return res.status(400).json({
                message: 'Không thể chia sẻ công việc cho chính mình'
            });
        }

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: 'Người dùng được chia sẻ không tồn tại'
            });
        }

        const existingShare = task.sharedWith.find(
            item => item.userId.toString() === userId
        );

        if (existingShare) {
            existingShare.permission = permission;
        } else {
            task.sharedWith.push({
                userId,
                permission
            });
        }

        await task.save();

        res.json({
            message: 'Chia sẻ công việc thành công',
            task
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 7. Xem danh sách người được chia sẻ
exports.getTaskShares = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ'
            });
        }

        const task = await Task.findOne({
            _id: id,
            createdBy: req.userId
        }).populate('sharedWith.userId', 'fullName email avatarUrl');

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền'
            });
        }

        res.json({
            message: 'Lấy danh sách chia sẻ thành công',
            sharedWith: task.sharedWith
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 8. Thay đổi quyền chia sẻ
exports.updateTaskShare = async (req, res) => {
    try {
        const { id, userId } = req.params;
        const { permission } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({
                message: 'ID không hợp lệ'
            });
        }

        if (!['view', 'edit'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyền phải là view hoặc edit'
            });
        }

        const task = await Task.findOneAndUpdate(
            {
                _id: id,
                createdBy: req.userId,
                'sharedWith.userId': userId
            },
            {
                $set: {
                    'sharedWith.$.permission': permission
                }
            },
            { new: true, runValidators: true }
        );

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc người được chia sẻ'
            });
        }

        res.json({
            message: 'Cập nhật quyền chia sẻ thành công',
            task
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 9. Thu hồi quyền chia sẻ
exports.removeTaskShare = async (req, res) => {
    try {
        const { id, userId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({
                message: 'ID không hợp lệ'
            });
        }

        const task = await Task.findOneAndUpdate(
            {
                _id: id,
                createdBy: req.userId
            },
            {
                $pull: {
                    sharedWith: { userId }
                }
            },
            { new: true }
        );

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền'
            });
        }

        res.json({
            message: 'Thu hồi quyền chia sẻ thành công',
            task
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
