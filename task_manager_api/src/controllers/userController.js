
const User = require('../models/User');

// Tìm kiếm người dùng theo họ tên hoặc email
exports.searchUsers = async (req, res) => {
    try {
        const q = (req.query.q || '').trim();

        if (q.length < 2) {
            return res.status(400).json({
                message: 'Vui lòng nhập ít nhất 2 ký tự để tìm kiếm'
            });
        }

        // Escape ký tự đặc biệt để tránh regex injection
        const escapedQuery = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

        const users = await User.find({
            _id: { $ne: req.userId },
            $or: [
                { fullName: { $regex: escapedQuery, $options: 'i' } },
                { email: { $regex: escapedQuery, $options: 'i' } }
            ]
        })
            .select('_id fullName email avatarUrl')
            .limit(20)
            .sort({ fullName: 1 });

        return res.status(200).json({
            message: 'Tìm kiếm người dùng thành công',
            users
        });

    } catch (error) {
        console.error('Lỗi tìm kiếm người dùng:', error);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi tìm kiếm người dùng'
        });
    }
};
