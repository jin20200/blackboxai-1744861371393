const mongoose = require('mongoose');
const User = require('../models/User');
const config = require('../config/config');

const createAdminUser = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(config.mongoURI);
        console.log('Connected to MongoDB');

        // Check if admin user already exists
        const adminExists = await User.findOne({ username: 'admin' });
        
        if (adminExists) {
            console.log('Admin user already exists');
            return;
        }

        // Create admin user
        const adminUser = await User.create({
            username: 'admin',
            password: 'admin123', // Change this in production!
            role: 'admin'
        });

        console.log('Admin user created successfully:', {
            username: adminUser.username,
            role: adminUser.role
        });

        console.log('Please change the admin password after first login!');

    } catch (error) {
        console.error('Error initializing database:', error);
    } finally {
        // Close database connection
        await mongoose.connection.close();
        console.log('Database connection closed');
    }
};

// Run the initialization
createAdminUser();

/*
Instructions for use:

1. Make sure MongoDB is running
2. From the backend directory, run:
   node scripts/init-db.js

This will create an admin user with the following credentials:
- Username: admin
- Password: admin123

IMPORTANT: Change the password immediately after first login!
*/
