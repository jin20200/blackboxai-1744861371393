#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Iniciando configuración del sistema de monitoreo...${NC}\n"

# Create necessary directories
echo -e "${BLUE}Creando directorios necesarios...${NC}"
mkdir -p prometheus_data grafana_data
chmod 777 prometheus_data grafana_data

# Check if monitoring stack is already running
if docker ps | grep -q "event-manager-prometheus\|event-manager-grafana"; then
    echo -e "${YELLOW}Stack de monitoreo detectado. Deteniendo servicios...${NC}"
    docker-compose -f docker-compose.prod.yml stop prometheus grafana mongodb-exporter node-exporter
fi

# Validate configurations
echo -e "${BLUE}Validando archivos de configuración...${NC}"

# Check Prometheus config
if ! docker run --rm -v $(pwd)/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus:latest \
    --config.file=/etc/prometheus/prometheus.yml \
    check; then
    echo -e "${RED}Error en la configuración de Prometheus${NC}"
    exit 1
fi

# Set up Grafana permissions
echo -e "${BLUE}Configurando permisos de Grafana...${NC}"
if [ -d "grafana_data" ]; then
    chmod -R 472 grafana_data
fi

# Create monitoring network if it doesn't exist
if ! docker network ls | grep -q "event-manager-network-prod"; then
    echo -e "${BLUE}Creando red de monitoreo...${NC}"
    docker network create event-manager-network-prod
fi

# Start monitoring services
echo -e "${BLUE}Iniciando servicios de monitoreo...${NC}"
docker-compose -f docker-compose.prod.yml up -d prometheus grafana mongodb-exporter node-exporter

# Wait for services to be ready
echo -e "${BLUE}Esperando que los servicios estén listos...${NC}"
sleep 10

# Check if services are running
echo -e "${BLUE}Verificando estado de los servicios...${NC}"
services=("prometheus" "grafana" "mongodb-exporter" "node-exporter")
all_running=true

for service in "${services[@]}"; do
    if ! docker ps | grep -q "event-manager-$service"; then
        echo -e "${RED}Error: $service no está ejecutándose${NC}"
        all_running=false
    fi
done

if [ "$all_running" = true ]; then
    echo -e "${GREEN}✓ Todos los servicios de monitoreo están ejecutándose correctamente${NC}"
else
    echo -e "${RED}Algunos servicios no se iniciaron correctamente${NC}"
    echo -e "${YELLOW}Revisando logs de los servicios...${NC}"
    docker-compose -f docker-compose.prod.yml logs prometheus grafana mongodb-exporter node-exporter
    exit 1
fi

# Configure Grafana datasource
echo -e "${BLUE}Configurando datasource de Grafana...${NC}"
sleep 5  # Wait for Grafana to be fully ready

# Get Grafana admin password from environment or use default
GRAFANA_PASS=${GRAFANA_ADMIN_PASSWORD:-admin}

# Add Prometheus datasource
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"name":"Prometheus","type":"prometheus","url":"http://prometheus:9090","access":"proxy","isDefault":true}' \
    "http://admin:${GRAFANA_PASS}@localhost:3001/api/datasources"

echo -e "\n${GREEN}¡Configuración de monitoreo completada!${NC}"
echo -e "\nAccesos:"
echo -e "- Prometheus: http://localhost:9090"
echo -e "- Grafana: http://localhost:3001"
echo -e "  Usuario: admin"
echo -e "  Contraseña: ${GRAFANA_PASS}"
echo -e "\nMétricas disponibles:"
echo -e "- Sistema: http://localhost:9100/metrics"
echo -e "- MongoDB: http://localhost:9216/metrics"
echo -e "- API: http://localhost:3000/metrics"

echo -e "\n${YELLOW}Notas importantes:${NC}"
echo -e "1. Asegúrese de cambiar la contraseña predeterminada de Grafana"
echo -e "2. Configure alertas según sus necesidades en Grafana"
echo -e "3. Los datos de monitoreo se almacenan en ./prometheus_data y ./grafana_data"
echo -e "4. Revise las reglas de alertas en monitoring/alert.rules.yml"

# Make the script executable
chmod +x monitoring/setup-monitoring.sh
