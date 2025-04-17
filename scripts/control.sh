#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./logs/control-${TIMESTAMP}.log"
SCRIPTS_DIR="./scripts"

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to check script existence
check_script() {
    local script=$1
    if [ ! -f "${SCRIPTS_DIR}/${script}.sh" ]; then
        log_message "Script ${script}.sh no encontrado" "ERROR"
        return 1
    fi
    return 0
}

# Function to execute script with parameters
execute_script() {
    local script=$1
    shift
    local params=$@
    
    if check_script "$script"; then
        log_message "Ejecutando ${script}.sh ${params}..." "INFO"
        bash "${SCRIPTS_DIR}/${script}.sh" $params
        
        if [ $? -eq 0 ]; then
            log_message "Ejecución de ${script}.sh completada exitosamente" "SUCCESS"
            return 0
        else
            log_message "Error en la ejecución de ${script}.sh" "ERROR"
            return 1
        fi
    fi
}

# Function to show script status
show_status() {
    log_message "Verificando estado del sistema..." "INFO"
    
    echo -e "\n${BLUE}Estado del Sistema${NC}"
    echo "===================="
    
    # Check services status
    echo -e "\n${BLUE}Servicios:${NC}"
    docker-compose ps
    
    # Check disk usage
    echo -e "\n${BLUE}Uso de Disco:${NC}"
    df -h /
    
    # Check memory usage
    echo -e "\n${BLUE}Uso de Memoria:${NC}"
    free -h
    
    # Check running processes
    echo -e "\n${BLUE}Procesos:${NC}"
    docker-compose top
    
    # Check logs for errors
    echo -e "\n${BLUE}Últimos Errores:${NC}"
    find ./logs -type f -name "*.log" -exec grep -l "ERROR" {} \; | while read log; do
        echo "Archivo: $log"
        tail -n 5 "$log" | grep "ERROR"
    done
}

# Function to show available scripts
list_scripts() {
    echo -e "\n${BLUE}Scripts Disponibles:${NC}"
    echo "=================="
    
    for script in "${SCRIPTS_DIR}"/*.sh; do
        if [ "$(basename "$script")" != "control.sh" ]; then
            echo -e "\n${YELLOW}$(basename "$script" .sh)${NC}"
            # Extract and show script description
            head -n 20 "$script" | grep -i "description" || echo "No description available"
        fi
    done
}

# Function to manage development environment
manage_dev() {
    local action=$1
    
    case "$action" in
        start)
            execute_script "dev-setup"
            ;;
        stop)
            docker-compose down
            ;;
        restart)
            docker-compose down
            execute_script "dev-setup"
            ;;
        update)
            git pull
            execute_script "dev-setup"
            ;;
        *)
            log_message "Acción de desarrollo no válida" "ERROR"
            return 1
            ;;
    esac
}

# Function to manage production environment
manage_prod() {
    local action=$1
    
    case "$action" in
        deploy)
            execute_script "deploy"
            ;;
        rollback)
            execute_script "deploy" "rollback"
            ;;
        status)
            execute_script "scale-manager" "health"
            ;;
        scale)
            execute_script "scale-manager" "scale" "$2" "$3"
            ;;
        *)
            log_message "Acción de producción no válida" "ERROR"
            return 1
            ;;
    esac
}

# Function to manage maintenance tasks
manage_maintenance() {
    local action=$1
    
    case "$action" in
        backup)
            execute_script "backup"
            ;;
        cleanup)
            execute_script "cleanup" "all"
            ;;
        logs)
            execute_script "log-manager" "$2"
            ;;
        security)
            execute_script "security-audit"
            ;;
        performance)
            execute_script "performance-test"
            ;;
        *)
            log_message "Acción de mantenimiento no válida" "ERROR"
            return 1
            ;;
    esac
}

# Function to manage monitoring
manage_monitoring() {
    local action=$1
    
    case "$action" in
        start)
            execute_script "setup-monitoring"
            ;;
        status)
            curl -s http://localhost:9090/-/healthy || echo "Prometheus no responde"
            curl -s http://localhost:3001/api/health || echo "Grafana no responde"
            ;;
        alerts)
            execute_script "notify-manager" "alert" "$2" "$3"
            ;;
        report)
            execute_script "notify-manager" "report"
            ;;
        *)
            log_message "Acción de monitoreo no válida" "ERROR"
            return 1
            ;;
    esac
}

# Function to manage database
manage_database() {
    local action=$1
    
    case "$action" in
        migrate)
            execute_script "db-manage" "migrate-up"
            ;;
        rollback)
            execute_script "db-manage" "migrate-down"
            ;;
        seed)
            execute_script "db-manage" "seed"
            ;;
        backup)
            execute_script "backup"
            ;;
        *)
            log_message "Acción de base de datos no válida" "ERROR"
            return 1
            ;;
    esac
}

# Show help
show_help() {
    echo -e "${BLUE}Control Central del Sistema${NC}"
    echo -e "========================\n"
    echo -e "Uso: ./scripts/control.sh <categoría> <acción> [opciones]\n"
    
    echo -e "${BLUE}Categorías:${NC}"
    echo -e "  dev         Gestionar entorno de desarrollo"
    echo -e "  prod        Gestionar entorno de producción"
    echo -e "  maint       Ejecutar tareas de mantenimiento"
    echo -e "  monitor     Gestionar monitoreo"
    echo -e "  db          Gestionar base de datos"
    echo -e "  status      Mostrar estado del sistema"
    echo -e "  list        Listar scripts disponibles"
    
    echo -e "\n${BLUE}Ejemplos:${NC}"
    echo -e "  ./scripts/control.sh dev start"
    echo -e "  ./scripts/control.sh prod deploy"
    echo -e "  ./scripts/control.sh maint backup"
    echo -e "  ./scripts/control.sh monitor status"
    echo -e "  ./scripts/control.sh db migrate"
}

# Main execution
case "$1" in
    dev)
        manage_dev "$2"
        ;;
    prod)
        manage_prod "$2" "$3" "$4"
        ;;
    maint)
        manage_maintenance "$2" "$3"
        ;;
    monitor)
        manage_monitoring "$2" "$3" "$4"
        ;;
    db)
        manage_database "$2"
        ;;
    status)
        show_status
        ;;
    list)
        list_scripts
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
chmod +x scripts/control.sh
