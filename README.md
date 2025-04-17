# Event Manager System

A comprehensive event management system with robust DevOps tooling and automation.

## System Overview

This system provides a complete solution for event management with:
- User and guest management
- QR code-based entry system
- Real-time monitoring
- Automated scaling
- Comprehensive logging
- Security auditing
- Performance monitoring
- Automated backups
- Deployment automation

## Quick Start

```bash
# Set up development environment
./scripts/control.sh dev start

# Check system status
./scripts/control.sh status

# Deploy to production
./scripts/control.sh prod deploy
```

## System Requirements

- Docker 20.10.0 or higher
- Docker Compose 1.29.0 or higher
- Node.js 14.0.0 or higher
- MongoDB 4.4 or higher
- Nginx 1.18 or higher

## Directory Structure

```
.
├── backend/               # Backend API service
├── monitoring/           # Monitoring configuration
│   ├── prometheus/      # Prometheus configuration
│   └── grafana/        # Grafana dashboards
├── nginx/               # Nginx configuration
├── scripts/             # Automation scripts
└── docs/               # Documentation
```

## Scripts Documentation

### Control Script
The main interface for managing the system: `./scripts/control.sh`

Categories:
- `dev`: Development environment management
- `prod`: Production environment management
- `maint`: Maintenance tasks
- `monitor`: Monitoring operations
- `db`: Database management

### Development Scripts

#### Dev Setup (`dev-setup.sh`)
Sets up the development environment.
```bash
./scripts/control.sh dev start
./scripts/control.sh dev stop
./scripts/control.sh dev restart
```

#### Database Management (`db-manage.sh`)
Handles database migrations and seeding.
```bash
./scripts/control.sh db migrate
./scripts/control.sh db rollback
./scripts/control.sh db seed
```

### Production Scripts

#### Deployment (`deploy.sh`)
Manages production deployments.
```bash
./scripts/control.sh prod deploy
./scripts/control.sh prod rollback
```

#### Scaling (`scale-manager.sh`)
Handles service scaling.
```bash
./scripts/control.sh prod scale api up
./scripts/control.sh prod scale api down
```

### Maintenance Scripts

#### Backup (`backup.sh`)
Manages system backups.
```bash
./scripts/control.sh maint backup
```

#### Cleanup (`cleanup.sh`)
Cleans up system resources.
```bash
./scripts/control.sh maint cleanup
```

#### Security Audit (`security-audit.sh`)
Performs security checks.
```bash
./scripts/control.sh maint security
```

#### Performance Test (`performance-test.sh`)
Runs performance tests.
```bash
./scripts/control.sh maint performance
```

### Monitoring Scripts

#### Setup Monitoring (`setup-monitoring.sh`)
Configures monitoring stack.
```bash
./scripts/control.sh monitor start
./scripts/control.sh monitor status
```

#### Log Management (`log-manager.sh`)
Manages system logs.
```bash
./scripts/control.sh maint logs rotate
./scripts/control.sh maint logs analyze
```

#### Notifications (`notify-manager.sh`)
Handles system notifications.
```bash
./scripts/control.sh monitor alerts critical "Message"
./scripts/control.sh monitor report
```

## Configuration

### Environment Variables

Create `.env.production` for production settings:
```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb://mongodb:27017/event-manager
```

### Monitoring Configuration

1. Prometheus (`monitoring/prometheus.yml`)
2. Grafana (`monitoring/grafana/`)
3. Alert rules (`monitoring/alert.rules.yml`)

### Nginx Configuration

1. Main config (`nginx/nginx.conf`)
2. Server blocks (`nginx/conf.d/`)

## Deployment

### Development
```bash
./scripts/control.sh dev start
```

### Staging
```bash
./scripts/control.sh prod deploy staging
```

### Production
```bash
./scripts/control.sh prod deploy production
```

## Monitoring

Access monitoring interfaces:
- Grafana: `http://localhost:3001`
- Prometheus: `http://localhost:9090`

## Maintenance

### Regular Tasks
```bash
# Daily backup
./scripts/control.sh maint backup

# Weekly cleanup
./scripts/control.sh maint cleanup

# Monthly security audit
./scripts/control.sh maint security
```

### Emergency Procedures

1. System Issues:
```bash
# Check status
./scripts/control.sh status

# Emergency restart
./scripts/control.sh prod restart
```

2. Database Issues:
```bash
# Backup
./scripts/control.sh db backup

# Restore
./scripts/control.sh db restore <backup-file>
```

## Security

### Security Features
- Automated security audits
- SSL/TLS configuration
- Docker security settings
- Database authentication
- API rate limiting

### Security Best Practices
1. Regularly update dependencies
2. Monitor security alerts
3. Perform regular audits
4. Maintain access controls

## Troubleshooting

### Common Issues

1. Container Issues:
```bash
./scripts/control.sh status
./scripts/control.sh prod restart
```

2. Database Issues:
```bash
./scripts/control.sh db migrate
```

3. Performance Issues:
```bash
./scripts/control.sh maint performance
```

### Logs

Access logs:
```bash
./scripts/control.sh maint logs view
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

## License

MIT License - see LICENSE file for details

## Support

For support:
- Create an issue
- Contact: support@example.com
- Documentation: `/docs`
