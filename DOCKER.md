# Docker Guide

This document outlines the containerization strategy, Docker configurations, and best practices for the Event Manager system.

## Table of Contents

- [Docker Overview](#docker-overview)
- [Container Architecture](#container-architecture)
- [Docker Configuration](#docker-configuration)
- [Docker Compose](#docker-compose)
- [Build Process](#build-process)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [Container Management](#container-management)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Docker Overview

### Container Strategy

```yaml
containerization_strategy:
  approach: microservices
  base_images: alpine-based
  registry: private
  versioning: semantic
  security: rootless
```

### Image Hierarchy

```
Base Image
   ↓
Language Base (Node.js)
   ↓
Application Base
   ↓
Service Images
```

## Container Architecture

### Service Containers

```yaml
services:
  api:
    image: event-manager-api
    scale: 1-5
    
  worker:
    image: event-manager-worker
    scale: 1-3
    
  frontend:
    image: event-manager-frontend
    scale: 1-2
    
  database:
    image: mongodb
    scale: 1
    
  cache:
    image: redis
    scale: 1-3
```

### Network Layout

```yaml
networks:
  frontend_net:
    driver: bridge
    services: [frontend, api]
    
  backend_net:
    driver: bridge
    services: [api, worker, database, cache]
    
  monitoring_net:
    driver: bridge
    services: [prometheus, grafana]
```

## Docker Configuration

### Dockerfile Examples

```dockerfile
# API Service Dockerfile
FROM node:16-alpine

# Security: Run as non-root user
USER node

# Set working directory
WORKDIR /app

# Copy package files
COPY --chown=node:node package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY --chown=node:node . .

# Set environment
ENV NODE_ENV=production

# Start application
CMD ["npm", "start"]
```

### Multi-stage Builds

```dockerfile
# Frontend Build
FROM node:16-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production Image
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
```

## Docker Compose

### Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  api:
    build:
      context: ./backend
      target: development
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev

  frontend:
    build:
      context: ./frontend
      target: development
    volumes:
      - ./frontend:/app
      - /app/node_modules
    command: npm run dev
```

### Production Environment

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  api:
    build:
      context: ./backend
      target: production
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      target: production
    deploy:
      replicas: 2
```

## Build Process

### Build Scripts

```bash
# Build script
#!/bin/bash

# Build all images
docker-compose build

# Build specific service
docker-compose build api

# Build with no cache
docker-compose build --no-cache
```

### Build Optimization

```dockerfile
# Optimize build layers
FROM node:16-alpine

# Layer 1: Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Layer 2: Copy source code
COPY . .

# Layer 3: Build application
RUN npm run build
```

## Development Environment

### Local Development

```bash
# Start development environment
./scripts/control.sh dev start

# Development commands
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml logs -f
docker-compose -f docker-compose.dev.yml exec api sh
```

### Development Tools

```yaml
# Development tools configuration
services:
  dev-tools:
    image: event-manager-dev-tools
    volumes:
      - .:/workspace
    environment:
      - NODE_ENV=development
    ports:
      - "9229:9229"  # Debug port
```

## Production Environment

### Production Configuration

```yaml
# Production settings
services:
  api:
    environment:
      - NODE_ENV=production
      - API_KEY=${API_KEY}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped
```

### Deployment Process

```bash
# Production deployment
./scripts/deploy.sh production

# Deployment steps:
1. Build images
2. Push to registry
3. Pull on production
4. Rolling update
```

## Container Management

### Health Checks

```yaml
# Health check configuration
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Resource Limits

```yaml
# Resource constraints
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Best Practices

### Security

```yaml
# Security best practices
security:
  # Run as non-root
  user: node
  
  # Minimal base image
  FROM node:16-alpine
  
  # Security scanning
  scan:
    - vulnerability
    - secrets
    - compliance
```

### Performance

```yaml
# Performance optimization
performance:
  # Multi-stage builds
  build:
    stages:
      - development
      - test
      - production
      
  # Layer optimization
  layers:
    - dependencies
    - source
    - configuration
```

## Troubleshooting

### Common Issues

```bash
# Container troubleshooting
docker logs <container>
docker inspect <container>
docker stats <container>
docker exec -it <container> sh
```

### Debug Mode

```yaml
# Debug configuration
services:
  api:
    environment:
      - DEBUG=express:*
    ports:
      - "9229:9229"
    command: ["npm", "run", "debug"]
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Container Security Guide](./docs/container-security.md)
