const express = require('express');
const router = express.Router();
const {
    login,
    register,
    getMe,
    updatePassword,
    getUsers,
    deleteUser,
    updateUserRole
} = require('../controllers/authController');
const { protect, isAdmin } = require('../middleware/authMiddleware');

// Public routes
router.post('/login', login);

// Protected routes
router.use(protect); // All routes below this will be protected

router.get('/me', getMe);
router.put('/updatepassword', updatePassword);

// Admin only routes
router.use(isAdmin); // All routes below this will require admin privileges

router.post('/register', register);
router.get('/users', getUsers);
router.delete('/users/:id', deleteUser);
router.put('/users/:id/role', updateUserRole);

module.exports = router;
