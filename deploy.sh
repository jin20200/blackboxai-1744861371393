#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIN_NODE_VERSION="14.0.0"
ENV_FILE=".env.production"
DEPLOY_ENV="production"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to backup MongoDB
backup_mongodb() {
    echo -e "${BLUE}Creando backup de MongoDB...${NC}"
    mkdir -p "$BACKUP_DIR"
    if docker-compose -f docker-compose.prod.yml exec -T mongodb mongodump --out="/data/db/backup-${TIMESTAMP}"; then
        echo -e "${GREEN}✓ Backup creado exitosamente${NC}"
        docker cp "$(docker-compose -f docker-compose.prod.yml ps -q mongodb):/data/db/backup-${TIMESTAMP}" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ Backup copiado a $BACKUP_DIR/backup-${TIMESTAMP}${NC}"
    else
        echo -e "${RED}✗ Error al crear backup${NC}"
        exit 1
    fi
}

# Function to validate environment file
validate_env() {
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}Error: Archivo $ENV_FILE no encontrado${NC}"
        exit 1
    fi

    # Check required variables
    required_vars=("JWT_SECRET" "MONGO_ROOT_PASSWORD" "MONGO_APP_PASSWORD")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$ENV_FILE"; then
            echo -e "${RED}Error: Variable $var no encontrada en $ENV_FILE${NC}"
            exit 1
        fi
    done
}

# Function to check SSL certificates
check_ssl() {
    if [ ! -d "./certbot/conf/live" ]; then
        echo -e "${YELLOW}⚠ Certificados SSL no encontrados${NC}"
        echo -e "${BLUE}Iniciando proceso de obtención de certificados...${NC}"
        return 1
    fi
    return 0
}

# Function to setup SSL certificates
setup_ssl() {
    domain=$(grep "^NGINX_HOST=" "$ENV_FILE" | cut -d '=' -f2)
    email=$(grep "^SSL_EMAIL=" "$ENV_FILE" | cut -d '=' -f2)

    docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$email" \
        --agree-tos \
        --no-eff-email \
        -d "$domain"
}

# Main deployment script
echo -e "${BLUE}Iniciando despliegue del Sistema de Control de Eventos...${NC}\n"

# Check system requirements
echo -e "${BLUE}Verificando requisitos del sistema...${NC}"

# Check Node.js
if ! command_exists node; then
    echo -e "${RED}Error: Node.js no está instalado${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d "v" -f 2)
if version_gt $MIN_NODE_VERSION $NODE_VERSION; then
    echo -e "${RED}Error: Se requiere Node.js v${MIN_NODE_VERSION} o superior${NC}"
    exit 1
fi

# Check Docker
if ! command_exists docker; then
    echo -e "${RED}Error: Docker no está instalado${NC}"
    exit 1
fi

# Check Docker Compose
if ! command_exists docker-compose; then
    echo -e "${RED}Error: Docker Compose no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Todos los requisitos del sistema están cumplidos${NC}\n"

# Validate environment configuration
echo -e "${BLUE}Validando configuración...${NC}"
validate_env
echo -e "${GREEN}✓ Configuración válida${NC}\n"

# Create backup of existing deployment
if [ -f "docker-compose.prod.yml" ]; then
    echo -e "${BLUE}Creando backup de la implementación actual...${NC}"
    backup_mongodb
fi

# Pull latest images
echo -e "${BLUE}Descargando últimas imágenes de Docker...${NC}"
docker-compose -f docker-compose.prod.yml pull
echo -e "${GREEN}✓ Imágenes actualizadas${NC}\n"

# Check and setup SSL
if ! check_ssl; then
    setup_ssl
fi

# Stop existing containers
echo -e "${BLUE}Deteniendo contenedores existentes...${NC}"
docker-compose -f docker-compose.prod.yml down
echo -e "${GREEN}✓ Contenedores detenidos${NC}\n"

# Start new containers
echo -e "${BLUE}Iniciando nuevos contenedores...${NC}"
docker-compose -f docker-compose.prod.yml up -d
echo -e "${GREEN}✓ Contenedores iniciados${NC}\n"

# Wait for services to be ready
echo -e "${BLUE}Esperando que los servicios estén listos...${NC}"
sleep 10

# Check service health
echo -e "${BLUE}Verificando estado de los servicios...${NC}"
if docker-compose -f docker-compose.prod.yml ps | grep -q "Exit"; then
    echo -e "${RED}Error: Algunos servicios no se iniciaron correctamente${NC}"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

echo -e "${GREEN}✓ Todos los servicios están funcionando correctamente${NC}\n"

# Final checks
echo -e "${BLUE}Realizando verificaciones finales...${NC}"
curl -f http://localhost:3000/api/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API responde correctamente${NC}"
else
    echo -e "${RED}✗ Error: API no responde${NC}"
    exit 1
fi

echo -e "\n${GREEN}¡Despliegue completado exitosamente!${NC}\n"

echo -e "Accesos:"
echo -e "- API: https://$(grep '^NGINX_HOST=' "$ENV_FILE" | cut -d '=' -f2)"
echo -e "- Panel de administración: https://$(grep '^NGINX_HOST=' "$ENV_FILE" | cut -d '=' -f2)/admin"
echo -e "\nPara ver los logs:"
echo -e "docker-compose -f docker-compose.prod.yml logs -f"

# Make the script executable
chmod +x deploy.sh
