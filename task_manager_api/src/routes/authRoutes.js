// src/routes/authRoutes.js
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware'); // Import middleware[cite: 1]

// Các API public
router.post('/register', authController.register); //[cite: 1]
router.post('/login', authController.login); //[cite: 1]

// Các API private (cần authMiddleware kiểm tra token)[cite: 1]
router.get('/me', authMiddleware, authController.getMe); //[cite: 1]
router.put('/me', authMiddleware, authController.updateProfile); //[cite: 1]
router.put('/change-password', authMiddleware, authController.changePassword); //[cite: 1]

module.exports = router;