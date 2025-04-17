const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config/config');
const { AppError, asyncHandler } = require('../middleware/errorHandler');

// Generate JWT Token
const generateToken = (id) => {
    return jwt.sign({ id }, config.jwtSecret, {
        expiresIn: config.jwtExpiration
    });
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = asyncHandler(async (req, res) => {
    const { username, password } = req.body;

    // Validate input
    if (!username || !password) {
        throw new AppError('Por favor ingrese usuario y contraseña', 400);
    }

    // Check user exists
    const user = await User.findOne({ username });
    if (!user) {
        throw new AppError('Credenciales inválidas', 401);
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
        throw new AppError('Credenciales inválidas', 401);
    }

    // Generate token
    const token = generateToken(user._id);

    res.json({
        success: true,
        token,
        user: {
            id: user._id,
            username: user.username,
            role: user.role
        }
    });
});

// @desc    Register new user (admin only)
// @route   POST /api/auth/register
// @access  Private/Admin
exports.register = asyncHandler(async (req, res) => {
    const { username, password, role } = req.body;

    // Check if user exists
    const userExists = await User.findOne({ username });
    if (userExists) {
        throw new AppError('El usuario ya existe', 400);
    }

    // Create user
    const user = await User.create({
        username,
        password,
        role: role || 'staff' // default to staff if no role specified
    });

    res.status(201).json({
        success: true,
        message: 'Usuario creado exitosamente',
        user: {
            id: user._id,
            username: user.username,
            role: user.role
        }
    });
});

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id).select('-password');
    
    res.json({
        success: true,
        user
    });
});

// @desc    Update user password
// @route   PUT /api/auth/updatepassword
// @access  Private
exports.updatePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;

    // Get user
    const user = await User.findById(req.user.id);

    // Check current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
        throw new AppError('Contraseña actual incorrecta', 401);
    }

    // Update password
    user.password = newPassword;
    await user.save();

    // Generate new token
    const token = generateToken(user._id);

    res.json({
        success: true,
        message: 'Contraseña actualizada exitosamente',
        token
    });
});

// @desc    Get all users (admin only)
// @route   GET /api/auth/users
// @access  Private/Admin
exports.getUsers = asyncHandler(async (req, res) => {
    const users = await User.find().select('-password');

    res.json({
        success: true,
        count: users.length,
        users
    });
});

// @desc    Delete user (admin only)
// @route   DELETE /api/auth/users/:id
// @access  Private/Admin
exports.deleteUser = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        throw new AppError('Usuario no encontrado', 404);
    }

    // Prevent admin from deleting themselves
    if (user._id.toString() === req.user.id) {
        throw new AppError('No puede eliminar su propia cuenta', 400);
    }

    await user.remove();

    res.json({
        success: true,
        message: 'Usuario eliminado exitosamente'
    });
});

// @desc    Update user role (admin only)
// @route   PUT /api/auth/users/:id/role
// @access  Private/Admin
exports.updateUserRole = asyncHandler(async (req, res) => {
    const { role } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
        throw new AppError('Usuario no encontrado', 404);
    }

    // Prevent admin from changing their own role
    if (user._id.toString() === req.user.id) {
        throw new AppError('No puede cambiar su propio rol', 400);
    }

    user.role = role;
    await user.save();

    res.json({
        success: true,
        message: 'Rol de usuario actualizado exitosamente',
        user: {
            id: user._id,
            username: user.username,
            role: user.role
        }
    });
});
