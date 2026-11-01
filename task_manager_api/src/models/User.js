const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    fullName: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true, // Tạo unique index để tránh trùng lặp email
        lowercase: true,
        trim: true
    },
    passwordHash: {
        type: String,
        required: true // Lưu mật khẩu đã băm, không lưu mật khẩu thô
    },
    avatarUrl: {
        type: String,
        default: null // Tùy chọn, đường dẫn ảnh đại diện
    }
}, {
    // Mongoose sẽ tự động quản lý hai trường createdAt và updatedAt[cite: 1]
    timestamps: true
});

module.exports = mongoose.model('User', userSchema);