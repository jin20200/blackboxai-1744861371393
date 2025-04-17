# Contributing to Event Manager

Thank you for your interest in contributing to Event Manager! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Git Workflow](#git-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Security Guidelines](#security-guidelines)
- [Performance Guidelines](#performance-guidelines)

## Code of Conduct

### Our Pledge

We are committed to providing a friendly, safe, and welcoming environment for all contributors.

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

## Development Setup

1. **Clone the Repository**
```bash
git clone https://github.com/your-org/event-manager.git
cd event-manager
```

2. **Set Up Development Environment**
```bash
./scripts/control.sh dev start
```

3. **Verify Installation**
```bash
./scripts/control.sh status
```

## Coding Standards

### JavaScript/Node.js

- Use ES6+ features
- Follow Airbnb JavaScript Style Guide
- Use async/await for asynchronous operations
- Maintain proper error handling

Example:
```javascript
// Good
async function getUserData(userId) {
  try {
    const user = await User.findById(userId);
    return user;
  } catch (error) {
    logger.error('Error fetching user:', error);
    throw new AppError('User not found', 404);
  }
}

// Bad
function getUserData(userId) {
  return User.findById(userId)
    .then(user => user)
    .catch(error => {
      console.log(error);
      throw error;
    });
}
```

### MongoDB

- Use proper indexing
- Implement data validation
- Follow schema best practices
- Use atomic operations

Example:
```javascript
// Good
const userSchema = new Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  lastLogin: {
    type: Date,
    default: Date.now
  }
});

// Bad
const userSchema = new Schema({
  email: String,
  lastLogin: Date
});
```

## Git Workflow

1. **Branch Naming Convention**
```
feature/description
bugfix/description
hotfix/description
release/version
```

2. **Commit Message Format**
```
type(scope): description

[optional body]

[optional footer]
```

Example:
```
feat(auth): implement JWT authentication

- Add JWT token generation
- Implement token validation middleware
- Add refresh token functionality

Closes #123
```

3. **Branch Management**
- `main`: Production-ready code
- `develop`: Development branch
- Feature branches: Branch from and merge to `develop`
- Release branches: Branch from `develop`, merge to `main` and `develop`

## Pull Request Process

1. **Before Submitting**
   - Update documentation
   - Add/update tests
   - Run linting: `npm run lint`
   - Run tests: `npm test`
   - Run security audit: `./scripts/control.sh maint security`

2. **PR Template**
```markdown
## Description
[Description of changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests passing
- [ ] Security audit passed
```

## Testing Guidelines

### Unit Tests

- Test individual components
- Use meaningful test descriptions
- Follow AAA pattern (Arrange, Act, Assert)

Example:
```javascript
describe('User Service', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', async () => {
      // Arrange
      const userData = {
        email: 'test@example.com',
        password: 'secure123'
      };

      // Act
      const user = await UserService.createUser(userData);

      // Assert
      expect(user).toHaveProperty('id');
      expect(user.email).toBe(userData.email);
    });
  });
});
```

### Integration Tests

- Test component interactions
- Use proper test data setup/cleanup
- Mock external services appropriately

## Documentation

### Code Documentation

- Use JSDoc for function documentation
- Document complex algorithms
- Include usage examples

Example:
```javascript
/**
 * Validates and processes guest entry
 * @param {string} qrCode - Guest's QR code
 * @param {Object} options - Processing options
 * @param {boolean} options.validateTicket - Whether to validate ticket
 * @returns {Promise<Object>} Processed guest data
 * @throws {AppError} If QR code is invalid
 */
async function processGuestEntry(qrCode, options = {}) {
  // Implementation
}
```

### API Documentation

- Document all endpoints
- Include request/response examples
- Specify error responses

## Security Guidelines

1. **Authentication & Authorization**
   - Use JWT tokens
   - Implement proper role-based access
   - Validate all user input

2. **Data Protection**
   - Use HTTPS
   - Encrypt sensitive data
   - Implement rate limiting

3. **Code Security**
   - No secrets in code
   - Regular dependency updates
   - Security audit compliance

## Performance Guidelines

1. **Database**
   - Proper indexing
   - Query optimization
   - Connection pooling

2. **API**
   - Response caching
   - Pagination
   - Request validation

3. **Monitoring**
   - Performance metrics
   - Error tracking
   - Resource utilization

## Additional Resources

- [Project Wiki](wiki-link)
- [API Documentation](api-docs-link)
- [Architecture Guide](architecture-guide-link)

## Getting Help

- Create an issue
- Join our Slack channel
- Contact the maintainers

## License

By contributing to Event Manager, you agree that your contributions will be licensed under its MIT License.
