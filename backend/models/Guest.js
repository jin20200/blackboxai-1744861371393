const mongoose = require('mongoose');

const guestSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'El nombre es requerido'],
        trim: true
    },
    email: {
        type: String,
        required: [true, 'El email es requerido'],
        trim: true,
        lowercase: true
    },
    phone: {
        type: String,
        trim: true
    },
    ticketType: {
        type: String,
        enum: ['vip', 'general', 'invitacion'],
        required: [true, 'El tipo de entrada es requerido']
    },
    qrCode: {
        type: String,
        unique: true,
        required: true
    },
    status: {
        type: String,
        enum: ['pendiente', 'ingresado', 'cancelado'],
        default: 'pendiente'
    },
    gift: {
        type: String,
        default: null
    },
    entryTime: {
        type: Date,
        default: null
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Índices para búsqueda eficiente
guestSchema.index({ qrCode: 1 });
guestSchema.index({ email: 1 });
guestSchema.index({ status: 1 });

// Método para verificar si el invitado puede ingresar
guestSchema.methods.canEnter = function() {
    return this.status === 'pendiente';
};

// Método para registrar entrada
guestSchema.methods.registerEntry = function() {
    if (!this.canEnter()) {
        throw new Error('El invitado ya ha ingresado o su entrada está cancelada');
    }
    
    this.status = 'ingresado';
    this.entryTime = new Date();
    return this.save();
};

// Método para registrar regalo
guestSchema.methods.registerGift = function(giftDescription) {
    if (this.ticketType !== 'invitacion') {
        throw new Error('Solo los invitados con tipo "invitacion" pueden registrar regalos');
    }
    
    this.gift = giftDescription;
    return this.save();
};

// Middleware para generar QR único si no existe
guestSchema.pre('save', async function(next) {
    if (!this.qrCode) {
        // Generar código único basado en timestamp y random string
        const timestamp = Date.now().toString(36);
        const randomStr = Math.random().toString(36).substring(2, 8);
        this.qrCode = `${timestamp}-${randomStr}`;
    }
    next();
});

module.exports = mongoose.model('Guest', guestSchema);
