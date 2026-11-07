
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/database');

// Đọc biến môi trường từ file .env
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Kết nối MongoDB
connectDB();

// Route kiểm tra server
app.get('/', (req, res) => {
    res.json({
        message: 'Task Manager API đang hoạt động!'
    });
});

// Route xác thực tài khoản
app.use('/api/auth', require('./routes/authRoutes'));

// Khởi động server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server đang chạy tại cổng ${PORT}`);
});
