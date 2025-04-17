const QRCode = require('qrcode');
const Guest = require('../models/Guest');
const { AppError, asyncHandler } = require('../middleware/errorHandler');

// @desc    Create new guest
// @route   POST /api/guests
// @access  Private
exports.createGuest = asyncHandler(async (req, res) => {
    const { name, email, phone, ticketType } = req.body;

    // Create guest
    const guest = await Guest.create({
        name,
        email,
        phone,
        ticketType,
        createdBy: req.user._id
    });

    // Generate QR code
    const qrCodeData = await QRCode.toDataURL(guest.qrCode);

    res.status(201).json({
        success: true,
        message: 'Invitado creado exitosamente',
        data: {
            guest,
            qrCode: qrCodeData
        }
    });
});

// @desc    Get all guests
// @route   GET /api/guests
// @access  Private
exports.getGuests = asyncHandler(async (req, res) => {
    // Build query
    const query = {};
    
    // If user is not admin, only show their created guests
    if (req.user.role !== 'admin') {
        query.createdBy = req.user._id;
    }

    // Filter by status if provided
    if (req.query.status) {
        query.status = req.query.status;
    }

    // Filter by ticket type if provided
    if (req.query.ticketType) {
        query.ticketType = req.query.ticketType;
    }

    const guests = await Guest.find(query)
        .populate('createdBy', 'username')
        .sort('-createdAt');

    res.json({
        success: true,
        count: guests.length,
        data: guests
    });
});

// @desc    Get single guest
// @route   GET /api/guests/:id
// @access  Private
exports.getGuest = asyncHandler(async (req, res) => {
    const guest = await Guest.findById(req.params.id)
        .populate('createdBy', 'username');

    if (!guest) {
        throw new AppError('Invitado no encontrado', 404);
    }

    // Check if user has access to this guest
    if (req.user.role !== 'admin' && guest.createdBy._id.toString() !== req.user.id) {
        throw new AppError('No autorizado para ver este invitado', 403);
    }

    res.json({
        success: true,
        data: guest
    });
});

// @desc    Update guest
// @route   PUT /api/guests/:id
// @access  Private
exports.updateGuest = asyncHandler(async (req, res) => {
    let guest = await Guest.findById(req.params.id);

    if (!guest) {
        throw new AppError('Invitado no encontrado', 404);
    }

    // Check if user has access to update this guest
    if (req.user.role !== 'admin' && guest.createdBy.toString() !== req.user.id) {
        throw new AppError('No autorizado para actualizar este invitado', 403);
    }

    // Update guest
    guest = await Guest.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true
    });

    res.json({
        success: true,
        data: guest
    });
});

// @desc    Delete guest
// @route   DELETE /api/guests/:id
// @access  Private
exports.deleteGuest = asyncHandler(async (req, res) => {
    const guest = await Guest.findById(req.params.id);

    if (!guest) {
        throw new AppError('Invitado no encontrado', 404);
    }

    // Check if user has access to delete this guest
    if (req.user.role !== 'admin' && guest.createdBy.toString() !== req.user.id) {
        throw new AppError('No autorizado para eliminar este invitado', 403);
    }

    await guest.remove();

    res.json({
        success: true,
        message: 'Invitado eliminado exitosamente'
    });
});

// @desc    Register guest entry
// @route   POST /api/guests/:id/entry
// @access  Private
exports.registerEntry = asyncHandler(async (req, res) => {
    const guest = await Guest.findById(req.params.id);

    if (!guest) {
        throw new AppError('Invitado no encontrado', 404);
    }

    // Check if guest can enter
    if (!guest.canEnter()) {
        throw new AppError('El invitado ya ha ingresado o su entrada está cancelada', 400);
    }

    // Register entry
    await guest.registerEntry();

    res.json({
        success: true,
        message: 'Entrada registrada exitosamente',
        data: guest
    });
});

// @desc    Register gift
// @route   POST /api/guests/:id/gift
// @access  Private
exports.registerGift = asyncHandler(async (req, res) => {
    const { gift } = req.body;
    const guest = await Guest.findById(req.params.id);

    if (!guest) {
        throw new AppError('Invitado no encontrado', 404);
    }

    // Register gift
    await guest.registerGift(gift);

    res.json({
        success: true,
        message: 'Regalo registrado exitosamente',
        data: guest
    });
});

// @desc    Verify guest by QR code
// @route   GET /api/guests/verify/:qrCode
// @access  Private
exports.verifyGuestByQR = asyncHandler(async (req, res) => {
    const guest = await Guest.findOne({ qrCode: req.params.qrCode });

    if (!guest) {
        throw new AppError('Código QR inválido', 404);
    }

    res.json({
        success: true,
        data: guest
    });
});

// @desc    Get guest statistics
// @route   GET /api/guests/stats
// @access  Private
exports.getGuestStats = asyncHandler(async (req, res) => {
    const stats = await Guest.aggregate([
        {
            $group: {
                _id: null,
                totalGuests: { $sum: 1 },
                enteredGuests: {
                    $sum: {
                        $cond: [{ $eq: ['$status', 'ingresado'] }, 1, 0]
                    }
                },
                pendingGuests: {
                    $sum: {
                        $cond: [{ $eq: ['$status', 'pendiente'] }, 1, 0]
                    }
                },
                vipGuests: {
                    $sum: {
                        $cond: [{ $eq: ['$ticketType', 'vip'] }, 1, 0]
                    }
                },
                generalGuests: {
                    $sum: {
                        $cond: [{ $eq: ['$ticketType', 'general'] }, 1, 0]
                    }
                },
                invitacionGuests: {
                    $sum: {
                        $cond: [{ $eq: ['$ticketType', 'invitacion'] }, 1, 0]
                    }
                },
                giftsRegistered: {
                    $sum: {
                        $cond: [{ $ne: ['$gift', null] }, 1, 0]
                    }
                }
            }
        }
    ]);

    res.json({
        success: true,
        data: stats[0] || {
            totalGuests: 0,
            enteredGuests: 0,
            pendingGuests: 0,
            vipGuests: 0,
            generalGuests: 0,
            invitacionGuests: 0,
            giftsRegistered: 0
        }
    });
});
