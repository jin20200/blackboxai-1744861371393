#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./logs/cleanup-${TIMESTAMP}.log"
TEMP_DIR="./temp"
DISK_THRESHOLD=80
DOCKER_IMAGE_AGE=30 # days
LOG_RETENTION=30 # days
BACKUP_RETENTION=90 # days

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")" "$TEMP_DIR"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to check disk space
check_disk_space() {
    log_message "Verificando espacio en disco..." "INFO"
    
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_message "Uso de disco crítico: ${disk_usage}%" "WARNING"
        return 1
    fi
    
    log_message "Uso de disco normal: ${disk_usage}%" "SUCCESS"
    return 0
}

# Function to clean Docker resources
clean_docker() {
    log_message "Limpiando recursos de Docker..." "INFO"
    
    # Stop and remove unused containers
    log_message "Eliminando contenedores no utilizados..." "INFO"
    docker container prune -f
    
    # Remove unused images older than specified days
    log_message "Eliminando imágenes antiguas..." "INFO"
    docker images -q | while read -r image_id; do
        created=$(docker image inspect "$image_id" --format '{{.Created}}')
        created_ts=$(date -d "$created" +%s)
        now_ts=$(date +%s)
        age_days=$(( (now_ts - created_ts) / 86400 ))
        
        if [ "$age_days" -gt "$DOCKER_IMAGE_AGE" ]; then
            docker rmi "$image_id" 2>/dev/null || true
        fi
    done
    
    # Remove unused volumes
    log_message "Eliminando volúmenes no utilizados..." "INFO"
    docker volume prune -f
    
    # Remove unused networks
    log_message "Eliminando redes no utilizadas..." "INFO"
    docker network prune -f
    
    # Clean Docker build cache
    log_message "Limpiando caché de construcción..." "INFO"
    docker builder prune -f --keep-storage 10GB
    
    log_message "Limpieza de Docker completada" "SUCCESS"
}

# Function to clean temporary files
clean_temp_files() {
    log_message "Limpiando archivos temporales..." "INFO"
    
    # Clean temp directory
    find "$TEMP_DIR" -type f -mtime +1 -delete
    
    # Clean npm cache
    npm cache clean --force
    
    # Clean yarn cache if exists
    if command -v yarn &> /dev/null; then
        yarn cache clean
    fi
    
    # Clean system temp files
    find /tmp -type f -atime +1 -delete 2>/dev/null || true
    
    log_message "Limpieza de archivos temporales completada" "SUCCESS"
}

# Function to clean log files
clean_logs() {
    log_message "Limpiando archivos de log..." "INFO"
    
    # Compress old logs
    find ./logs -type f -name "*.log" -mtime +7 -exec gzip {} \;
    
    # Remove old compressed logs
    find ./logs -type f -name "*.log.gz" -mtime +"$LOG_RETENTION" -delete
    
    # Clean npm logs
    rm -f ~/.npm/_logs/*.log
    
    # Clean Docker container logs
    if [ -d "/var/lib/docker/containers" ]; then
        find /var/lib/docker/containers -type f -name "*.log" -exec truncate -s 0 {} \;
    fi
    
    log_message "Limpieza de logs completada" "SUCCESS"
}

# Function to clean old backups
clean_backups() {
    log_message "Limpiando backups antiguos..." "INFO"
    
    # Remove old database backups
    find ./backups/mongodb -type f -mtime +"$BACKUP_RETENTION" -delete
    
    # Remove old configuration backups
    find ./backups/config -type f -mtime +"$BACKUP_RETENTION" -delete
    
    # Remove old log backups
    find ./backups/logs -type f -mtime +"$BACKUP_RETENTION" -delete
    
    log_message "Limpieza de backups completada" "SUCCESS"
}

# Function to clean old artifacts
clean_artifacts() {
    log_message "Limpiando artifacts antiguos..." "INFO"
    
    # Clean old build artifacts
    find ./dist -type f -mtime +7 -delete 2>/dev/null || true
    find ./build -type f -mtime +7 -delete 2>/dev/null || true
    
    # Clean old test reports
    find ./coverage -type f -mtime +7 -delete 2>/dev/null || true
    find ./reports -type f -mtime +7 -delete 2>/dev/null || true
    
    # Clean old documentation builds
    find ./docs/api -type f -mtime +7 -delete 2>/dev/null || true
    
    log_message "Limpieza de artifacts completada" "SUCCESS"
}

# Function to clean database
clean_database() {
    log_message "Limpiando base de datos..." "INFO"
    
    # Connect to MongoDB and clean old data
    docker-compose exec -T mongodb mongo --eval '
        db.getSiblingDB("event-manager").guests.deleteMany({
            createdAt: {
                $lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
            },
            status: "completed"
        });
        db.getSiblingDB("event-manager").logs.deleteMany({
            timestamp: {
                $lt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
            }
        });
    '
    
    log_message "Limpieza de base de datos completada" "SUCCESS"
}

# Function to clean node_modules
clean_node_modules() {
    log_message "Limpiando node_modules..." "INFO"
    
    # Remove node_modules directories
    find . -name "node_modules" -type d -prune -exec rm -rf {} \;
    
    # Reinstall dependencies
    npm ci
    
    log_message "Limpieza de node_modules completada" "SUCCESS"
}

# Function to generate cleanup report
generate_report() {
    local report_file="./reports/cleanup-report-${TIMESTAMP}.txt"
    
    log_message "Generando reporte de limpieza..." "INFO"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOL
Reporte de Limpieza del Sistema
==============================
Fecha: $(date)

Espacio en Disco
---------------
Antes: ${initial_disk_usage}%
Después: $(df -h / | awk 'NR==2 {print $5}')

Recursos Limpiados
-----------------
- Contenedores Docker eliminados: $(docker ps -aq | wc -l)
- Imágenes Docker eliminadas: $(docker images -q | wc -l)
- Archivos temporales eliminados: $(find "$TEMP_DIR" -type f -mtime +1 | wc -l)
- Logs antiguos eliminados: $(find ./logs -type f -name "*.log.gz" -mtime +"$LOG_RETENTION" | wc -l)
- Backups antiguos eliminados: $(find ./backups -type f -mtime +"$BACKUP_RETENTION" | wc -l)

Estado del Sistema
----------------
$(free -h)

EOL
    
    log_message "Reporte generado: ${report_file}" "SUCCESS"
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/cleanup.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  all                  Ejecutar todas las limpiezas"
    echo -e "  docker              Limpiar recursos Docker"
    echo -e "  temp                Limpiar archivos temporales"
    echo -e "  logs                Limpiar logs"
    echo -e "  backups             Limpiar backups antiguos"
    echo -e "  artifacts           Limpiar artifacts"
    echo -e "  database            Limpiar datos antiguos de la base de datos"
    echo -e "  node_modules        Limpiar y reinstalar node_modules"
}

# Main execution
initial_disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

case "$1" in
    all)
        check_disk_space
        clean_docker
        clean_temp_files
        clean_logs
        clean_backups
        clean_artifacts
        clean_database
        clean_node_modules
        generate_report
        ;;
    docker)
        clean_docker
        ;;
    temp)
        clean_temp_files
        ;;
    logs)
        clean_logs
        ;;
    backups)
        clean_backups
        ;;
    artifacts)
        clean_artifacts
        ;;
    database)
        clean_database
        ;;
    node_modules)
        clean_node_modules
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
chmod +x scripts/cleanup.sh
