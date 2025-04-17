// Switch to admin database to create application user
db = db.getSiblingDB('admin');

// Create application user with restricted permissions
db.createUser({
    user: process.env.MONGO_APP_USER,
    pwd: process.env.MONGO_APP_PASSWORD,
    roles: [
        {
            role: "readWrite",
            db: "event-manager"
        }
    ]
});

// Switch to application database
db = db.getSiblingDB('event-manager');

// Create collections with schema validation
db.createCollection("users", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["username", "password", "role"],
            properties: {
                username: {
                    bsonType: "string",
                    description: "must be a string and is required"
                },
                password: {
                    bsonType: "string",
                    description: "must be a string and is required"
                },
                role: {
                    enum: ["admin", "staff"],
                    description: "must be either admin or staff and is required"
                },
                createdAt: {
                    bsonType: "date",
                    description: "must be a date"
                }
            }
        }
    }
});

db.createCollection("guests", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["name", "email", "ticketType", "qrCode"],
            properties: {
                name: {
                    bsonType: "string",
                    description: "must be a string and is required"
                },
                email: {
                    bsonType: "string",
                    description: "must be a string and is required"
                },
                phone: {
                    bsonType: "string",
                    description: "must be a string if provided"
                },
                ticketType: {
                    enum: ["vip", "general", "invitacion"],
                    description: "must be one of vip, general, or invitacion and is required"
                },
                qrCode: {
                    bsonType: "string",
                    description: "must be a string and is required"
                },
                status: {
                    enum: ["pendiente", "ingresado", "cancelado"],
                    description: "must be one of pendiente, ingresado, or cancelado"
                },
                gift: {
                    bsonType: "string",
                    description: "must be a string if provided"
                },
                entryTime: {
                    bsonType: "date",
                    description: "must be a date if provided"
                },
                createdBy: {
                    bsonType: "objectId",
                    description: "must be an objectId and is required"
                },
                createdAt: {
                    bsonType: "date",
                    description: "must be a date"
                }
            }
        }
    }
});

// Create indexes
db.users.createIndex({ "username": 1 }, { unique: true });
db.guests.createIndex({ "email": 1 });
db.guests.createIndex({ "qrCode": 1 }, { unique: true });
db.guests.createIndex({ "status": 1 });
db.guests.createIndex({ "ticketType": 1 });
db.guests.createIndex({ "createdBy": 1 });
db.guests.createIndex({ "createdAt": 1 });

// Create compound indexes for common queries
db.guests.createIndex({ "ticketType": 1, "status": 1 });
db.guests.createIndex({ "createdBy": 1, "createdAt": -1 });

// Create text index for search functionality
db.guests.createIndex({ 
    "name": "text", 
    "email": "text" 
}, {
    weights: {
        name: 2,
        email: 1
    },
    name: "guest_search_index"
});

// Set up TTL index for any temporary data (if needed)
// db.temporary_collection.createIndex({ "createdAt": 1 }, { expireAfterSeconds: 86400 });

print('Database initialization completed successfully');
