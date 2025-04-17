# Database Guide

This document outlines the database architecture, schema design, and management procedures for the Event Manager system.

## Table of Contents

- [Database Overview](#database-overview)
- [Schema Design](#schema-design)
- [Data Models](#data-models)
- [Indexes](#indexes)
- [Query Optimization](#query-optimization)
- [Database Management](#database-management)
- [Backup and Recovery](#backup-and-recovery)
- [Monitoring](#monitoring)
- [Security](#security)
- [Best Practices](#best-practices)

## Database Overview

### Architecture

```yaml
database_architecture:
  primary: MongoDB
  caching: Redis
  type: distributed
  sharding: enabled
  replication: enabled
```

### Configuration

```javascript
// MongoDB configuration
const dbConfig = {
  // Connection settings
  connection: {
    url: process.env.MONGO_URI,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000
    }
  },
  
  // Replica set configuration
  replication: {
    name: 'event-manager-rs',
    nodes: [
      { host: 'mongo-1', priority: 1 },
      { host: 'mongo-2', priority: 0.5 },
      { host: 'mongo-3', priority: 0.5 }
    ]
  }
};
```

## Schema Design

### Core Schemas

```javascript
// User Schema
const userSchema = {
  _id: ObjectId,
  email: { type: String, unique: true },
  password: String,
  profile: {
    name: String,
    avatar: String,
    phone: String
  },
  roles: [String],
  settings: {
    notifications: Boolean,
    theme: String
  },
  created_at: Date,
  updated_at: Date
};

// Event Schema
const eventSchema = {
  _id: ObjectId,
  title: String,
  description: String,
  date: Date,
  location: {
    address: String,
    coordinates: [Number],
    venue: String
  },
  organizer: { type: ObjectId, ref: 'User' },
  capacity: Number,
  tickets: [{
    type: String,
    price: Number,
    quantity: Number,
    sold: Number
  }],
  status: {
    type: String,
    enum: ['draft', 'published', 'cancelled', 'completed']
  },
  tags: [String],
  created_at: Date,
  updated_at: Date
};

// Guest Schema
const guestSchema = {
  _id: ObjectId,
  event: { type: ObjectId, ref: 'Event' },
  user: { type: ObjectId, ref: 'User' },
  ticket: {
    type: String,
    number: String,
    price: Number
  },
  status: {
    type: String,
    enum: ['registered', 'checked-in', 'cancelled']
  },
  check_in: {
    time: Date,
    location: String
  },
  created_at: Date,
  updated_at: Date
};
```

## Data Models

### Model Relationships

```javascript
// Relationship definitions
const relationships = {
  // One-to-Many
  user_events: {
    from: 'User',
    to: 'Event',
    type: 'one-to-many',
    field: 'organizer'
  },
  
  // Many-to-Many
  event_guests: {
    from: 'Event',
    to: 'User',
    through: 'Guest',
    type: 'many-to-many'
  }
};
```

### Data Validation

```javascript
// Validation rules
const validation = {
  user: {
    email: {
      type: String,
      required: true,
      unique: true,
      validate: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i
    },
    password: {
      type: String,
      required: true,
      minlength: 8
    }
  },
  
  event: {
    capacity: {
      type: Number,
      min: 1,
      validate: {
        validator: Number.isInteger,
        message: '{VALUE} is not an integer'
      }
    }
  }
};
```

## Indexes

### Index Strategy

```javascript
// Index configuration
const indexes = {
  // Collection indexes
  users: [
    { email: 1, unique: true },
    { 'profile.name': 1 }
  ],
  
  events: [
    { date: 1 },
    { organizer: 1 },
    { status: 1 },
    { 'location.coordinates': '2dsphere' }
  ],
  
  guests: [
    { event: 1 },
    { user: 1 },
    { 'ticket.number': 1, unique: true }
  ]
};
```

### Compound Indexes

```javascript
// Compound index examples
db.events.createIndex({
  status: 1,
  date: -1
});

db.guests.createIndex({
  event: 1,
  status: 1,
  'check_in.time': -1
});
```

## Query Optimization

### Query Patterns

```javascript
// Optimized queries
const queryPatterns = {
  // Use projection
  findUser: async (id) => {
    return User.findById(id)
      .select('email profile.name')
      .lean();
  },
  
  // Use aggregation
  getEventStats: async (eventId) => {
    return Event.aggregate([
      { $match: { _id: eventId } },
      { $lookup: { from: 'guests', ... } },
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]).cache(300);
  }
};
```

### Performance Tuning

```javascript
// Performance optimization
const performanceConfig = {
  // Query optimization
  queryOptimizer: {
    maxTimeMS: 5000,
    hint: useIndexes,
    explain: analyzeQueries
  },
  
  // Batch operations
  batchSize: 1000,
  
  // Caching strategy
  cache: {
    enabled: true,
    ttl: 3600,
    invalidation: ['write', 'update']
  }
};
```

## Database Management

### Migration System

```javascript
// Migration configuration
const migrationConfig = {
  // Migration settings
  migrations: {
    directory: './migrations',
    tableName: 'migrations',
    sortDirsSeparately: true
  },
  
  // Migration template
  template: {
    up: async (db) => {
      // Migration logic
    },
    down: async (db) => {
      // Rollback logic
    }
  }
};
```

### Data Seeding

```javascript
// Seed configuration
const seedConfig = {
  // Seed data
  seeds: {
    directory: './seeds',
    runOnce: true
  },
  
  // Seed order
  order: [
    'users',
    'events',
    'guests'
  ]
};
```

## Backup and Recovery

### Backup Strategy

```javascript
// Backup configuration
const backupConfig = {
  // Backup schedule
  schedule: {
    full: '0 0 * * *',      // Daily
    incremental: '0 */6 * * *' // Every 6 hours
  },
  
  // Backup storage
  storage: {
    type: 's3',
    bucket: 'database-backups',
    retention: '30d'
  }
};
```

### Recovery Procedures

```javascript
// Recovery configuration
const recoveryConfig = {
  // Recovery types
  types: {
    pointInTime: true,
    snapshot: true,
    logical: true
  },
  
  // Recovery validation
  validation: {
    checksum: true,
    dataIntegrity: true,
    applicationTests: true
  }
};
```

## Monitoring

### Metrics Collection

```javascript
// Monitoring configuration
const monitoringConfig = {
  // Database metrics
  metrics: {
    performance: [
      'query_time',
      'connections',
      'operations',
      'cache_hits'
    ],
    storage: [
      'disk_usage',
      'index_size',
      'data_size'
    ]
  },
  
  // Alerts
  alerts: {
    highLatency: 'query_time > 100ms',
    highConnections: 'connections > 1000',
    lowCacheHits: 'cache_hits < 80%'
  }
};
```

### Health Checks

```javascript
// Health check configuration
const healthChecks = {
  // Check types
  checks: {
    connection: async () => {
      await mongoose.connection.db.admin().ping();
    },
    replication: async () => {
      await checkReplicationLag();
    },
    indexes: async () => {
      await verifyIndexes();
    }
  }
};
```

## Security

### Access Control

```javascript
// Security configuration
const securityConfig = {
  // Authentication
  auth: {
    mechanism: 'SCRAM-SHA-256',
    source: 'admin'
  },
  
  // Authorization
  roles: {
    readWrite: ['read', 'write'],
    readOnly: ['read'],
    admin: ['all']
  },
  
  // Encryption
  encryption: {
    atRest: true,
    inTransit: true
  }
};
```

### Audit Logging

```javascript
// Audit configuration
const auditConfig = {
  // Audit events
  events: [
    'insert',
    'update',
    'delete',
    'command'
  ],
  
  // Audit detail
  detail: {
    who: true,
    what: true,
    when: true,
    where: true
  }
};
```

## Best Practices

### Development Guidelines

1. Use schema validation
2. Implement proper indexing
3. Write efficient queries
4. Handle errors properly
5. Use transactions when needed
6. Implement proper logging
7. Regular maintenance
8. Security best practices

### Performance Guidelines

```javascript
// Performance best practices
const performanceBestPractices = {
  // Query optimization
  queries: {
    useIndexes: true,
    limitResults: true,
    properProjection: true
  },
  
  // Data management
  data: {
    properSchemaDesign: true,
    regularArchiving: true,
    efficientIndexing: true
  }
};
```

## Resources

- [MongoDB Documentation](https://docs.mongodb.com/)
- [Database Best Practices](./docs/database-best-practices.md)
- [Schema Design Guide](./docs/schema-design.md)
- [Performance Tuning Guide](./docs/performance-tuning.md)
