const express = require('express');
const cors = require('cors');
require('dotenv').config();
const connectDB = require('./config/database');

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Kết nối CSDL
connectDB();

// Đăng ký Routes
// app.use('/api/tasks', require('./routes/taskRoutes'));

// Khởi chạy server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});