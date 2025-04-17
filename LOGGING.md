# Logging Guide

This document outlines the logging strategy, configuration, and best practices for the Event Manager system.

## Table of Contents

- [Logging Overview](#logging-overview)
- [Log Levels](#log-levels)
- [Log Categories](#log-categories)
- [Log Formats](#log-formats)
- [Log Storage](#log-storage)
- [Log Rotation](#log-rotation)
- [Log Analysis](#log-analysis)
- [Monitoring and Alerts](#monitoring-and-alerts)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Logging Overview

### Architecture

```yaml
logging_architecture:
  collectors:
    - application_logs
    - system_logs
    - access_logs
    - security_logs
    
  storage:
    short_term: elasticsearch
    long_term: s3
    
  visualization:
    platform: kibana
    dashboards: grafana
```

### Configuration

```javascript
// Logging configuration
const loggingConfig = {
  // Global settings
  global: {
    environment: process.env.NODE_ENV,
    service: 'event-manager',
    version: '1.0.0'
  },
  
  // Output settings
  output: {
    console: true,
    file: true,
    elasticsearch: true
  }
};
```

## Log Levels

### Level Definitions

```javascript
// Log level configuration
const logLevels = {
  error: {
    level: 0,
    color: 'red',
    console: true,
    file: true,
    alert: true
  },
  
  warn: {
    level: 1,
    color: 'yellow',
    console: true,
    file: true,
    alert: false
  },
  
  info: {
    level: 2,
    color: 'blue',
    console: true,
    file: true,
    alert: false
  },
  
  debug: {
    level: 3,
    color: 'green',
    console: process.env.NODE_ENV !== 'production',
    file: true,
    alert: false
  },
  
  trace: {
    level: 4,
    color: 'gray',
    console: false,
    file: true,
    alert: false
  }
};
```

### Usage Examples

```javascript
// Logger implementation
const logger = {
  error: (message, meta = {}) => {
    log('error', message, meta);
  },
  
  warn: (message, meta = {}) => {
    log('warn', message, meta);
  },
  
  info: (message, meta = {}) => {
    log('info', message, meta);
  },
  
  debug: (message, meta = {}) => {
    log('debug', message, meta);
  },
  
  trace: (message, meta = {}) => {
    log('trace', message, meta);
  }
};
```

## Log Categories

### Application Logs

```javascript
// Application logging
const applicationLogs = {
  // Request logging
  request: {
    enabled: true,
    format: 'combined',
    exclude: ['/health', '/metrics']
  },
  
  // Error logging
  error: {
    enabled: true,
    stackTrace: true,
    contextData: true
  },
  
  // Performance logging
  performance: {
    enabled: true,
    slowThreshold: 1000
  }
};
```

### System Logs

```javascript
// System logging configuration
const systemLogs = {
  // Resource monitoring
  resources: {
    cpu: true,
    memory: true,
    disk: true,
    network: true
  },
  
  // Process monitoring
  process: {
    start: true,
    stop: true,
    crash: true
  }
};
```

## Log Formats

### JSON Format

```javascript
// JSON log format
const jsonFormat = {
  timestamp: new Date().toISOString(),
  level: 'info',
  message: 'User login successful',
  context: {
    userId: '123',
    ip: '192.168.1.1',
    userAgent: 'Mozilla/5.0'
  },
  service: 'auth-service',
  environment: 'production'
};
```

### Text Format

```javascript
// Text log format
const textFormat = {
  pattern: '[%timestamp%] %level%: %message% %metadata%',
  timestamp: {
    format: 'YYYY-MM-DD HH:mm:ss.SSS'
  },
  metadata: {
    separator: ' | ',
    include: ['service', 'environment', 'requestId']
  }
};
```

## Log Storage

### Short-term Storage

```javascript
// Elasticsearch configuration
const elasticsearchConfig = {
  node: 'http://elasticsearch:9200',
  
  indices: {
    application: {
      name: 'app-logs',
      retention: '30d'
    },
    system: {
      name: 'sys-logs',
      retention: '15d'
    }
  },
  
  options: {
    maxRetries: 3,
    requestTimeout: 30000
  }
};
```

### Long-term Storage

```javascript
// S3 archival configuration
const s3Config = {
  bucket: 'event-manager-logs',
  
  organization: {
    prefix: 'logs',
    dateFormat: 'YYYY/MM/DD'
  },
  
  retention: {
    days: 365,
    lifecycle: {
      transition: {
        days: 90,
        storageClass: 'GLACIER'
      }
    }
  }
};
```

## Log Rotation

### Rotation Policy

```javascript
// Log rotation configuration
const rotationConfig = {
  // File rotation
  file: {
    maxSize: '100M',
    maxFiles: 10,
    compress: true,
    datePattern: 'YYYY-MM-DD'
  },
  
  // Index rotation
  elasticsearch: {
    maxIndices: 30,
    rollover: {
      maxSize: '50GB',
      maxAge: '30d'
    }
  }
};
```

### Cleanup Policy

```javascript
// Log cleanup configuration
const cleanupConfig = {
  // Retention periods
  retention: {
    error: '365d',
    warn: '90d',
    info: '30d',
    debug: '7d',
    trace: '3d'
  },
  
  // Cleanup schedule
  schedule: '0 0 * * *' // Daily at midnight
};
```

## Log Analysis

### Search and Analysis

```javascript
// Log analysis tools
const analysisTools = {
  // Search configuration
  search: {
    engine: 'elasticsearch',
    indices: ['app-logs-*', 'sys-logs-*'],
    maxResults: 10000
  },
  
  // Analysis features
  analysis: {
    patterns: true,
    trends: true,
    anomalies: true,
    correlations: true
  }
};
```

### Visualization

```javascript
// Visualization configuration
const visualizationConfig = {
  // Kibana dashboards
  kibana: {
    defaultIndex: 'app-logs-*',
    refreshInterval: '1m',
    dashboards: [
      'application-overview',
      'error-analysis',
      'performance-metrics'
    ]
  },
  
  // Grafana integration
  grafana: {
    datasource: 'elasticsearch',
    dashboards: [
      'system-metrics',
      'application-metrics'
    ]
  }
};
```

## Monitoring and Alerts

### Alert Rules

```javascript
// Alert configuration
const alertConfig = {
  // Error alerts
  errors: {
    threshold: 10,
    timeWindow: '5m',
    channels: ['slack', 'email']
  },
  
  // Performance alerts
  performance: {
    responseTime: {
      threshold: 1000,
      timeWindow: '5m'
    },
    errorRate: {
      threshold: 1,
      timeWindow: '5m'
    }
  }
};
```

### Notification Channels

```javascript
// Notification configuration
const notificationConfig = {
  // Slack notifications
  slack: {
    webhook: process.env.SLACK_WEBHOOK,
    channel: '#alerts',
    username: 'Logger Bot'
  },
  
  // Email notifications
  email: {
    from: 'alerts@your-domain.com',
    to: ['team@your-domain.com'],
    subject: '[LOG ALERT] {{ alert.name }}'
  }
};
```

## Best Practices

### Logging Guidelines

1. Use appropriate log levels
2. Include contextual information
3. Structure logs consistently
4. Handle sensitive data properly
5. Implement proper error handling
6. Use correlation IDs
7. Include timestamps
8. Add source information

### Performance Considerations

```javascript
// Performance optimization
const loggingPerformance = {
  // Batch processing
  batch: {
    size: 100,
    interval: 5000
  },
  
  // Buffer configuration
  buffer: {
    size: '100M',
    flush: 'interval'
  }
};
```

## Troubleshooting

### Common Issues

```javascript
// Troubleshooting guide
const troubleshooting = {
  // Missing logs
  missingLogs: {
    checkPoints: [
      'Log level configuration',
      'Storage permissions',
      'Disk space',
      'Service status'
    ]
  },
  
  // Performance issues
  performance: {
    checkPoints: [
      'Batch size',
      'Buffer configuration',
      'Storage capacity',
      'Network connectivity'
    ]
  }
};
```

### Debug Mode

```bash
# Enable debug logging
./scripts/log-manager.sh debug enable

# Analyze log issues
./scripts/log-manager.sh analyze issues

# View real-time logs
./scripts/log-manager.sh tail
```

## Resources

- [Logging Best Practices](./docs/logging-best-practices.md)
- [Log Analysis Guide](./docs/log-analysis.md)
- [Troubleshooting Guide](./docs/logging-troubleshooting.md)
- [Alert Configuration](./docs/alert-configuration.md)
