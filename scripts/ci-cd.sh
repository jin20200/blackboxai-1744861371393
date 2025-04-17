#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARTIFACTS_DIR="./artifacts"
RELEASE_DIR="./releases"
VERSION=$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')

# Create necessary directories
mkdir -p "${ARTIFACTS_DIR}" "${RELEASE_DIR}"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}"
}

# Function to check code quality
check_code_quality() {
    log_message "Verificando calidad del código..." "INFO"
    
    # Run ESLint
    log_message "Ejecutando ESLint..." "INFO"
    if ! npm run lint; then
        log_message "Errores de ESLint encontrados" "ERROR"
        return 1
    fi
    
    # Run tests with coverage
    log_message "Ejecutando tests..." "INFO"
    if ! npm run test -- --coverage; then
        log_message "Tests fallidos" "ERROR"
        return 1
    fi
    
    # Check test coverage thresholds
    local coverage=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
    if (( $(echo "$coverage < 80" | bc -l) )); then
        log_message "Cobertura de tests insuficiente: ${coverage}%" "ERROR"
        return 1
    fi
    
    log_message "Verificación de calidad completada exitosamente" "SUCCESS"
    return 0
}

# Function to build application
build_application() {
    local env=$1
    log_message "Construyendo aplicación para ${env}..." "INFO"
    
    # Clean previous build
    rm -rf dist/
    
    # Install dependencies
    npm ci
    
    # Build application
    if ! npm run build; then
        log_message "Error en la construcción" "ERROR"
        return 1
    fi
    
    # Create artifact
    local artifact_file="${ARTIFACTS_DIR}/event-manager-${VERSION}-${env}-${TIMESTAMP}.tar.gz"
    tar -czf "$artifact_file" dist/ package.json package-lock.json
    
    log_message "Artifact creado: ${artifact_file}" "SUCCESS"
    return 0
}

# Function to run security checks
security_check() {
    log_message "Ejecutando verificaciones de seguridad..." "INFO"
    
    # Run npm audit
    log_message "Ejecutando npm audit..." "INFO"
    if ! npm audit; then
        log_message "Vulnerabilidades encontradas en dependencias" "WARNING"
    fi
    
    # Run security audit script
    if [ -f "./scripts/security-audit.sh" ]; then
        log_message "Ejecutando auditoría de seguridad..." "INFO"
        if ! ./scripts/security-audit.sh; then
            log_message "Problemas de seguridad encontrados" "ERROR"
            return 1
        fi
    fi
    
    log_message "Verificaciones de seguridad completadas" "SUCCESS"
    return 0
}

# Function to deploy to environment
deploy_to_env() {
    local env=$1
    local version=$2
    log_message "Desplegando versión ${version} a ${env}..." "INFO"
    
    # Validate environment
    case "$env" in
        development|staging|production)
            ;;
        *)
            log_message "Ambiente no válido: ${env}" "ERROR"
            return 1
            ;;
    esac
    
    # Create deployment directory
    local deploy_dir="${RELEASE_DIR}/${env}/${version}"
    mkdir -p "$deploy_dir"
    
    # Extract artifact
    local artifact_file="${ARTIFACTS_DIR}/event-manager-${version}-${env}-*.tar.gz"
    if ! tar -xzf $artifact_file -C "$deploy_dir"; then
        log_message "Error al extraer artifact" "ERROR"
        return 1
    fi
    
    # Run deployment script based on environment
    case "$env" in
        production)
            if ! ./scripts/deploy.sh production; then
                log_message "Error en despliegue a producción" "ERROR"
                return 1
            fi
            ;;
        staging)
            if ! ./scripts/deploy.sh staging; then
                log_message "Error en despliegue a staging" "ERROR"
                return 1
            fi
            ;;
        development)
            if ! ./scripts/deploy.sh development; then
                log_message "Error en despliegue a desarrollo" "ERROR"
                return 1
            fi
            ;;
    esac
    
    log_message "Despliegue completado exitosamente" "SUCCESS"
    return 0
}

# Function to run performance tests
performance_test() {
    log_message "Ejecutando pruebas de rendimiento..." "INFO"
    
    if [ -f "./scripts/performance-test.sh" ]; then
        if ! ./scripts/performance-test.sh; then
            log_message "Pruebas de rendimiento fallidas" "ERROR"
            return 1
        fi
    fi
    
    log_message "Pruebas de rendimiento completadas" "SUCCESS"
    return 0
}

# Function to create release
create_release() {
    local version=$1
    log_message "Creando release ${version}..." "INFO"
    
    # Tag release
    if ! git tag -a "v${version}" -m "Release version ${version}"; then
        log_message "Error al crear tag de release" "ERROR"
        return 1
    fi
    
    # Create release notes
    local release_notes="${RELEASE_DIR}/release-notes-${version}.md"
    echo "# Release Notes v${version}" > "$release_notes"
    echo "## Changes" >> "$release_notes"
    git log $(git describe --tags --abbrev=0 HEAD^)..HEAD --pretty=format:"* %s" >> "$release_notes"
    
    log_message "Release creado exitosamente" "SUCCESS"
    return 0
}

# Function to rollback deployment
rollback_deployment() {
    local env=$1
    local version=$2
    log_message "Iniciando rollback a versión ${version} en ${env}..." "INFO"
    
    # Verify previous version exists
    local previous_deploy="${RELEASE_DIR}/${env}/${version}"
    if [ ! -d "$previous_deploy" ]; then
        log_message "Versión anterior no encontrada" "ERROR"
        return 1
    fi
    
    # Execute rollback
    case "$env" in
        production)
            if ! ./scripts/deploy.sh production rollback "$version"; then
                log_message "Error en rollback a producción" "ERROR"
                return 1
            fi
            ;;
        staging)
            if ! ./scripts/deploy.sh staging rollback "$version"; then
                log_message "Error en rollback a staging" "ERROR"
                return 1
            fi
            ;;
    esac
    
    log_message "Rollback completado exitosamente" "SUCCESS"
    return 0
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/ci-cd.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  quality              Verificar calidad del código"
    echo -e "  build <env>         Construir aplicación para un ambiente"
    echo -e "  security            Ejecutar verificaciones de seguridad"
    echo -e "  deploy <env> <ver>  Desplegar a un ambiente"
    echo -e "  performance         Ejecutar pruebas de rendimiento"
    echo -e "  release <ver>       Crear un release"
    echo -e "  rollback <env> <ver> Realizar rollback a versión anterior"
}

# Main execution
case "$1" in
    quality)
        check_code_quality
        ;;
    build)
        if [ -z "$2" ]; then
            log_message "Debe especificar el ambiente" "ERROR"
            exit 1
        fi
        build_application "$2"
        ;;
    security)
        security_check
        ;;
    deploy)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Debe especificar ambiente y versión" "ERROR"
            exit 1
        fi
        deploy_to_env "$2" "$3"
        ;;
    performance)
        performance_test
        ;;
    release)
        if [ -z "$2" ]; then
            log_message "Debe especificar la versión" "ERROR"
            exit 1
        fi
        create_release "$2"
        ;;
    rollback)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Debe especificar ambiente y versión" "ERROR"
            exit 1
        fi
        rollback_deployment "$2" "$3"
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
chmod +x scripts/ci-cd.sh
