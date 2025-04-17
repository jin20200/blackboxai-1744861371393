#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./logs/scale-manager-${TIMESTAMP}.log"
CONFIG_DIR="./config/scaling"
MIN_INSTANCES=2
MAX_INSTANCES=10
CPU_THRESHOLD_UP=80
CPU_THRESHOLD_DOWN=30
MEMORY_THRESHOLD_UP=80
MEMORY_THRESHOLD_DOWN=40
SCALE_COOLDOWN=300 # 5 minutes

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")" "$CONFIG_DIR"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to get current resource usage
get_resource_usage() {
    local service=$1
    
    # Get CPU usage
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$service" | sed 's/%//')
    
    # Get memory usage
    local memory_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$service" | sed 's/%//')
    
    echo "$cpu_usage $memory_usage"
}

# Function to check if scaling is needed
check_scaling_needs() {
    local service=$1
    log_message "Verificando necesidades de escalado para $service..." "INFO"
    
    # Get current number of replicas
    local current_replicas=$(docker-compose ps -q "$service" | wc -l)
    
    # Get resource usage
    read -r cpu_usage memory_usage <<< "$(get_resource_usage "$service")"
    
    # Check if scaling up is needed
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD_UP" | bc -l) )) || \
       (( $(echo "$memory_usage > $MEMORY_THRESHOLD_UP" | bc -l) )); then
        if [ "$current_replicas" -lt "$MAX_INSTANCES" ]; then
            echo "up"
        fi
    # Check if scaling down is needed
    elif (( $(echo "$cpu_usage < $CPU_THRESHOLD_DOWN" | bc -l) )) && \
         (( $(echo "$memory_usage < $MEMORY_THRESHOLD_DOWN" | bc -l) )); then
        if [ "$current_replicas" -gt "$MIN_INSTANCES" ]; then
            echo "down"
        fi
    else
        echo "none"
    fi
}

# Function to scale service
scale_service() {
    local service=$1
    local direction=$2
    
    log_message "Escalando servicio $service $direction..." "INFO"
    
    local current_replicas=$(docker-compose ps -q "$service" | wc -l)
    local new_replicas
    
    if [ "$direction" == "up" ]; then
        new_replicas=$((current_replicas + 1))
    else
        new_replicas=$((current_replicas - 1))
    fi
    
    # Scale the service
    docker-compose up -d --scale "$service=$new_replicas"
    
    if [ $? -eq 0 ]; then
        log_message "Servicio escalado exitosamente a $new_replicas instancias" "SUCCESS"
        return 0
    else
        log_message "Error al escalar servicio" "ERROR"
        return 1
    fi
}

# Function to update load balancer configuration
update_load_balancer() {
    log_message "Actualizando configuración del balanceador de carga..." "INFO"
    
    # Get list of active service instances
    local instances=$(docker-compose ps -q api)
    
    # Generate nginx upstream configuration
    cat > ./nginx/conf.d/upstream.conf << EOL
upstream api_servers {
    least_conn;
EOL
    
    for instance in $instances; do
        local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$instance")
        echo "    server $container_ip:3000;" >> ./nginx/conf.d/upstream.conf
    done
    
    echo "}" >> ./nginx/conf.d/upstream.conf
    
    # Reload nginx configuration
    docker-compose exec -T nginx nginx -s reload
    
    if [ $? -eq 0 ]; then
        log_message "Configuración de balanceo actualizada exitosamente" "SUCCESS"
        return 0
    else
        log_message "Error al actualizar configuración de balanceo" "ERROR"
        return 1
    fi
}

# Function to monitor service health
monitor_service_health() {
    local service=$1
    log_message "Monitoreando salud del servicio $service..." "INFO"
    
    local instances=$(docker-compose ps -q "$service")
    local unhealthy=0
    
    for instance in $instances; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$instance")
        
        if [ "$health_status" != "healthy" ]; then
            ((unhealthy++))
            log_message "Instancia $instance no saludable: $health_status" "WARNING"
        fi
    done
    
    echo $unhealthy
}

# Function to handle instance recovery
recover_instance() {
    local instance=$1
    log_message "Intentando recuperar instancia $instance..." "INFO"
    
    # Try to restart the instance
    docker restart "$instance"
    
    # Wait for health check
    sleep 30
    
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$instance")
    
    if [ "$health_status" == "healthy" ]; then
        log_message "Instancia recuperada exitosamente" "SUCCESS"
        return 0
    else
        log_message "No se pudo recuperar la instancia" "ERROR"
        return 1
    fi
}

# Function to generate scaling report
generate_scaling_report() {
    local report_file="./reports/scaling-report-${TIMESTAMP}.txt"
    
    log_message "Generando reporte de escalado..." "INFO"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOL
Reporte de Escalado del Sistema
==============================
Fecha: $(date)

Estado Actual
------------
Instancias API: $(docker-compose ps -q api | wc -l)
Instancias MongoDB: $(docker-compose ps -q mongodb | wc -l)

Métricas de Recursos
------------------
$(docker stats --no-stream)

Historial de Escalado
-------------------
$(cat "$LOG_FILE" | grep "Escalando servicio")

Estado de Salud
-------------
Instancias no saludables: $(monitor_service_health api)

Configuración de Balanceo
-----------------------
$(cat ./nginx/conf.d/upstream.conf)
EOL
    
    log_message "Reporte generado: ${report_file}" "SUCCESS"
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/scale-manager.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  monitor              Monitorear y escalar automáticamente"
    echo -e "  scale <servicio> <up|down>  Escalar servicio manualmente"
    echo -e "  health              Verificar salud de servicios"
    echo -e "  report              Generar reporte de escalado"
    echo -e "  update-lb           Actualizar configuración del balanceador"
}

# Main execution
case "$1" in
    monitor)
        while true; do
            for service in api mongodb; do
                scale_direction=$(check_scaling_needs "$service")
                
                if [ "$scale_direction" != "none" ]; then
                    scale_service "$service" "$scale_direction"
                    update_load_balancer
                    sleep "$SCALE_COOLDOWN"
                fi
                
                unhealthy_count=$(monitor_service_health "$service")
                if [ "$unhealthy_count" -gt 0 ]; then
                    log_message "Detectadas $unhealthy_count instancias no saludables" "WARNING"
                    docker-compose ps -q "$service" | while read -r instance; do
                        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$instance")
                        if [ "$health_status" != "healthy" ]; then
                            recover_instance "$instance"
                        fi
                    done
                fi
            done
            
            sleep 60
        done
        ;;
    scale)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Debe especificar servicio y dirección" "ERROR"
            exit 1
        fi
        scale_service "$2" "$3"
        update_load_balancer
        ;;
    health)
        for service in api mongodb; do
            unhealthy_count=$(monitor_service_health "$service")
            echo -e "Servicio $service: $unhealthy_count instancias no saludables"
        done
        ;;
    report)
        generate_scaling_report
        ;;
    update-lb)
        update_load_balancer
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_message "Comando no válido" "ERROR"
        show_help
        exit 1
        ;;
esac

# Make script executable
chmod +x scripts/scale-manager.sh
