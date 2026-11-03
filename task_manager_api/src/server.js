
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/database');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API kiểm tra server
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Task Manager API đang hoạt động'
    });
});

// API xác thực
app.use('/api/auth', require('./routes/authRoutes'));

// API quản lý công việc
app.use('/api/tasks', require('./routes/askRoutes'));

// Xử lý API không tồn tại
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'API không tồn tại',
        path: req.originalUrl
    });
});

// Xử lý lỗi server
app.use((err, req, res, next) => {
    console.error(err.stack);

    res.status(500).json({
        success: false,
        message: 'Lỗi server',
        error: err.message
    });
});

const PORT = process.env.PORT || 3000;

const startServer = async () => {
    try {
        await connectDB();

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server running on port ${PORT}`);
            console.log(`API: http://localhost:${PORT}`);
        });
    } catch (error) {
        console.error('Không thể khởi động server:', error.message);
        process.exit(1);
    }
};

startServer();
