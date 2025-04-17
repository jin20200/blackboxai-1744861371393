#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="./logs"
REPORTS_DIR="./reports"
ARCHIVE_DIR="./logs/archive"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MAX_LOG_SIZE="100M"
LOG_RETENTION_DAYS=30

# Create necessary directories
mkdir -p "${LOG_DIR}" "${REPORTS_DIR}" "${ARCHIVE_DIR}"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}"
}

# Function to analyze logs
analyze_logs() {
    local start_date=$1
    local end_date=$2
    local report_file="${REPORTS_DIR}/log_analysis_${TIMESTAMP}.txt"
    
    log_message "Analizando logs..." "INFO"
    
    echo "Reporte de Análisis de Logs" > "$report_file"
    echo "=========================" >> "$report_file"
    echo "Período: ${start_date} a ${end_date}" >> "$report_file"
    echo "" >> "$report_file"
    
    # Analyze API errors
    echo "Errores de API" >> "$report_file"
    echo "-------------" >> "$report_file"
    grep "ERROR" "${LOG_DIR}/api.log" | \
    awk -v sd="$start_date" -v ed="$end_date" '$0 >= sd && $0 <= ed' | \
    sort | uniq -c | sort -nr >> "$report_file"
    
    # Analyze authentication attempts
    echo -e "\nIntentos de Autenticación" >> "$report_file"
    echo "------------------------" >> "$report_file"
    grep "login" "${LOG_DIR}/auth.log" | \
    awk -v sd="$start_date" -v ed="$end_date" '$0 >= sd && $0 <= ed' | \
    sort | uniq -c | sort -nr >> "$report_file"
    
    # Analyze guest entries
    echo -e "\nEntradas de Invitados" >> "$report_file"
    echo "-------------------" >> "$report_file"
    grep "entry" "${LOG_DIR}/guest.log" | \
    awk -v sd="$start_date" -v ed="$end_date" '$0 >= sd && $0 <= ed' | \
    sort | uniq -c | sort -nr >> "$report_file"
    
    # Generate statistics
    echo -e "\nEstadísticas Generales" >> "$report_file"
    echo "--------------------" >> "$report_file"
    echo "Total errores: $(grep -c "ERROR" ${LOG_DIR}/*.log)" >> "$report_file"
    echo "Total advertencias: $(grep -c "WARNING" ${LOG_DIR}/*.log)" >> "$report_file"
    echo "Total entradas exitosas: $(grep -c "entry successful" ${LOG_DIR}/guest.log)" >> "$report_file"
    
    log_message "Reporte generado: ${report_file}" "SUCCESS"
}

# Function to rotate logs
rotate_logs() {
    log_message "Rotando logs..." "INFO"
    
    for log_file in ${LOG_DIR}/*.log; do
        if [ -f "$log_file" ]; then
            local file_size=$(du -b "$log_file" | cut -f1)
            local max_size_bytes=$((1024*1024*100)) # 100MB in bytes
            
            if [ $file_size -gt $max_size_bytes ]; then
                local rotated_file="${log_file}.${TIMESTAMP}.gz"
                gzip -c "$log_file" > "$rotated_file"
                truncate -s 0 "$log_file"
                log_message "Log rotado: ${rotated_file}" "SUCCESS"
            fi
        fi
    done
}

# Function to archive old logs
archive_logs() {
    log_message "Archivando logs antiguos..." "INFO"
    
    find "${LOG_DIR}" -name "*.log.*" -type f -mtime +${LOG_RETENTION_DAYS} -exec mv {} "${ARCHIVE_DIR}/" \;
    
    # Compress archive directory if it's getting too large
    local archive_size=$(du -s "${ARCHIVE_DIR}" | cut -f1)
    if [ $archive_size -gt $((1024*1024)) ]; then # 1GB in KB
        local archive_file="${ARCHIVE_DIR}/logs_${TIMESTAMP}.tar.gz"
        tar -czf "$archive_file" -C "${ARCHIVE_DIR}" .
        rm "${ARCHIVE_DIR}"/*.log.*
        log_message "Logs archivados en: ${archive_file}" "SUCCESS"
    fi
}

# Function to generate error report
generate_error_report() {
    local report_file="${REPORTS_DIR}/error_report_${TIMESTAMP}.txt"
    
    log_message "Generando reporte de errores..." "INFO"
    
    echo "Reporte de Errores" > "$report_file"
    echo "=================" >> "$report_file"
    echo "Fecha: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Collect errors from all logs
    echo "Errores Críticos" >> "$report_file"
    echo "---------------" >> "$report_file"
    grep "ERROR" ${LOG_DIR}/*.log | tail -n 100 >> "$report_file"
    
    # Add error statistics
    echo -e "\nEstadísticas de Errores" >> "$report_file"
    echo "---------------------" >> "$report_file"
    for log_file in ${LOG_DIR}/*.log; do
        echo "$(basename "$log_file"): $(grep -c "ERROR" "$log_file") errores" >> "$report_file"
    done
    
    log_message "Reporte de errores generado: ${report_file}" "SUCCESS"
}

# Function to generate access report
generate_access_report() {
    local report_file="${REPORTS_DIR}/access_report_${TIMESTAMP}.txt"
    
    log_message "Generando reporte de accesos..." "INFO"
    
    echo "Reporte de Accesos" > "$report_file"
    echo "=================" >> "$report_file"
    echo "Fecha: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Analyze API access patterns
    echo "Patrones de Acceso API" >> "$report_file"
    echo "-------------------" >> "$report_file"
    grep "GET\|POST\|PUT\|DELETE" "${LOG_DIR}/api.log" | \
    awk '{print $6, $7}' | sort | uniq -c | sort -nr >> "$report_file"
    
    # Analyze user sessions
    echo -e "\nSesiones de Usuario" >> "$report_file"
    echo "-----------------" >> "$report_file"
    grep "session" "${LOG_DIR}/auth.log" | \
    awk '{print $4, $5}' | sort | uniq -c >> "$report_file"
    
    log_message "Reporte de accesos generado: ${report_file}" "SUCCESS"
}

# Function to clean old reports
clean_old_reports() {
    log_message "Limpiando reportes antiguos..." "INFO"
    
    find "${REPORTS_DIR}" -name "*.txt" -type f -mtime +${LOG_RETENTION_DAYS} -delete
    find "${REPORTS_DIR}" -name "*.gz" -type f -mtime +$((LOG_RETENTION_DAYS * 2)) -delete
    
    log_message "Limpieza de reportes completada" "SUCCESS"
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/log-manager.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  analyze <fecha-inicio> <fecha-fin>  Analizar logs en un período"
    echo -e "  rotate                              Rotar logs actuales"
    echo -e "  archive                             Archivar logs antiguos"
    echo -e "  error-report                        Generar reporte de errores"
    echo -e "  access-report                       Generar reporte de accesos"
    echo -e "  clean                               Limpiar reportes antiguos"
}

# Main execution
case "$1" in
    analyze)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Debe especificar fecha de inicio y fin" "ERROR"
            exit 1
        fi
        analyze_logs "$2" "$3"
        ;;
    rotate)
        rotate_logs
        ;;
    archive)
        archive_logs
        ;;
    error-report)
        generate_error_report
        ;;
    access-report)
        generate_access_report
        ;;
    clean)
        clean_old_reports
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
chmod +x scripts/log-manager.sh
