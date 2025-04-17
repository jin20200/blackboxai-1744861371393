#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/backups/mongodb"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="event-manager-backup-${TIMESTAMP}"
RETENTION_DAYS=7
LOG_FILE="/var/log/mongodb-backup.log"

# Load environment variables
if [ -f .env.production ]; then
    source .env.production
else
    echo -e "${RED}Error: Archivo .env.production no encontrado${NC}"
    exit 1
fi

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    echo -e "${message}"
}

# Function to check if MongoDB is running
check_mongodb() {
    if ! docker ps | grep -q "event-manager-mongodb-prod"; then
        log_message "MongoDB no está ejecutándose" "ERROR"
        return 1
    fi
    return 0
}

# Function to create backup directory
create_backup_dir() {
    if [ ! -d "${BACKUP_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
        if [ $? -ne 0 ]; then
            log_message "No se pudo crear el directorio de backup" "ERROR"
            return 1
        fi
    fi
    return 0
}

# Function to perform backup
perform_backup() {
    log_message "Iniciando backup de MongoDB..." "INFO"

    # Create backup using mongodump
    docker-compose -f docker-compose.prod.yml exec -T mongodb \
        mongodump \
        --uri="mongodb://${MONGO_ROOT_USER}:${MONGO_ROOT_PASSWORD}@localhost:27017/event-manager?authSource=admin" \
        --out="/data/db/${BACKUP_NAME}" \
        --gzip

    if [ $? -ne 0 ]; then
        log_message "Error al crear el backup" "ERROR"
        return 1
    fi

    # Copy backup from container to host
    docker cp "$(docker-compose -f docker-compose.prod.yml ps -q mongodb):/data/db/${BACKUP_NAME}" "${BACKUP_DIR}/"
    
    if [ $? -ne 0 ]; then
        log_message "Error al copiar el backup" "ERROR"
        return 1
    fi

    # Create checksum
    cd "${BACKUP_DIR}"
    tar czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
    sha256sum "${BACKUP_NAME}.tar.gz" > "${BACKUP_NAME}.sha256"
    
    # Clean up temporary files
    rm -rf "${BACKUP_NAME}"
    
    log_message "Backup completado exitosamente: ${BACKUP_NAME}.tar.gz" "INFO"
    return 0
}

# Function to rotate old backups
rotate_backups() {
    log_message "Iniciando rotación de backups..." "INFO"
    
    find "${BACKUP_DIR}" -name "event-manager-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_DIR}" -name "event-manager-backup-*.sha256" -type f -mtime +${RETENTION_DAYS} -delete
    
    local deleted=$?
    if [ $deleted -eq 0 ]; then
        log_message "Rotación de backups completada" "INFO"
    else
        log_message "Error en la rotación de backups" "WARNING"
    fi
}

# Function to verify backup
verify_backup() {
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    local checksum_file="${BACKUP_DIR}/${BACKUP_NAME}.sha256"
    
    if [ ! -f "${backup_file}" ] || [ ! -f "${checksum_file}" ]; then
        log_message "Archivos de backup no encontrados" "ERROR"
        return 1
    }
    
    cd "${BACKUP_DIR}"
    if ! sha256sum -c "${BACKUP_NAME}.sha256"; then
        log_message "Verificación de checksum fallida" "ERROR"
        return 1
    fi
    
    log_message "Verificación de backup completada exitosamente" "INFO"
    return 0
}

# Main execution
main() {
    log_message "Iniciando proceso de backup..." "INFO"
    
    # Check MongoDB status
    if ! check_mongodb; then
        exit 1
    fi
    
    # Create backup directory
    if ! create_backup_dir; then
        exit 1
    fi
    
    # Perform backup
    if ! perform_backup; then
        exit 1
    fi
    
    # Verify backup
    if ! verify_backup; then
        exit 1
    fi
    
    # Rotate old backups
    rotate_backups
    
    log_message "Proceso de backup completado exitosamente" "INFO"
    
    # Print backup statistics
    echo -e "\n${GREEN}Estadísticas de backup:${NC}"
    echo -e "Ubicación: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo -e "Tamaño: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
    echo -e "Checksum: $(cat "${BACKUP_DIR}/${BACKUP_NAME}.sha256" | cut -d' ' -f1)"
}

# Execute main function
main

# Make script executable
chmod +x scripts/backup.sh

# Usage instructions
echo -e "\n${BLUE}Para programar backups automáticos, agregue la siguiente línea a crontab:${NC}"
echo "0 2 * * * /path/to/scripts/backup.sh > /dev/null 2>&1"
