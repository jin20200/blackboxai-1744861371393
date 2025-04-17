#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESULTS_DIR="./performance-tests"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/performance-test-${TIMESTAMP}.txt"
API_URL="http://localhost:3000"
TEST_DURATION=60
CONCURRENT_USERS=50

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Function to check dependencies
check_dependencies() {
    echo -e "${BLUE}Verificando dependencias...${NC}"
    
    local missing_deps=()
    
    if ! command -v ab &> /dev/null; then
        missing_deps+=("apache2-utils (para Apache Benchmark)")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Dependencias faltantes:${NC}"
        printf '%s\n' "${missing_deps[@]}"
        echo -e "Instale las dependencias faltantes con:"
        echo -e "sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Todas las dependencias están instaladas${NC}\n"
}

# Function to get JWT token
get_auth_token() {
    echo -e "${BLUE}Obteniendo token de autenticación...${NC}"
    
    local response=$(curl -s -X POST "${API_URL}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin123"}')
    
    local token=$(echo $response | jq -r '.token')
    
    if [ "$token" == "null" ] || [ -z "$token" ]; then
        echo -e "${RED}Error al obtener token de autenticación${NC}"
        exit 1
    fi
    
    echo $token
}

# Function to run performance test
run_performance_test() {
    local endpoint=$1
    local description=$2
    local method=${3:-GET}
    local data=${4:-""}
    local token=${5:-""}
    
    echo -e "\n${BLUE}Ejecutando prueba: $description${NC}"
    echo -e "Endpoint: $endpoint"
    echo -e "Método: $method"
    
    # Create temp file for results
    local temp_file=$(mktemp)
    
    # Prepare headers
    local headers_file=$(mktemp)
    echo "Content-Type: application/json" > $headers_file
    if [ ! -z "$token" ]; then
        echo "Authorization: Bearer $token" >> $headers_file
    fi
    
    # Prepare data file if needed
    local data_file=""
    if [ ! -z "$data" ]; then
        data_file=$(mktemp)
        echo "$data" > $data_file
    fi
    
    # Run Apache Benchmark
    if [ "$method" == "GET" ]; then
        ab -n $((CONCURRENT_USERS * 20)) -c $CONCURRENT_USERS \
           -H "$(cat $headers_file)" \
           -g $temp_file \
           "${API_URL}${endpoint}" > "${RESULTS_DIR}/ab_${TIMESTAMP}_${endpoint//\//_}.txt" 2>&1
    else
        ab -n $((CONCURRENT_USERS * 20)) -c $CONCURRENT_USERS \
           -p $data_file -T "application/json" \
           -H "$(cat $headers_file)" \
           -g $temp_file \
           "${API_URL}${endpoint}" > "${RESULTS_DIR}/ab_${TIMESTAMP}_${endpoint//\//_}.txt" 2>&1
    fi
    
    # Process results
    local results=$(cat "${RESULTS_DIR}/ab_${TIMESTAMP}_${endpoint//\//_}.txt")
    
    # Extract key metrics
    local rps=$(echo "$results" | grep "Requests per second" | awk '{print $4}')
    local mean_time=$(echo "$results" | grep "Time per request" | head -1 | awk '{print $4}')
    local failed_requests=$(echo "$results" | grep "Failed requests:" | awk '{print $3}')
    
    # Log results
    echo -e "\nResultados para $description:" >> "${REPORT_FILE}"
    echo -e "================================" >> "${REPORT_FILE}"
    echo -e "Endpoint: $endpoint" >> "${REPORT_FILE}"
    echo -e "Método: $method" >> "${REPORT_FILE}"
    echo -e "Requests por segundo: $rps" >> "${REPORT_FILE}"
    echo -e "Tiempo medio por request: $mean_time ms" >> "${REPORT_FILE}"
    echo -e "Requests fallidos: $failed_requests" >> "${REPORT_FILE}"
    echo -e "Reporte detallado: ab_${TIMESTAMP}_${endpoint//\//_}.txt\n" >> "${REPORT_FILE}"
    
    # Clean up temp files
    rm -f $temp_file $headers_file
    if [ ! -z "$data_file" ]; then
        rm -f $data_file
    fi
    
    # Print results
    echo -e "${GREEN}Resultados:${NC}"
    echo -e "Requests por segundo: ${GREEN}$rps${NC}"
    echo -e "Tiempo medio por request: ${YELLOW}$mean_time ms${NC}"
    echo -e "Requests fallidos: ${RED}$failed_requests${NC}"
}

# Function to monitor system resources
monitor_resources() {
    echo -e "\n${BLUE}Monitoreando recursos del sistema...${NC}"
    
    # Get initial stats
    local start_time=$(date +%s)
    
    # Monitor for test duration
    while true; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -ge $TEST_DURATION ]; then
            break
        fi
        
        # Get CPU and memory usage
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
        local mem_usage=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
        
        echo "$(date '+%H:%M:%S') CPU: $cpu_usage% MEM: $mem_usage" >> "${RESULTS_DIR}/resources_${TIMESTAMP}.txt"
        sleep 1
    done
}

# Main execution
echo -e "${BLUE}Iniciando pruebas de rendimiento...${NC}\n"
echo "Reporte de Pruebas de Rendimiento - $(date)" > "${REPORT_FILE}"
echo "===========================================" >> "${REPORT_FILE}"

# Check dependencies
check_dependencies

# Get auth token
TOKEN=$(get_auth_token)

# Start resource monitoring in background
monitor_resources &
MONITOR_PID=$!

# Run tests
run_performance_test "/api/health" "Health Check"

run_performance_test "/api/guests" "Lista de Invitados" "GET" "" "$TOKEN"

run_performance_test "/api/guests" "Crear Invitado" "POST" \
    '{"name":"Test Guest","email":"test@example.com","ticketType":"general"}' \
    "$TOKEN"

run_performance_test "/api/guests/stats" "Estadísticas" "GET" "" "$TOKEN"

# Stop resource monitoring
kill $MONITOR_PID

# Process resource monitoring data
echo -e "\n${BLUE}Procesando datos de monitoreo...${NC}"
echo -e "\nEstadísticas de Recursos:" >> "${REPORT_FILE}"
echo -e "========================" >> "${REPORT_FILE}"
echo -e "\nCPU Promedio: $(awk '{sum+=$4} END {print sum/NR}' "${RESULTS_DIR}/resources_${TIMESTAMP}.txt")%" >> "${REPORT_FILE}"
echo -e "Memoria Promedio: $(awk '{sum+=$6} END {print sum/NR}' "${RESULTS_DIR}/resources_${TIMESTAMP}.txt")%" >> "${REPORT_FILE}"

# Generate summary
echo -e "\n${BLUE}Generando resumen...${NC}"
echo -e "\nResumen de Pruebas de Rendimiento" >> "${REPORT_FILE}"
echo -e "================================" >> "${REPORT_FILE}"
echo -e "Duración total: ${TEST_DURATION} segundos" >> "${REPORT_FILE}"
echo -e "Usuarios concurrentes: ${CONCURRENT_USERS}" >> "${REPORT_FILE}"

echo -e "\n${GREEN}Pruebas completadas.${NC}"
echo -e "Reporte completo guardado en: ${REPORT_FILE}"
echo -e "Datos de monitoreo guardados en: ${RESULTS_DIR}/resources_${TIMESTAMP}.txt"

# Make script executable
chmod +x scripts/performance-test.sh

# Usage instructions
echo -e "\n${BLUE}Para ejecutar pruebas de rendimiento:${NC}"
echo -e "./scripts/performance-test.sh"
