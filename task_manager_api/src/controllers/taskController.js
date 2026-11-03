
const Task = require('../models/Task');

// Lấy danh sách công việc
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, q } = req.query;

        const query = {
            $or: [
                { createdBy: req.userId },
                { assigneeIds: req.userId }
            ]
        };

        if (status) {
            query.status = status;
        }

        if (priority) {
            query.priority = priority;
        }

        if (q) {
            query.title = {
                $regex: q,
                $options: 'i'
            };
        }

        const tasks = await Task.find(query)
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .sort({ createdAt: -1 });

        return res.status(200).json(tasks);

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi lấy danh sách công việc',
            error: error.message
        });
    }
};

// Tạo công việc
exports.createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            startDate,
            dueDate,
            priority,
            status
        } = req.body;

        if (!title || !title.trim()) {
            return res.status(400).json({
                message: 'Tên công việc không được để trống'
            });
        }

        const newTask = await Task.create({
            title: title.trim(),
            description: description || '',
            startDate: startDate || null,
            dueDate: dueDate || null,
            priority: priority || 'medium',
            status: status || 'todo',
            createdBy: req.userId,
            assigneeIds: [req.userId],
            primaryAssigneeId: req.userId
        });

        return res.status(201).json(newTask);

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi tạo công việc',
            error: error.message
        });
    }
};

// Xem chi tiết công việc
exports.getTaskById = async (req, res) => {
    try {
        const task = await Task.findOne({
            _id: req.params.id,
            $or: [
                { createdBy: req.userId },
                { assigneeIds: req.userId }
            ]
        })
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email');

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc'
            });
        }

        return res.status(200).json(task);

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi lấy công việc',
            error: error.message
        });
    }
};

// Cập nhật công việc
exports.updateTask = async (req, res) => {
    try {
        const allowedFields = [
            'title',
            'description',
            'startDate',
            'dueDate',
            'priority',
            'status'
        ];

        const updateData = {};

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        }

        const task = await Task.findOneAndUpdate(
            {
                _id: req.params.id,
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

        return res.status(200).json(task);

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi cập nhật công việc',
            error: error.message
        });
    }
};

// Xóa công việc
exports.deleteTask = async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({
            _id: req.params.id,
            createdBy: req.userId
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc hoặc bạn không có quyền xóa'
            });
        }

        return res.status(200).json({
            message: 'Đã xóa công việc thành công'
        });

    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi xóa công việc',
            error: error.message
        });
    }
};
