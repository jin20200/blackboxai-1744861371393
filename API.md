# API Documentation

Comprehensive documentation for the Event Manager API endpoints, authentication, and usage.

## Table of Contents

- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Data Models](#data-models)
- [Webhooks](#webhooks)
- [API Versioning](#api-versioning)
- [Best Practices](#best-practices)

## Authentication

### JWT Authentication

```bash
# Login request
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}

# Response
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Using Authentication

```bash
# Include token in requests
GET /api/events
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Token Refresh

```bash
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

## API Endpoints

### Events

#### Create Event
```bash
POST /api/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Tech Conference 2024",
  "date": "2024-06-15T09:00:00Z",
  "venue": "Convention Center",
  "capacity": 500,
  "ticketTypes": [
    {
      "name": "Regular",
      "price": 199.99,
      "quantity": 400
    },
    {
      "name": "VIP",
      "price": 499.99,
      "quantity": 100
    }
  ]
}

# Response
{
  "id": "event_123",
  "name": "Tech Conference 2024",
  "status": "draft",
  "created": "2024-01-15T10:30:00Z"
}
```

#### List Events
```bash
GET /api/events
Authorization: Bearer <token>

# Query Parameters
?status=active
?from=2024-01-01
?to=2024-12-31
?limit=10
?page=1

# Response
{
  "events": [...],
  "total": 100,
  "page": 1,
  "pages": 10
}
```

#### Get Event Details
```bash
GET /api/events/:id
Authorization: Bearer <token>

# Response
{
  "id": "event_123",
  "name": "Tech Conference 2024",
  "status": "active",
  "tickets": {
    "sold": 250,
    "available": 250
  },
  "revenue": 49997.50
}
```

### Guests

#### Register Guest
```bash
POST /api/events/:id/guests
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "ticketType": "Regular",
  "preferences": {
    "dietary": "vegetarian",
    "seating": "front"
  }
}

# Response
{
  "id": "guest_456",
  "ticketNumber": "TC2024-456",
  "qrCode": "data:image/png;base64,..."
}
```

#### Check-in Guest
```bash
POST /api/events/:id/checkin
Authorization: Bearer <token>
Content-Type: application/json

{
  "ticketNumber": "TC2024-456"
}

# Response
{
  "status": "checked-in",
  "timestamp": "2024-06-15T09:15:00Z"
}
```

### Reports

#### Event Statistics
```bash
GET /api/events/:id/stats
Authorization: Bearer <token>

# Response
{
  "attendance": {
    "total": 250,
    "checkedIn": 180
  },
  "revenue": {
    "total": 49997.50,
    "byType": {
      "Regular": 39998.00,
      "VIP": 9999.50
    }
  }
}
```

## Error Handling

### Error Codes

```javascript
const errorCodes = {
  AUTH_001: 'Invalid credentials',
  AUTH_002: 'Token expired',
  EVENT_001: 'Event not found',
  EVENT_002: 'Invalid event data',
  GUEST_001: 'Guest not found',
  GUEST_002: 'Invalid ticket'
};
```

### Error Response Format

```json
{
  "error": {
    "code": "EVENT_001",
    "message": "Event not found",
    "details": {
      "eventId": "event_123"
    }
  }
}
```

## Rate Limiting

### Limits

```javascript
const rateLimits = {
  public: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // requests per window
  },
  authenticated: {
    windowMs: 15 * 60 * 1000,
    max: 1000
  }
};
```

### Rate Limit Headers

```bash
# Response headers
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Data Models

### Event Model

```javascript
const eventSchema = {
  name: String,
  date: Date,
  venue: {
    name: String,
    address: String,
    capacity: Number
  },
  ticketTypes: [{
    name: String,
    price: Number,
    quantity: Number
  }],
  status: {
    type: String,
    enum: ['draft', 'active', 'completed', 'cancelled']
  }
};
```

### Guest Model

```javascript
const guestSchema = {
  name: String,
  email: String,
  ticketNumber: String,
  ticketType: String,
  status: {
    type: String,
    enum: ['registered', 'checked-in', 'cancelled']
  },
  preferences: {
    dietary: String,
    seating: String
  }
};
```

## Webhooks

### Webhook Events

```javascript
const webhookEvents = {
  'event.created': 'When a new event is created',
  'event.updated': 'When an event is updated',
  'guest.registered': 'When a guest registers',
  'guest.checked-in': 'When a guest checks in'
};
```

### Webhook Configuration

```bash
POST /api/webhooks
Authorization: Bearer <token>
Content-Type: application/json

{
  "url": "https://your-domain.com/webhook",
  "events": ["event.created", "guest.registered"],
  "secret": "your_webhook_secret"
}
```

## API Versioning

### Version Header

```bash
# Request with version header
GET /api/events
Accept: application/json
X-API-Version: 2024-01-15
```

### Version URL

```bash
# Version in URL
GET /api/v1/events
GET /api/v2/events
```

## Best Practices

### Request Guidelines

1. **Pagination**
```bash
GET /api/events?limit=10&page=2
GET /api/events?cursor=eyJpZCI6MTIzfQ==
```

2. **Filtering**
```bash
GET /api/events?status=active&venue=convention-center
```

3. **Sorting**
```bash
GET /api/events?sort=date:desc,name:asc
```

### Response Guidelines

1. **Envelope Format**
```json
{
  "data": {},
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0"
  }
}
```

2. **Collection Format**
```json
{
  "data": [],
  "meta": {
    "total": 100,
    "page": 1,
    "pages": 10
  }
}
```

## SDK Examples

### Node.js

```javascript
const EventManager = require('event-manager-sdk');

const client = new EventManager({
  apiKey: 'your_api_key',
  environment: 'production'
});

// Create event
const event = await client.events.create({
  name: 'Tech Conference 2024',
  date: '2024-06-15T09:00:00Z'
});

// Register guest
const guest = await client.guests.register(event.id, {
  name: 'John Doe',
  email: 'john@example.com'
});
```

### Python

```python
from event_manager import EventManagerClient

client = EventManagerClient(
    api_key='your_api_key',
    environment='production'
)

# Create event
event = client.events.create(
    name='Tech Conference 2024',
    date='2024-06-15T09:00:00Z'
)

# Register guest
guest = client.guests.register(
    event_id=event.id,
    name='John Doe',
    email='john@example.com'
)
```

## Testing

### Sandbox Environment

```bash
# Sandbox base URL
BASE_URL=https://api-sandbox.event-manager.com

# Sandbox credentials
API_KEY=sk_test_123...
```

### Test Cards

```javascript
const testCards = {
  success: '4242424242424242',
  decline: '4000000000000002',
  insufficient_funds: '4000000000009995'
};
```

## Resources

- [API Reference](https://api.event-manager.com/docs)
- [SDK Documentation](https://github.com/event-manager/sdk)
- [Webhook Guide](https://api.event-manager.com/docs/webhooks)
- [API Status](https://status.event-manager.com)
