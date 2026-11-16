
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/database');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/tasks', require('./routes/taskRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/statistics', require('./routes/statisticsRoutes'));

// Kiểm tra server
app.get('/', (req, res) => {
    res.json({
        message: 'Task Manager API đang hoạt động!'
    });
});

// Khởi chạy server sau khi kết nối MongoDB
const PORT = process.env.PORT || 3000;

const startServer = async () => {
    await connectDB();

    app.listen(PORT, () => {
        console.log(`Server đang chạy tại http://localhost:${PORT}`);
    });
};

startServer();
