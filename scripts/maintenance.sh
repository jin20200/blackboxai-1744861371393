#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MAINTENANCE_DIR="./maintenance"
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${MAINTENANCE_DIR}/maintenance-${TIMESTAMP}.txt"
LOG_RETENTION_DAYS=30
DISK_THRESHOLD=80
CONTAINER_LOG_SIZE="100M"

# Create necessary directories
mkdir -p "${MAINTENANCE_DIR}" "${LOG_DIR}"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "${REPORT_FILE}"
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO] ${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING] ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR] ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS] ${message}${NC}"
            ;;
    esac
}

# Function to check disk space
check_disk_space() {
    log_message "Verificando espacio en disco..." "INFO"
    
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_message "Uso de disco crítico: ${disk_usage}%" "ERROR"
        return 1
    else
        log_message "Uso de disco normal: ${disk_usage}%" "SUCCESS"
        return 0
    fi
}

# Function to rotate logs
rotate_logs() {
    log_message "Iniciando rotación de logs..." "INFO"
    
    # Find and compress old logs
    find "${LOG_DIR}" -type f -name "*.log" -mtime +${LOG_RETENTION_DAYS} -exec gzip {} \;
    
    # Remove very old compressed logs
    find "${LOG_DIR}" -type f -name "*.log.gz" -mtime +$((LOG_RETENTION_DAYS * 2)) -delete
    
    # Rotate Docker container logs
    for container in $(docker ps -q); do
        container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
        log_message "Rotando logs del contenedor: $container_name" "INFO"
        
        docker inspect "$container" --format='{{.LogPath}}' | xargs truncate -s 0
        docker exec "$container" bash -c 'echo "" > /var/log/*.log 2>/dev/null || true'
    done
    
    log_message "Rotación de logs completada" "SUCCESS"
}

# Function to clean Docker resources
clean_docker_resources() {
    log_message "Limpiando recursos de Docker..." "INFO"
    
    # Remove unused containers
    docker container prune -f
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    log_message "Limpieza de Docker completada" "SUCCESS"
}

# Function to check and repair MongoDB
check_mongodb() {
    log_message "Verificando MongoDB..." "INFO"
    
    if ! docker ps | grep -q "mongodb"; then
        log_message "MongoDB no está ejecutándose" "ERROR"
        return 1
    fi
    
    # Run MongoDB repair
    docker-compose exec -T mongodb mongod --repair
    if [ $? -eq 0 ]; then
        log_message "Reparación de MongoDB completada" "SUCCESS"
    else
        log_message "Error en la reparación de MongoDB" "ERROR"
    fi
}

# Function to check application health
check_application_health() {
    log_message "Verificando salud de la aplicación..." "INFO"
    
    # Check API health
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health")
    if [ "$api_status" == "200" ]; then
        log_message "API respondiendo correctamente" "SUCCESS"
    else
        log_message "API no responde correctamente (Status: $api_status)" "ERROR"
    fi
    
    # Check MongoDB connection
    if docker-compose exec -T mongodb mongo --eval "db.stats()" &>/dev/null; then
        log_message "Conexión a MongoDB correcta" "SUCCESS"
    else
        log_message "Error en la conexión a MongoDB" "ERROR"
    fi
}

# Function to optimize MongoDB
optimize_mongodb() {
    log_message "Optimizando MongoDB..." "INFO"
    
    # Compact database
    docker-compose exec -T mongodb mongo admin --eval 'db.runCommand({compact: "event-manager"})'
    
    # Repair database
    docker-compose exec -T mongodb mongo admin --eval 'db.repairDatabase()'
    
    # Update indexes
    docker-compose exec -T mongodb mongo event-manager --eval 'db.getCollectionNames().forEach(function(collection) { db[collection].reIndex() })'
    
    log_message "Optimización de MongoDB completada" "SUCCESS"
}

# Function to check SSL certificates
check_ssl_certificates() {
    log_message "Verificando certificados SSL..." "INFO"
    
    local cert_path="/etc/letsencrypt/live/your-domain.com/fullchain.pem"
    if [ -f "$cert_path" ]; then
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))
        
        if [ $days_left -lt 30 ]; then
            log_message "Certificado SSL expirará en $days_left días" "WARNING"
        else
            log_message "Certificado SSL válido por $days_left días" "SUCCESS"
        fi
    else
        log_message "Certificado SSL no encontrado" "ERROR"
    fi
}

# Function to backup configuration
backup_configuration() {
    log_message "Respaldando archivos de configuración..." "INFO"
    
    local backup_dir="${MAINTENANCE_DIR}/config-backup-${TIMESTAMP}"
    mkdir -p "$backup_dir"
    
    # Backup configuration files
    cp docker-compose*.yml "$backup_dir/"
    cp -r nginx/ "$backup_dir/"
    cp .env* "$backup_dir/" 2>/dev/null
    
    tar -czf "${backup_dir}.tar.gz" "$backup_dir"
    rm -rf "$backup_dir"
    
    log_message "Respaldo de configuración completado: ${backup_dir}.tar.gz" "SUCCESS"
}

# Main execution
echo -e "${BLUE}Iniciando mantenimiento del sistema...${NC}\n"
echo "Reporte de Mantenimiento - $(date)" > "${REPORT_FILE}"
echo "===============================" >> "${REPORT_FILE}"

# Run maintenance tasks
check_disk_space
rotate_logs
clean_docker_resources
check_mongodb
check_application_health
optimize_mongodb
check_ssl_certificates
backup_configuration

# Generate summary
echo -e "\n${BLUE}Generando resumen...${NC}"
echo -e "\nResumen de Mantenimiento" >> "${REPORT_FILE}"
echo -e "======================" >> "${REPORT_FILE}"
echo -e "Fecha: $(date)" >> "${REPORT_FILE}"
echo -e "Espacio en disco liberado: $(du -sh ${LOG_DIR} | cut -f1)" >> "${REPORT_FILE}"
echo -e "Archivos de log rotados: $(find ${LOG_DIR} -type f -name "*.gz" | wc -l)" >> "${REPORT_FILE}"

echo -e "\n${GREEN}Mantenimiento completado.${NC}"
echo -e "Reporte guardado en: ${REPORT_FILE}"

# Make script executable
chmod +x scripts/maintenance.sh

# Usage instructions
echo -e "\n${BLUE}Para programar mantenimiento automático, agregue al crontab:${NC}"
echo "0 3 * * * /path/to/scripts/maintenance.sh > /dev/null 2>&1"
