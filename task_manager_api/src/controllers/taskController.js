
const mongoose = require('mongoose');
const Task = require('../models/Task');

// Điều kiện xác định người dùng có liên quan đến công việc
const accessCondition = (userId) => ({
    $or: [
        { createdBy: userId },
        { assigneeIds: userId }
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

        // Chỉ cho phép cập nhật các trường hợp lệ
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

        const task = await Task.findOneAndUpdate(
            {
                _id: id,
                createdBy: req.userId
            },
            updateData,
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
        res.status(400).json({ error: err.message });
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
