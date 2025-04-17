# Monitoring Guide

This document outlines the monitoring, alerting, and observability setup for the Event Manager system.

## Table of Contents

- [Monitoring Overview](#monitoring-overview)
- [Metrics Collection](#metrics-collection)
- [Logging System](#logging-system)
- [Alerting Rules](#alerting-rules)
- [Dashboards](#dashboards)
- [Tracing](#tracing)
- [Health Checks](#health-checks)
- [Incident Response](#incident-response)

## Monitoring Overview

### Architecture

```
[Applications] → [Prometheus] → [Grafana]
      ↓             ↓             ↓
[Node Exporter] → [AlertManager] → [Notifications]
      ↓
[Custom Exporters]
```

### Components

```yaml
monitoring:
  metrics:
    - prometheus
    - node-exporter
    - custom-exporters
  visualization:
    - grafana
  alerting:
    - alertmanager
    - notification-channels
  logging:
    - elasticsearch
    - logstash
    - kibana
```

## Metrics Collection

### System Metrics

```javascript
// Prometheus metrics setup
const metrics = {
  httpRequestDuration: new prometheus.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.1, 0.5, 1, 2, 5]
  }),

  activeConnections: new prometheus.Gauge({
    name: 'active_connections',
    help: 'Number of active connections'
  }),

  totalRequests: new prometheus.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status']
  })
};
```

### Business Metrics

```javascript
// Custom business metrics
const businessMetrics = {
  activeEvents: new prometheus.Gauge({
    name: 'active_events',
    help: 'Number of active events'
  }),

  registeredGuests: new prometheus.Counter({
    name: 'registered_guests_total',
    help: 'Total number of registered guests',
    labelNames: ['event_type']
  }),

  ticketSales: new prometheus.Counter({
    name: 'ticket_sales_total',
    help: 'Total ticket sales in cents',
    labelNames: ['ticket_type']
  })
};
```

## Logging System

### Log Configuration

```javascript
// Winston logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'event-manager' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### Log Aggregation

```yaml
# Logstash configuration
input {
  file {
    path => "/var/log/event-manager/*.log"
    type => "event-manager"
  }
}

filter {
  json {
    source => "message"
  }
  date {
    match => ["timestamp", "ISO8601"]
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "event-manager-%{+YYYY.MM.dd}"
  }
}
```

## Alerting Rules

### System Alerts

```yaml
# Prometheus alert rules
groups:
  - name: system
    rules:
      - alert: HighCPUUsage
        expr: cpu_usage_percent > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High CPU usage detected
          
      - alert: HighMemoryUsage
        expr: memory_usage_percent > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High memory usage detected
```

### Business Alerts

```yaml
# Business alert rules
groups:
  - name: business
    rules:
      - alert: HighEventFailureRate
        expr: event_failure_rate > 0.05
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: High event failure rate detected
          
      - alert: LowTicketSales
        expr: ticket_sales_rate < 10
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: Low ticket sales rate detected
```

## Dashboards

### System Dashboard

```javascript
// Grafana dashboard configuration
{
  "dashboard": {
    "title": "System Overview",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "cpu_usage_percent",
            "legendFormat": "CPU %"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "memory_usage_percent",
            "legendFormat": "Memory %"
          }
        ]
      }
    ]
  }
}
```

### Business Dashboard

```javascript
// Business metrics dashboard
{
  "dashboard": {
    "title": "Business Metrics",
    "panels": [
      {
        "title": "Active Events",
        "type": "stat",
        "targets": [
          {
            "expr": "active_events",
            "legendFormat": "Events"
          }
        ]
      },
      {
        "title": "Ticket Sales",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ticket_sales_total[1h])",
            "legendFormat": "Sales/Hour"
          }
        ]
      }
    ]
  }
}
```

## Tracing

### Distributed Tracing

```javascript
// OpenTelemetry configuration
const tracer = new opentelemetry.Tracer({
  serviceName: 'event-manager',
  sampler: new opentelemetry.ProbabilitySampler(0.1)
});

// Trace request
app.use(async (req, res, next) => {
  const span = tracer.startSpan('http_request');
  span.setAttribute('http.method', req.method);
  span.setAttribute('http.url', req.url);
  
  try {
    await next();
    span.setAttribute('http.status_code', res.statusCode);
  } finally {
    span.end();
  }
});
```

## Health Checks

### Endpoint Health

```javascript
// Health check endpoints
app.get('/health', (req, res) => {
  const health = {
    status: 'UP',
    components: {
      database: isDatabaseHealthy(),
      cache: isCacheHealthy(),
      queue: isQueueHealthy()
    },
    timestamp: new Date()
  };
  
  res.json(health);
});
```

### Component Health

```javascript
// Component health checks
const healthChecks = {
  async checkDatabase() {
    try {
      await mongoose.connection.db.admin().ping();
      return { status: 'UP' };
    } catch (error) {
      return { status: 'DOWN', error: error.message };
    }
  },
  
  async checkRedis() {
    try {
      await redis.ping();
      return { status: 'UP' };
    } catch (error) {
      return { status: 'DOWN', error: error.message };
    }
  }
};
```

## Incident Response

### Automated Response

```javascript
// Automated incident response
const incidentResponse = {
  async handleHighLoad() {
    await scaleService('api', '+1');
    await notifyTeam('High load detected, scaling up');
  },
  
  async handleDatabaseIssue() {
    await switchToBackupDB();
    await notifyTeam('Database issue detected, switched to backup');
  }
};
```

### Manual Response

```bash
# Incident response commands
./scripts/control.sh incident create    # Create incident record
./scripts/control.sh incident update    # Update incident status
./scripts/control.sh incident resolve   # Resolve incident
```

## Configuration

### Prometheus Configuration

```yaml
# prometheus.yml
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
# grafana.ini
[auth]
disable_login_form = false

[security]
admin_user = admin
admin_password = admin

[dashboards]
default_home_dashboard_path = /etc/grafana/dashboards/home.json
```

## Usage

### Starting Monitoring

```bash
# Start monitoring stack
./scripts/control.sh monitor start

# Verify monitoring
./scripts/control.sh monitor verify
```

### Accessing Dashboards

- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Kibana: http://localhost:5601

### Managing Alerts

```bash
# View active alerts
./scripts/control.sh monitor alerts

# Silence alert
./scripts/control.sh monitor silence create
```

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- Internal Wiki: /wiki/monitoring
