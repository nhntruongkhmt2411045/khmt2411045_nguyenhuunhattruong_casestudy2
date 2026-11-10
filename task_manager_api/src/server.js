
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// Routes xác thực
app.use('/api/auth', require('./routes/authRoutes'));

// Routes quản lý công việc
app.use('/api/tasks', require('./routes/taskRoutes'));

// Routes người dùng
app.use('/api/users', require('./routes/userRoutes'));

// Kiểm tra server
app.get('/', (req, res) => {
    res.json({
        message: 'Task Manager API đang hoạt động!'
    });
});

// Kết nối MongoDB
const PORT = process.env.PORT || 5000;

mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log('MongoDB kết nối thành công!');

        app.listen(PORT, () => {
            console.log(`Server đang chạy tại http://localhost:${PORT}`);
        });
    })
    .catch(err => {
        console.error('Lỗi kết nối MongoDB:', err.message);
    });
