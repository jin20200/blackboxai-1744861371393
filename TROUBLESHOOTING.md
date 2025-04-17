# Troubleshooting Guide

This document provides guidance for diagnosing and resolving common issues in the Event Manager system.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [System Health](#system-health)
- [Database Issues](#database-issues)
- [API Issues](#api-issues)
- [Authentication Issues](#authentication-issues)
- [Performance Issues](#performance-issues)
- [Network Issues](#network-issues)
- [Deployment Issues](#deployment-issues)
- [Recovery Procedures](#recovery-procedures)

## Quick Diagnostics

### System Status Check

```bash
# Check overall system status
./scripts/control.sh status all

# Check specific component
./scripts/control.sh status <component>
```

### Health Check

```bash
# Run health checks
./scripts/control.sh health check

# Expected output
{
  "status": "healthy",
  "components": {
    "api": "up",
    "database": "up",
    "cache": "up",
    "queue": "up"
  }
}
```

## Common Issues

### 1. Service Not Starting

```bash
# Check service logs
./scripts/log-manager.sh view service

# Verify configuration
./scripts/control.sh verify config

# Common fixes
./scripts/maintenance.sh repair service
```

### 2. Database Connection Issues

```bash
# Check database connectivity
./scripts/db-manage.sh check connection

# Reset database connection
./scripts/db-manage.sh reset connection

# Verify database health
./scripts/db-manage.sh health check
```

### 3. Memory Issues

```bash
# Check memory usage
./scripts/control.sh monitor memory

# Clear application cache
./scripts/maintenance.sh cache clear

# Restart service with clean memory
./scripts/control.sh service restart clean
```

## System Health

### CPU Usage

```bash
# Monitor CPU usage
./scripts/control.sh monitor cpu

# High CPU usage resolution
if [[ $(top -bn1 | grep "Cpu(s)" | awk '{print $2}') > 80 ]]; then
    ./scripts/performance-test.sh analyze cpu
    ./scripts/scale-manager.sh adjust cpu
fi
```

### Memory Usage

```bash
# Check memory leaks
./scripts/maintenance.sh check memory-leaks

# Memory cleanup
./scripts/cleanup.sh memory

# Monitor memory trends
./scripts/control.sh monitor memory-trends
```

## Database Issues

### Connection Problems

```javascript
// Database connection check
const checkDatabase = async () => {
  try {
    await mongoose.connection.db.admin().ping();
    console.log('Database connected');
  } catch (error) {
    console.error('Database connection failed:', error);
    await attemptReconnect();
  }
};
```

### Query Performance

```javascript
// Slow query analysis
const analyzeQuery = async (query) => {
  const explanation = await query.explain('executionStats');
  if (explanation.executionStats.executionTimeMillis > 100) {
    console.warn('Slow query detected:', explanation);
    optimizeQuery(query);
  }
};
```

### Data Integrity

```bash
# Check data integrity
./scripts/db-manage.sh verify integrity

# Repair corrupted data
./scripts/db-manage.sh repair data

# Backup before repairs
./scripts/backup.sh database
```

## API Issues

### Request Failures

```javascript
// API request troubleshooting
const troubleshootRequest = async (req) => {
  // Check authentication
  if (!req.headers.authorization) {
    return { error: 'Missing authentication' };
  }

  // Validate input
  const validation = validateRequest(req);
  if (!validation.valid) {
    return { error: 'Invalid request', details: validation.errors };
  }

  // Check rate limits
  const rateLimit = await checkRateLimit(req);
  if (!rateLimit.allowed) {
    return { error: 'Rate limit exceeded' };
  }
};
```

### Rate Limiting

```javascript
// Rate limit configuration
const rateLimitConfig = {
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later'
};
```

## Authentication Issues

### Token Problems

```javascript
// Token validation
const validateToken = async (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return { valid: true, data: decoded };
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return { valid: false, error: 'Token expired' };
    }
    return { valid: false, error: 'Invalid token' };
  }
};
```

### Session Management

```javascript
// Session troubleshooting
const troubleshootSession = async (sessionId) => {
  // Check session existence
  const session = await Session.findById(sessionId);
  if (!session) {
    return { error: 'Session not found' };
  }

  // Check session expiration
  if (session.expiresAt < new Date()) {
    return { error: 'Session expired' };
  }

  // Verify session data
  const validation = validateSessionData(session);
  if (!validation.valid) {
    return { error: 'Invalid session data' };
  }
};
```

## Performance Issues

### Slow Responses

```bash
# Analyze response times
./scripts/performance-test.sh analyze response-times

# Identify bottlenecks
./scripts/performance-test.sh identify-bottlenecks

# Optimize performance
./scripts/performance-test.sh optimize
```

### Resource Usage

```javascript
// Resource monitoring
const monitorResources = {
  cpu: async () => {
    const usage = await getCPUUsage();
    if (usage > 80) {
      await notifyHighCPU(usage);
      await scaleResources('cpu');
    }
  },
  
  memory: async () => {
    const usage = await getMemoryUsage();
    if (usage > 85) {
      await notifyHighMemory(usage);
      await cleanupMemory();
    }
  }
};
```

## Network Issues

### Connectivity Problems

```bash
# Check network connectivity
./scripts/control.sh network test

# Analyze network traffic
./scripts/control.sh network analyze

# Reset network connections
./scripts/control.sh network reset
```

### DNS Issues

```bash
# Verify DNS resolution
./scripts/control.sh dns check

# Update DNS cache
./scripts/control.sh dns flush

# Test DNS servers
./scripts/control.sh dns test-servers
```

## Deployment Issues

### Failed Deployments

```bash
# Check deployment status
./scripts/ci-cd.sh status

# Rollback deployment
./scripts/ci-cd.sh rollback

# Verify deployment
./scripts/ci-cd.sh verify
```

### Configuration Issues

```bash
# Validate configuration
./scripts/control.sh config validate

# Reset configuration
./scripts/control.sh config reset

# Update configuration
./scripts/control.sh config update
```

## Recovery Procedures

### System Recovery

```bash
# Emergency recovery
./scripts/control.sh recover emergency

# Verify system state
./scripts/control.sh verify state

# Restore from backup
./scripts/backup.sh restore
```

### Data Recovery

```bash
# Recover lost data
./scripts/db-manage.sh recover data

# Verify data integrity
./scripts/db-manage.sh verify integrity

# Generate recovery report
./scripts/db-manage.sh report recovery
```

## Diagnostic Tools

### Log Analysis

```bash
# Analyze error patterns
./scripts/log-manager.sh analyze errors

# Generate error report
./scripts/log-manager.sh report errors

# Monitor real-time logs
./scripts/log-manager.sh monitor live
```

### Performance Analysis

```bash
# Run performance diagnostics
./scripts/performance-test.sh diagnose

# Generate performance report
./scripts/performance-test.sh report

# Monitor system metrics
./scripts/control.sh monitor metrics
```

## Contact Support

### Support Channels

- Emergency: +1-XXX-XXX-XXXX
- Email: support@your-domain.com
- Slack: #support-emergency
- On-call: [On-call Schedule](link-to-schedule)

### Escalation Process

1. Level 1: Application Support
2. Level 2: Technical Support
3. Level 3: System Engineers
4. Level 4: Senior Architects

## Resources

- [System Documentation](./docs)
- [Error Code Reference](./docs/errors)
- [Recovery Procedures](./docs/recovery)
- [Support Portal](link-to-portal)
