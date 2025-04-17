# Testing Guide

This document outlines the testing strategy, procedures, and best practices for the Event Manager system.

## Table of Contents

- [Testing Overview](#testing-overview)
- [Testing Environment](#testing-environment)
- [Types of Tests](#types-of-tests)
- [Testing Tools](#testing-tools)
- [Test Writing Guidelines](#test-writing-guidelines)
- [CI/CD Integration](#cicd-integration)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Test Coverage](#test-coverage)

## Testing Overview

### Testing Philosophy

- Test-Driven Development (TDD)
- Behavior-Driven Development (BDD)
- Continuous Testing
- Automated Testing
- Quality Assurance

### Testing Pyramid

```
     /\
    /  \
   /UI  \
  /Int.  \
 /Unit    \
-----------
```

- 70% Unit Tests
- 20% Integration Tests
- 10% UI/E2E Tests

## Testing Environment

### Setup Development Environment
```bash
# Initialize testing environment
./scripts/dev-setup.sh test

# Verify test environment
./scripts/control.sh test verify
```

### Test Database
```javascript
// Test database configuration
const testConfig = {
  mongodb: {
    url: 'mongodb://localhost:27017/event-manager-test',
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true
    }
  }
};
```

## Types of Tests

### Unit Tests

```javascript
// Example unit test
describe('User Service', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'secure123'
      };
      
      const user = await UserService.createUser(userData);
      
      expect(user).toHaveProperty('id');
      expect(user.email).toBe(userData.email);
    });
  });
});
```

### Integration Tests

```javascript
// Example integration test
describe('Auth Flow', () => {
  it('should authenticate user and return token', async () => {
    // Setup
    const user = await createTestUser();
    
    // Execute
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: user.email,
        password: 'password123'
      });
    
    // Assert
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });
});
```

### E2E Tests

```javascript
// Example E2E test
describe('Event Creation Flow', () => {
  it('should create event and show in dashboard', async () => {
    // Login
    await page.login();
    
    // Create event
    await page.goto('/events/new');
    await page.fill('#event-name', 'Test Event');
    await page.click('#submit');
    
    // Verify
    await page.goto('/dashboard');
    expect(await page.isVisible('text=Test Event')).toBe(true);
  });
});
```

## Testing Tools

### Primary Tools

- Jest: Unit testing
- Supertest: API testing
- Playwright: E2E testing
- Istanbul: Code coverage
- k6: Performance testing

### Setup Commands

```bash
# Install testing dependencies
npm install --save-dev jest supertest playwright @playwright/test

# Initialize Jest configuration
./scripts/control.sh test init-jest

# Setup E2E testing
./scripts/control.sh test setup-e2e
```

## Test Writing Guidelines

### Naming Convention

```javascript
// Format: should_expectedBehavior_when_condition
describe('UserService', () => {
  it('should_returnUser_when_validIdProvided', () => {
    // Test implementation
  });
});
```

### Test Structure

```javascript
// AAA Pattern: Arrange, Act, Assert
describe('EventService', () => {
  it('should create event', async () => {
    // Arrange
    const eventData = {
      name: 'Test Event',
      date: new Date()
    };
    
    // Act
    const event = await EventService.createEvent(eventData);
    
    // Assert
    expect(event).toMatchObject(eventData);
  });
});
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: |
          ./scripts/control.sh test ci
```

### Test Automation

```bash
# Run all tests
./scripts/control.sh test all

# Run specific test suite
./scripts/control.sh test suite <suite-name>

# Run with coverage
./scripts/control.sh test coverage
```

## Performance Testing

### Load Testing

```javascript
// k6 load test script
export default function() {
  const response = http.get('http://localhost:3000/api/events');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200
  });
}
```

### Stress Testing

```bash
# Run stress test
./scripts/performance-test.sh stress

# Generate performance report
./scripts/performance-test.sh report
```

## Security Testing

### Security Scans

```bash
# Run security tests
./scripts/security-audit.sh test

# Generate security report
./scripts/security-audit.sh report
```

### Penetration Testing

```bash
# Run automated pen tests
./scripts/security-audit.sh pentest

# Generate vulnerability report
./scripts/security-audit.sh vuln-report
```

## Test Coverage

### Coverage Goals

- Unit Tests: 90%
- Integration Tests: 80%
- E2E Tests: 60%
- Overall: 85%

### Coverage Report

```bash
# Generate coverage report
./scripts/control.sh test coverage-report

# View coverage dashboard
./scripts/control.sh test coverage-dashboard
```

## Mocking

### Mock Examples

```javascript
// Mock service
jest.mock('../services/UserService', () => ({
  getUser: jest.fn().mockResolvedValue({
    id: '123',
    email: 'test@example.com'
  })
}));

// Mock HTTP requests
jest.mock('axios', () => ({
  get: jest.fn().mockResolvedValue({ data: { success: true } })
}));
```

## Test Data Management

### Fixtures

```javascript
// fixtures/users.js
module.exports = {
  validUser: {
    email: 'test@example.com',
    password: 'password123'
  },
  adminUser: {
    email: 'admin@example.com',
    password: 'admin123',
    role: 'admin'
  }
};
```

### Database Seeding

```bash
# Seed test database
./scripts/db-manage.sh seed test

# Clear test data
./scripts/db-manage.sh clean test
```

## Continuous Improvement

### Metrics Tracking

- Test execution time
- Coverage trends
- Failed tests tracking
- Performance metrics

### Review Process

- Code review checklist
- Test review guidelines
- Performance review criteria
- Security review requirements

## Resources

- [Jest Documentation](https://jestjs.io/)
- [Playwright Documentation](https://playwright.dev/)
- [k6 Documentation](https://k6.io/docs/)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)

## Contact

For testing-related questions:
- Email: testing@your-domain.com
- Slack: #testing-help
- Documentation: /docs/testing
