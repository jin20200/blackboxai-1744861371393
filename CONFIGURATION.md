# Configuration Guide

This document outlines all configuration options, environment variables, and system settings for the Event Manager system.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Application Configuration](#application-configuration)
- [Database Configuration](#database-configuration)
- [Cache Configuration](#cache-configuration)
- [Security Configuration](#security-configuration)
- [Logging Configuration](#logging-configuration)
- [Monitoring Configuration](#monitoring-configuration)
- [Network Configuration](#network-configuration)
- [Service Configuration](#service-configuration)
- [Development Configuration](#development-configuration)

## Environment Variables

### Core Variables

```bash
# Core application settings
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
API_VERSION=v1
DEBUG=false

# Application URLs
APP_URL=https://app.your-domain.com
API_URL=https://api.your-domain.com
ADMIN_URL=https://admin.your-domain.com

# Timeouts and Limits
REQUEST_TIMEOUT=30000
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=1000
```

### Secret Management

```bash
# Security keys
JWT_SECRET=your-jwt-secret
ENCRYPTION_KEY=your-encryption-key
API_KEY=your-api-key

# External service secrets
STRIPE_SECRET_KEY=sk_live_...
SENDGRID_API_KEY=SG...
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

## Application Configuration

### Main Configuration

```javascript
// config/app.js
module.exports = {
  app: {
    name: 'Event Manager',
    version: '1.0.0',
    locale: 'en',
    timezone: 'UTC'
  },
  
  server: {
    port: process.env.PORT || 3000,
    host: process.env.HOST || '0.0.0.0',
    cors: {
      origin: ['https://app.your-domain.com'],
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
    }
  },
  
  api: {
    version: process.env.API_VERSION || 'v1',
    prefix: '/api',
    timeout: parseInt(process.env.REQUEST_TIMEOUT) || 30000,
    rateLimit: {
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 900000,
      max: parseInt(process.env.RATE_LIMIT_MAX) || 1000
    }
  }
};
```

### Feature Flags

```javascript
// config/features.js
module.exports = {
  features: {
    registration: true,
    socialLogin: true,
    emailVerification: true,
    twoFactorAuth: false,
    guestCheckin: true,
    ticketScanning: true,
    reporting: true
  },
  
  beta: {
    realTimeUpdates: false,
    advancedAnalytics: false,
    aiRecommendations: false
  }
};
```

## Database Configuration

### MongoDB Configuration

```javascript
// config/database.js
module.exports = {
  mongodb: {
    url: process.env.MONGO_URI,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      family: 4
    },
    
    indexes: {
      // Automatic index creation
      autoIndex: process.env.NODE_ENV !== 'production'
    },
    
    debug: {
      // Debug mode for development
      enabled: process.env.NODE_ENV === 'development'
    }
  }
};
```

### Redis Configuration

```javascript
// config/cache.js
module.exports = {
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD,
    
    options: {
      db: parseInt(process.env.REDIS_DB) || 0,
      keyPrefix: 'event-manager:',
      
      retry_strategy: function (options) {
        if (options.error && options.error.code === 'ECONNREFUSED') {
          return new Error('Redis server refused connection');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
          return new Error('Redis retry time exhausted');
        }
        if (options.attempt > 10) {
          return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
      }
    }
  }
};
```

## Security Configuration

### Authentication Configuration

```javascript
// config/auth.js
module.exports = {
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: '24h',
    refreshExpiresIn: '7d',
    algorithm: 'HS256'
  },
  
  password: {
    saltRounds: 10,
    minLength: 8,
    requireUppercase: true,
    requireNumbers: true,
    requireSpecialChars: true
  },
  
  session: {
    name: 'sid',
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
  }
};
```

### SSL Configuration

```javascript
// config/ssl.js
module.exports = {
  ssl: {
    enabled: process.env.NODE_ENV === 'production',
    key: fs.readFileSync('path/to/key.pem'),
    cert: fs.readFileSync('path/to/cert.pem'),
    
    options: {
      requestCert: false,
      rejectUnauthorized: false
    }
  }
};
```

## Logging Configuration

### Winston Logger

```javascript
// config/logging.js
module.exports = {
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    
    format: {
      timestamp: true,
      colorize: process.env.NODE_ENV === 'development',
      json: process.env.NODE_ENV === 'production'
    },
    
    transports: {
      console: {
        enabled: true,
        level: process.env.NODE_ENV === 'development' ? 'debug' : 'info'
      },
      file: {
        enabled: true,
        filename: 'logs/app-%DATE%.log',
        datePattern: 'YYYY-MM-DD',
        maxSize: '20m',
        maxFiles: '14d'
      }
    }
  }
};
```

## Monitoring Configuration

### Prometheus Configuration

```yaml
# config/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'event-manager'
    static_configs:
      - targets: ['localhost:3000']
```

### Grafana Configuration

```yaml
# config/grafana.yml
security:
  admin_user: admin
  admin_password: admin

auth:
  disable_login_form: false

dashboards:
  default_home_dashboard_path: /etc/grafana/dashboards/home.json
```

## Network Configuration

### Nginx Configuration

```nginx
# config/nginx.conf
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Service Configuration

### Queue Configuration

```javascript
// config/queue.js
module.exports = {
  queue: {
    driver: 'redis',
    prefix: 'queue:',
    
    jobs: {
      // Job processing configuration
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 1000
      },
      
      // Job types
      types: {
        email: {
          timeout: 30000,
          priority: 'high'
        },
        notification: {
          timeout: 10000,
          priority: 'normal'
        },
        report: {
          timeout: 300000,
          priority: 'low'
        }
      }
    }
  }
};
```

## Development Configuration

### Development Tools

```javascript
// config/development.js
module.exports = {
  development: {
    debug: true,
    
    cors: {
      enabled: true,
      origin: '*'
    },
    
    swagger: {
      enabled: true,
      path: '/api-docs'
    },
    
    morgan: {
      enabled: true,
      format: 'dev'
    }
  }
};
```

### Testing Configuration

```javascript
// config/testing.js
module.exports = {
  testing: {
    database: {
      url: 'mongodb://localhost:27017/event-manager-test'
    },
    
    mail: {
      driver: 'array'
    },
    
    queue: {
      driver: 'sync'
    }
  }
};
```

## Configuration Management

### Loading Configuration

```javascript
// config/index.js
const config = {
  // Load all configurations
  ...require('./app'),
  ...require('./database'),
  ...require('./cache'),
  ...require('./auth'),
  ...require('./logging'),
  ...require('./queue')
};

// Environment-specific overrides
if (process.env.NODE_ENV === 'development') {
  Object.assign(config, require('./development'));
}

if (process.env.NODE_ENV === 'test') {
  Object.assign(config, require('./testing'));
}

module.exports = config;
```

## Resources

- [Environment Variables Guide](./docs/env-vars.md)
- [Configuration Best Practices](./docs/config-best-practices.md)
- [Security Configuration Guide](./docs/security-config.md)
- [Development Setup Guide](./docs/dev-setup.md)
