const jwt = require('jsonwebtoken');
const config = require('../config/config');
const User = require('../models/User');

exports.protect = async (req, res, next) => {
    try {
        let token;

        // Check if token exists in headers
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'No autorizado para acceder a esta ruta'
            });
        }

        try {
            // Verify token
            const decoded = jwt.verify(token, config.jwtSecret);

            // Get user from token
            const user = await User.findById(decoded.id).select('-password');
            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Usuario no encontrado'
                });
            }

            // Add user to request object
            req.user = user;
            next();
        } catch (error) {
            return res.status(401).json({
                success: false,
                message: 'Token no válido'
            });
        }
    } catch (error) {
        next(error);
    }
};

// Middleware for role-based authorization
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: 'Usuario no autorizado para acceder a esta ruta'
            });
        }
        next();
    };
};

// Middleware to check if user is admin
exports.isAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Esta ruta requiere privilegios de administrador'
        });
    }
    next();
};

// Middleware to check if user can manage guests
exports.canManageGuests = (req, res, next) => {
    if (!['admin', 'staff'].includes(req.user.role)) {
        return res.status(403).json({
            success: false,
            message: 'No tiene permisos para gestionar invitados'
        });
    }
    next();
};

// Middleware to validate guest ownership or admin rights
exports.checkGuestAccess = async (req, res, next) => {
    try {
        const guest = await require('../models/Guest').findById(req.params.id);
        
        if (!guest) {
            return res.status(404).json({
                success: false,
                message: 'Invitado no encontrado'
            });
        }

        // Allow access if user is admin or created the guest
        if (req.user.role === 'admin' || guest.createdBy.equals(req.user._id)) {
            req.guest = guest;
            next();
        } else {
            return res.status(403).json({
                success: false,
                message: 'No tiene permisos para acceder a este invitado'
            });
        }
    } catch (error) {
        next(error);
    }
};
