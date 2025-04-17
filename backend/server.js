const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const guestRoutes = require('./routes/guestRoutes');
const ticketRoutes = require('./routes/ticketRoutes');
const { errorHandler } = require('./middleware/errorHandler');
const config = require('./config/config');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../')));

// Database connection
mongoose.connect(config.mongoURI)
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/guests', guestRoutes);
app.use('/api/tickets', ticketRoutes);

// Error handling
app.use(errorHandler);

// Serve static files for frontend routes
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../index.html'));
});

const PORT = config.port || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
