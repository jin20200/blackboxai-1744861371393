const QRCode = require('qrcode');
const crypto = require('crypto');

/**
 * Generate a QR code as a data URL
 * @param {string} data - The data to encode in the QR code
 * @returns {Promise<string>} The QR code as a data URL
 */
exports.generateQRCode = async (data) => {
    try {
        const options = {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            quality: 0.92,
            margin: 1,
            color: {
                dark: '#000000',
                light: '#ffffff'
            }
        };

        return await QRCode.toDataURL(data, options);
    } catch (error) {
        throw new Error('Error al generar código QR: ' + error.message);
    }
};

/**
 * Generate a unique code for guests
 * @returns {string} A unique code
 */
exports.generateUniqueCode = () => {
    const timestamp = Date.now().toString(36);
    const randomBytes = crypto.randomBytes(4).toString('hex');
    return `${timestamp}-${randomBytes}`;
};

/**
 * Format date to local string
 * @param {Date} date - The date to format
 * @returns {string} Formatted date string
 */
exports.formatDate = (date) => {
    return new Date(date).toLocaleString('es-ES', {
        dateStyle: 'medium',
        timeStyle: 'short'
    });
};

/**
 * Calculate event statistics
 * @param {Array} guests - Array of guest objects
 * @returns {Object} Statistics object
 */
exports.calculateStats = (guests) => {
    return guests.reduce((stats, guest) => {
        // Count total guests
        stats.total++;

        // Count by ticket type
        stats.byTicketType[guest.ticketType]++;

        // Count by status
        stats.byStatus[guest.status]++;

        // Count gifts if applicable
        if (guest.ticketType === 'invitacion' && guest.gift) {
            stats.giftsReceived++;
        }

        return stats;
    }, {
        total: 0,
        byTicketType: {
            vip: 0,
            general: 0,
            invitacion: 0
        },
        byStatus: {
            pendiente: 0,
            ingresado: 0,
            cancelado: 0
        },
        giftsReceived: 0
    });
};

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @returns {boolean} True if email is valid
 */
exports.isValidEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

/**
 * Validate phone number format
 * @param {string} phone - Phone number to validate
 * @returns {boolean} True if phone number is valid
 */
exports.isValidPhone = (phone) => {
    const phoneRegex = /^\+?[\d\s-]{8,}$/;
    return phoneRegex.test(phone);
};

/**
 * Generate a random password
 * @param {number} length - Length of the password
 * @returns {string} Random password
 */
exports.generateRandomPassword = (length = 10) => {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < length; i++) {
        const randomIndex = crypto.randomInt(0, charset.length);
        password += charset[randomIndex];
    }
    return password;
};

/**
 * Sanitize user input
 * @param {string} input - Input to sanitize
 * @returns {string} Sanitized input
 */
exports.sanitizeInput = (input) => {
    return input
        .trim()
        .replace(/[<>]/g, '') // Remove < and > to prevent HTML injection
        .replace(/['"]/g, ''); // Remove quotes
};

/**
 * Generate pagination metadata
 * @param {number} total - Total number of items
 * @param {number} page - Current page number
 * @param {number} limit - Items per page
 * @returns {Object} Pagination metadata
 */
exports.getPaginationMetadata = (total, page, limit) => {
    const totalPages = Math.ceil(total / limit);
    const hasNextPage = page < totalPages;
    const hasPrevPage = page > 1;

    return {
        currentPage: page,
        totalPages,
        totalItems: total,
        itemsPerPage: limit,
        hasNextPage,
        hasPrevPage,
        nextPage: hasNextPage ? page + 1 : null,
        prevPage: hasPrevPage ? page - 1 : null
    };
};

/**
 * Check if a user has required permissions
 * @param {string} userRole - User's role
 * @param {Array} requiredRoles - Array of required roles
 * @returns {boolean} True if user has required permissions
 */
exports.hasPermission = (userRole, requiredRoles) => {
    return requiredRoles.includes(userRole);
};
