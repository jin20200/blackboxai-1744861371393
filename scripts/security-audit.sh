#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AUDIT_DIR="./security-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${AUDIT_DIR}/security-audit-${TIMESTAMP}.txt"
CRITICAL_ISSUES=0
WARNING_ISSUES=0

# Create audit directory
mkdir -p "${AUDIT_DIR}"

# Function to log findings
log_finding() {
    local level=$1
    local message=$2
    local details=$3
    
    echo -e "\n[$level] $message" >> "${REPORT_FILE}"
    echo -e "$details" >> "${REPORT_FILE}"
    
    if [ "$level" == "CRITICAL" ]; then
        ((CRITICAL_ISSUES++))
        echo -e "${RED}[CRITICAL] $message${NC}"
    elif [ "$level" == "WARNING" ]; then
        ((WARNING_ISSUES++))
        echo -e "${YELLOW}[WARNING] $message${NC}"
    else
        echo -e "${BLUE}[INFO] $message${NC}"
    fi
}

echo -e "${BLUE}Iniciando auditoría de seguridad...${NC}"
echo "Reporte de Auditoría de Seguridad - $(date)" > "${REPORT_FILE}"
echo "==========================================" >> "${REPORT_FILE}"

# Check environment files
echo -e "\n${BLUE}Verificando archivos de entorno...${NC}"
if [ -f ".env" ]; then
    log_finding "WARNING" "Archivo .env encontrado en el repositorio" "Considere agregar .env al .gitignore"
fi

if [ -f ".env.production" ]; then
    if grep -q "SECRET.*=.*[A-Za-z0-9]" ".env.production"; then
        log_finding "CRITICAL" "Secretos encontrados en .env.production" "Los secretos no deben estar en control de versiones"
    fi
fi

# Check dependencies for vulnerabilities
echo -e "\n${BLUE}Verificando dependencias...${NC}"
if command -v npm &> /dev/null; then
    echo "Ejecutando npm audit..." >> "${REPORT_FILE}"
    npm audit --json >> "${REPORT_FILE}" 2>&1
    if [ $? -ne 0 ]; then
        log_finding "WARNING" "Vulnerabilidades encontradas en dependencias" "Ver reporte completo para detalles"
    fi
fi

# Check Docker security
echo -e "\n${BLUE}Verificando configuración de Docker...${NC}"

# Check Dockerfile
if [ -f "Dockerfile" ]; then
    if ! grep -q "USER" "Dockerfile"; then
        log_finding "WARNING" "No se especifica usuario no-root en Dockerfile" "Considere agregar 'USER node' o similar"
    fi
    
    if grep -q "npm install" "Dockerfile" && ! grep -q "npm ci" "Dockerfile"; then
        log_finding "WARNING" "Usar 'npm ci' en lugar de 'npm install' para producción" "npm ci es más seguro y reproducible"
    fi
fi

# Check docker-compose files
for compose_file in docker-compose*.yml; do
    if [ -f "$compose_file" ]; then
        if grep -q "privileged: true" "$compose_file"; then
            log_finding "CRITICAL" "Contenedor privilegiado encontrado en $compose_file" "Evite usar contenedores privilegiados"
        fi
    fi
done

# Check MongoDB security
echo -e "\n${BLUE}Verificando seguridad de MongoDB...${NC}"
if docker-compose ps | grep -q "mongodb"; then
    if ! docker-compose exec -T mongodb mongo --eval "db.auth" &> /dev/null; then
        log_finding "CRITICAL" "MongoDB no tiene autenticación habilitada" "Habilite la autenticación en MongoDB"
    fi
fi

# Check API security headers
echo -e "\n${BLUE}Verificando headers de seguridad...${NC}"
if [ -f "nginx/conf.d/default.conf" ]; then
    if ! grep -q "X-Frame-Options" "nginx/conf.d/default.conf"; then
        log_finding "WARNING" "Header X-Frame-Options no configurado" "Agregue X-Frame-Options para prevenir clickjacking"
    fi
    if ! grep -q "X-Content-Type-Options" "nginx/conf.d/default.conf"; then
        log_finding "WARNING" "Header X-Content-Type-Options no configurado" "Agregue X-Content-Type-Options: nosniff"
    fi
fi

# Check SSL/TLS configuration
echo -e "\n${BLUE}Verificando configuración SSL/TLS...${NC}"
if [ -f "nginx/conf.d/default.conf" ]; then
    if ! grep -q "ssl_protocols TLSv1.2 TLSv1.3" "nginx/conf.d/default.conf"; then
        log_finding "WARNING" "Versiones antiguas de SSL/TLS pueden estar habilitadas" "Use solo TLS 1.2 y 1.3"
    fi
fi

# Check for sensitive files
echo -e "\n${BLUE}Buscando archivos sensibles...${NC}"
sensitive_files=$(find . -type f -name "*.key" -o -name "*.pem" -o -name "*.crt" -o -name "*.p12" 2>/dev/null)
if [ ! -z "$sensitive_files" ]; then
    log_finding "CRITICAL" "Archivos sensibles encontrados en el repositorio" "$sensitive_files"
fi

# Check Node.js security configuration
echo -e "\n${BLUE}Verificando configuración de seguridad de Node.js...${NC}"
if [ -f "backend/package.json" ]; then
    if ! grep -q "helmet" "backend/package.json"; then
        log_finding "WARNING" "Helmet no está instalado" "Instale helmet para mejorar la seguridad de la API"
    fi
fi

# Generate summary
echo -e "\n${BLUE}Generando resumen...${NC}"
echo -e "\nResumen de la Auditoría" >> "${REPORT_FILE}"
echo -e "====================" >> "${REPORT_FILE}"
echo -e "Problemas críticos: ${CRITICAL_ISSUES}" >> "${REPORT_FILE}"
echo -e "Advertencias: ${WARNING_ISSUES}" >> "${REPORT_FILE}"

echo -e "\n${GREEN}Auditoría completada.${NC}"
echo -e "Problemas críticos: ${RED}${CRITICAL_ISSUES}${NC}"
echo -e "Advertencias: ${YELLOW}${WARNING_ISSUES}${NC}"
echo -e "Reporte completo guardado en: ${REPORT_FILE}"

# Recomendaciones
echo -e "\n${BLUE}Recomendaciones generales:${NC}"
echo -e "1. Revise y corrija todos los problemas críticos inmediatamente"
echo -e "2. Programe auditorías regulares de seguridad"
echo -e "3. Mantenga todas las dependencias actualizadas"
echo -e "4. Implemente monitoreo de seguridad continuo"
echo -e "5. Realice copias de seguridad regulares"
echo -e "6. Documente todos los cambios de seguridad"

# Make script executable
chmod +x scripts/security-audit.sh
