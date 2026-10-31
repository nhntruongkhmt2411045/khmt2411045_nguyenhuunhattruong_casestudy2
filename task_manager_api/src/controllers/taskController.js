const Task = require('../models/Task');

// 1. Lấy danh sách công việc (có tìm kiếm, lọc theo trạng thái/mức ưu tiên)
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, q } = req.query;
        let query = {
            $or: [
                { createdBy: req.user.id },
                { assigneeIds: req.user.id }
            ]
        };

        if (status) query.status = status;
        if (priority) query.priority = priority;
        if (q) query.title = { $regex: q, $options: 'i' };

        const tasks = await Task.find(query)
            .populate('createdBy', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .sort({ createdAt: -1 });

        res.json(tasks);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 2. Tạo công việc mới
exports.createTask = async (req, res) => {
    try {
        const { title, description, startDate, dueDate, priority, status } = req.body;
        const newTask = new Task({
            title,
            description,
            startDate,
            dueDate,
            priority: priority || 'medium',
            status: status || 'todo',
            createdBy: req.user.id
        });
        await newTask.save();
        res.status(201).json(newTask);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 3. Xem chi tiết công việc
exports.getTaskById = async (req, res) => {
    try {
        const task = await Task.findById(req.params.id)
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email');
        if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
        res.json(task);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 4. Cập nhật thông tin công việc
exports.updateTask = async (req, res) => {
    try {
        const task = await Task.findByIdAndUpdate(
            req.params.id,
            { ...req.body, updatedAt: Date.now() },
            { new: true }
        );
        if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
        res.json(task);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 5. Xóa công việc
exports.deleteTask = async (req, res) => {
    try {
        const task = await Task.findByIdAndDelete(req.params.id);
        if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
        res.json({ message: 'Đã xóa công việc thành công' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};