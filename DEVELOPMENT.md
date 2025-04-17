# Development Guide

This document provides comprehensive guidance for developers working on the Event Manager system.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Development Workflow](#development-workflow)
- [Testing Guidelines](#testing-guidelines)
- [Debugging](#debugging)
- [Local Development](#local-development)
- [API Development](#api-development)
- [Frontend Development](#frontend-development)
- [Database Development](#database-development)

## Development Setup

### Prerequisites

```bash
# Required software
node: ">=14.0.0"
npm: ">=6.0.0"
docker: ">=20.10.0"
docker-compose: ">=1.29.0"
mongodb: ">=4.4.0"
redis: ">=6.0.0"
```

### Initial Setup

```bash
# Clone repository
git clone https://github.com/your-org/event-manager.git
cd event-manager

# Install dependencies
npm install

# Setup development environment
./scripts/dev-setup.sh init

# Start development services
./scripts/control.sh dev start
```

## Project Structure

### Directory Layout

```
event-manager/
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   ├── tests/
│   └── config/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── utils/
│   └── tests/
├── scripts/
├── docs/
└── config/
```

### Key Components

```javascript
// Component organization
const projectComponents = {
  backend: {
    api: 'REST API endpoints',
    auth: 'Authentication system',
    database: 'Data models and migrations',
    services: 'Business logic'
  },
  
  frontend: {
    components: 'Reusable UI components',
    pages: 'Page layouts',
    state: 'Application state management',
    api: 'API integration'
  }
};
```

## Coding Standards

### Style Guide

```javascript
// ESLint configuration
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended'
  ],
  
  rules: {
    'indent': ['error', 2],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always'],
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn'
  }
};
```

### Best Practices

```javascript
// Code organization example
class UserService {
  // Constructor injection
  constructor(userRepository, emailService) {
    this.userRepository = userRepository;
    this.emailService = emailService;
  }
  
  // Clear method naming
  async createUser(userData) {
    // Input validation
    this.validateUserData(userData);
    
    // Business logic
    const user = await this.userRepository.create(userData);
    
    // Event handling
    await this.emailService.sendWelcomeEmail(user);
    
    return user;
  }
}
```

## Development Workflow

### Git Workflow

```bash
# Feature development workflow
git checkout -b feature/new-feature
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Create pull request
./scripts/control.sh pr create
```

### Branch Strategy

```javascript
// Branch naming convention
const branchTypes = {
  feature: 'feature/',
  bugfix: 'bugfix/',
  hotfix: 'hotfix/',
  release: 'release/'
};

// Version control workflow
const workflow = {
  main: 'production code',
  develop: 'development code',
  feature: 'new features',
  release: 'release preparation'
};
```

## Testing Guidelines

### Test Structure

```javascript
// Test organization
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', async () => {
      // Arrange
      const userData = {
        email: 'test@example.com',
        password: 'secure123'
      };
      
      // Act
      const user = await userService.createUser(userData);
      
      // Assert
      expect(user).toHaveProperty('id');
      expect(user.email).toBe(userData.email);
    });
  });
});
```

### Running Tests

```bash
# Run test suites
npm run test              # All tests
npm run test:unit        # Unit tests
npm run test:integration # Integration tests
npm run test:e2e        # End-to-end tests

# Test with coverage
npm run test:coverage
```

## Debugging

### Debug Configuration

```javascript
// VSCode debug configuration
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug API",
      "program": "${workspaceFolder}/backend/src/server.js",
      "env": {
        "NODE_ENV": "development",
        "DEBUG": "app:*"
      }
    }
  ]
}
```

### Debug Tools

```javascript
// Debug utilities
const debug = {
  // Request debugging
  logRequest: (req) => {
    console.log({
      method: req.method,
      path: req.path,
      query: req.query,
      body: req.body,
      headers: req.headers
    });
  },
  
  // Response debugging
  logResponse: (res) => {
    console.log({
      status: res.statusCode,
      headers: res.getHeaders(),
      body: res.body
    });
  }
};
```

## Local Development

### Environment Setup

```bash
# Create development environment
./scripts/dev-setup.sh create

# Start development services
docker-compose up -d

# Initialize database
./scripts/db-manage.sh init
```

### Development Tools

```javascript
// Development utilities
const devTools = {
  // Hot reload configuration
  hotReload: {
    enabled: true,
    watchDirs: ['src', 'config'],
    ignore: ['*.test.js', '*.spec.js']
  },
  
  // Development server
  server: {
    port: 3000,
    cors: true,
    proxy: {
      '/api': 'http://localhost:8000'
    }
  }
};
```

## API Development

### API Design

```javascript
// API structure
const apiStructure = {
  // RESTful endpoints
  endpoints: {
    users: '/api/users',
    events: '/api/events',
    guests: '/api/guests'
  },
  
  // Response format
  response: {
    success: {
      status: 200,
      data: {},
      meta: {}
    },
    error: {
      status: 400,
      error: {
        code: '',
        message: ''
      }
    }
  }
};
```

### API Documentation

```javascript
// Swagger configuration
const swaggerConfig = {
  openapi: '3.0.0',
  info: {
    title: 'Event Manager API',
    version: '1.0.0'
  },
  servers: [
    {
      url: 'http://localhost:3000',
      description: 'Development server'
    }
  ]
};
```

## Frontend Development

### Component Development

```javascript
// React component structure
const ComponentStructure = {
  // Component organization
  components: {
    common: 'shared components',
    features: 'feature-specific components',
    layouts: 'page layouts'
  },
  
  // State management
  state: {
    global: 'Redux store',
    local: 'Component state',
    context: 'React context'
  }
};
```

### Styling Guidelines

```javascript
// Styling configuration
const stylingConfig = {
  // CSS methodology
  methodology: 'BEM',
  
  // Theme configuration
  theme: {
    colors: {
      primary: '#007bff',
      secondary: '#6c757d'
    },
    spacing: {
      small: '0.5rem',
      medium: '1rem',
      large: '2rem'
    }
  }
};
```

## Database Development

### Schema Design

```javascript
// MongoDB schema example
const userSchema = new Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  password: {
    type: String,
    required: true
  },
  profile: {
    name: String,
    avatar: String
  },
  settings: {
    notifications: Boolean,
    theme: String
  }
});
```

### Migration Management

```javascript
// Database migration
const migration = {
  // Migration configuration
  config: {
    directory: 'migrations',
    tableName: 'migrations'
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

## Resources

- [Development Environment Setup](./docs/dev-setup.md)
- [Coding Standards Guide](./docs/coding-standards.md)
- [Testing Guide](./docs/testing.md)
- [API Documentation](./docs/api.md)
- [Database Guide](./docs/database.md)
