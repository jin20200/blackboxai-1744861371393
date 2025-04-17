const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../server');
const User = require('../models/User');
const Guest = require('../models/Guest');

let mongoServer;
let adminToken;
let staffToken;
let testGuest;

beforeAll(async () => {
    // Create in-memory MongoDB instance
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);

    // Create test users
    const adminUser = await User.create({
        username: 'testadmin',
        password: 'testpass123',
        role: 'admin'
    });

    const staffUser = await User.create({
        username: 'teststaff',
        password: 'testpass123',
        role: 'staff'
    });

    // Get tokens
    const adminResponse = await request(app)
        .post('/api/auth/login')
        .send({ username: 'testadmin', password: 'testpass123' });
    adminToken = adminResponse.body.token;

    const staffResponse = await request(app)
        .post('/api/auth/login')
        .send({ username: 'teststaff', password: 'testpass123' });
    staffToken = staffResponse.body.token;
});

afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
});

describe('Auth Endpoints', () => {
    test('Should login successfully', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                username: 'testadmin',
                password: 'testpass123'
            });
        
        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('token');
    });

    test('Should fail with invalid credentials', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                username: 'testadmin',
                password: 'wrongpass'
            });
        
        expect(response.status).toBe(401);
    });
});

describe('Guest Management', () => {
    test('Should create new guest', async () => {
        const response = await request(app)
            .post('/api/guests')
            .set('Authorization', `Bearer ${staffToken}`)
            .send({
                name: 'Test Guest',
                email: 'test@example.com',
                phone: '1234567890',
                ticketType: 'vip'
            });

        expect(response.status).toBe(201);
        expect(response.body.data.guest).toHaveProperty('qrCode');
        testGuest = response.body.data.guest;
    });

    test('Should get guest list', async () => {
        const response = await request(app)
            .get('/api/guests')
            .set('Authorization', `Bearer ${staffToken}`);

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body.data)).toBeTruthy();
    });

    test('Should verify guest QR code', async () => {
        const response = await request(app)
            .get(`/api/guests/verify/${testGuest.qrCode}`)
            .set('Authorization', `Bearer ${staffToken}`);

        expect(response.status).toBe(200);
        expect(response.body.data).toHaveProperty('name', 'Test Guest');
    });
});

describe('Entry Management', () => {
    test('Should register guest entry', async () => {
        const response = await request(app)
            .post(`/api/guests/${testGuest._id}/entry`)
            .set('Authorization', `Bearer ${staffToken}`);

        expect(response.status).toBe(200);
        expect(response.body.data.status).toBe('ingresado');
    });

    test('Should not allow duplicate entry', async () => {
        const response = await request(app)
            .post(`/api/guests/${testGuest._id}/entry`)
            .set('Authorization', `Bearer ${staffToken}`);

        expect(response.status).toBe(400);
    });
});

describe('Gift Management', () => {
    test('Should register gift for invitation type guest', async () => {
        // First create an invitation type guest
        const invitationGuest = await request(app)
            .post('/api/guests')
            .set('Authorization', `Bearer ${staffToken}`)
            .send({
                name: 'Invitation Guest',
                email: 'invitation@example.com',
                phone: '1234567890',
                ticketType: 'invitacion'
            });

        const response = await request(app)
            .post(`/api/guests/${invitationGuest.body.data.guest._id}/gift`)
            .set('Authorization', `Bearer ${staffToken}`)
            .send({
                gift: 'Test Gift'
            });

        expect(response.status).toBe(200);
        expect(response.body.data.gift).toBe('Test Gift');
    });

    test('Should not allow gift registration for non-invitation guests', async () => {
        const response = await request(app)
            .post(`/api/guests/${testGuest._id}/gift`)
            .set('Authorization', `Bearer ${staffToken}`)
            .send({
                gift: 'Test Gift'
            });

        expect(response.status).toBe(400);
    });
});

describe('Admin Operations', () => {
    test('Should get statistics', async () => {
        const response = await request(app)
            .get('/api/guests/stats')
            .set('Authorization', `Bearer ${adminToken}`);

        expect(response.status).toBe(200);
        expect(response.body.data).toHaveProperty('totalGuests');
        expect(response.body.data).toHaveProperty('enteredGuests');
    });

    test('Staff should not access admin routes', async () => {
        const response = await request(app)
            .post('/api/auth/register')
            .set('Authorization', `Bearer ${staffToken}`)
            .send({
                username: 'newstaff',
                password: 'password123',
                role: 'staff'
            });

        expect(response.status).toBe(403);
    });
});
