
const mongoose = require('mongoose');

const connectDB = async () => {
    if (!process.env.MONGO_URI) {
        throw new Error('Chưa cấu hình MONGO_URI trong file .env');
    }

    try {
        await mongoose.connect(process.env.MONGO_URI);

        console.log('MongoDB connected successfully');

        return mongoose.connection;
    } catch (error) {
        console.error('MongoDB connection failed:', error.message);
        throw error;
    }
};

module.exports = connectDB;
