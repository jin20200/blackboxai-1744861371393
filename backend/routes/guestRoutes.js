const express = require('express');
const router = express.Router();
const {
    createGuest,
    getGuests,
    getGuest,
    updateGuest,
    deleteGuest,
    registerEntry,
    registerGift,
    verifyGuestByQR,
    getGuestStats
} = require('../controllers/guestController');
const { 
    protect, 
    canManageGuests, 
    checkGuestAccess 
} = require('../middleware/authMiddleware');

// Protect all routes
router.use(protect);

// Guest statistics
router.get('/stats', getGuestStats);

// Verify guest by QR code
router.get('/verify/:qrCode', verifyGuestByQR);

// Guest management routes
router.route('/')
    .get(getGuests)
    .post(canManageGuests, createGuest);

router.route('/:id')
    .get(checkGuestAccess, getGuest)
    .put(checkGuestAccess, updateGuest)
    .delete(checkGuestAccess, deleteGuest);

// Entry and gift registration
router.post('/:id/entry', checkGuestAccess, registerEntry);
router.post('/:id/gift', checkGuestAccess, registerGift);

module.exports = router;
