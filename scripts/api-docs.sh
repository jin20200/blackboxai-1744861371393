#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="./docs/api"
POSTMAN_DIR="./docs/postman"
SWAGGER_DIR="./docs/swagger"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
API_VERSION=$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')

# Create necessary directories
mkdir -p "${DOCS_DIR}" "${POSTMAN_DIR}" "${SWAGGER_DIR}"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}"
}

# Function to generate Swagger/OpenAPI documentation
generate_swagger_docs() {
    log_message "Generando documentación Swagger..." "INFO"
    
    # Generate Swagger JSON
    npx swagger-jsdoc -d swagger.config.js -o "${SWAGGER_DIR}/swagger.json"
    
    if [ $? -ne 0 ]; then
        log_message "Error al generar documentación Swagger" "ERROR"
        return 1
    fi
    
    # Generate HTML documentation
    npx redoc-cli bundle "${SWAGGER_DIR}/swagger.json" \
        --output "${SWAGGER_DIR}/index.html" \
        --title "Event Manager API Documentation" \
        --template "${DOCS_DIR}/template.hbs"
    
    log_message "Documentación Swagger generada exitosamente" "SUCCESS"
    return 0
}

# Function to generate Postman collection
generate_postman_collection() {
    log_message "Generando colección de Postman..." "INFO"
    
    # Convert Swagger to Postman collection
    npx swagger2-postman-generator \
        -s "${SWAGGER_DIR}/swagger.json" \
        -o "${POSTMAN_DIR}/Event_Manager_API_v${API_VERSION}.json" \
        -p "Event Manager API" \
        -v "${API_VERSION}"
    
    if [ $? -ne 0 ]; then
        log_message "Error al generar colección de Postman" "ERROR"
        return 1
    fi
    
    # Create environment files
    for env in development staging production; do
        cat > "${POSTMAN_DIR}/environment_${env}.json" << EOL
{
    "name": "Event Manager ${env^}",
    "values": [
        {
            "key": "baseUrl",
            "value": "https://api-${env}.your-domain.com",
            "enabled": true
        },
        {
            "key": "apiKey",
            "value": "your-api-key",
            "enabled": true
        }
    ]
}
EOL
    done
    
    log_message "Colección de Postman generada exitosamente" "SUCCESS"
    return 0
}

# Function to validate API documentation
validate_api_docs() {
    log_message "Validando documentación de API..." "INFO"
    
    # Validate Swagger documentation
    npx swagger-cli validate "${SWAGGER_DIR}/swagger.json"
    
    if [ $? -ne 0 ]; then
        log_message "Error en la validación de Swagger" "ERROR"
        return 1
    fi
    
    # Check for broken links
    npx broken-link-checker "${SWAGGER_DIR}/index.html" --recursive
    
    log_message "Validación de documentación completada" "SUCCESS"
    return 0
}

# Function to test API endpoints
test_api_endpoints() {
    log_message "Probando endpoints de API..." "INFO"
    
    # Run Newman tests using Postman collection
    npx newman run "${POSTMAN_DIR}/Event_Manager_API_v${API_VERSION}.json" \
        -e "${POSTMAN_DIR}/environment_development.json" \
        --reporters cli,htmlextra \
        --reporter-htmlextra-export "${DOCS_DIR}/test-results/api-test-report-${TIMESTAMP}.html"
    
    if [ $? -ne 0 ]; then
        log_message "Algunas pruebas de API fallaron" "ERROR"
        return 1
    fi
    
    log_message "Pruebas de API completadas exitosamente" "SUCCESS"
    return 0
}

# Function to generate markdown documentation
generate_markdown_docs() {
    log_message "Generando documentación en Markdown..." "INFO"
    
    local md_file="${DOCS_DIR}/API_Documentation.md"
    
    # Generate main documentation
    cat > "$md_file" << EOL
# Event Manager API Documentation

Version: ${API_VERSION}
Generated: $(date)

## Overview

This documentation provides details about the Event Manager API endpoints, authentication, and usage.

## Authentication

The API uses JWT (JSON Web Token) for authentication. Include the token in the Authorization header:

\`\`\`
Authorization: Bearer <your-token>
\`\`\`

## Endpoints

EOL
    
    # Extract endpoints from Swagger and append to markdown
    jq -r '.paths | to_entries[] | "\n### \(.key)\n\n\(.value | to_entries[] | "**\(.key | ascii_upcase)**\n\n\(.value.description)\n\nParameters:\n\(.value.parameters // [] | .[] | "- \(.name): \(.description)")\n")' \
        "${SWAGGER_DIR}/swagger.json" >> "$md_file"
    
    # Add error codes section
    cat >> "$md_file" << EOL

## Error Codes

| Code | Description |
|------|-------------|
| 400  | Bad Request - Invalid parameters |
| 401  | Unauthorized - Authentication required |
| 403  | Forbidden - Insufficient permissions |
| 404  | Not Found - Resource doesn't exist |
| 500  | Internal Server Error |

## Rate Limiting

The API implements rate limiting to prevent abuse. Current limits:

- 100 requests per minute for authenticated users
- 20 requests per minute for unauthenticated users

## Examples

### Authentication

\`\`\`bash
curl -X POST https://api.your-domain.com/auth/login \\
  -H "Content-Type: application/json" \\
  -d '{"username": "user", "password": "pass"}'
\`\`\`

### Create Guest

\`\`\`bash
curl -X POST https://api.your-domain.com/api/guests \\
  -H "Authorization: Bearer <your-token>" \\
  -H "Content-Type: application/json" \\
  -d '{"name": "John Doe", "email": "john@example.com"}'
\`\`\`
EOL
    
    log_message "Documentación Markdown generada exitosamente" "SUCCESS"
    return 0
}

# Function to serve documentation locally
serve_docs() {
    log_message "Iniciando servidor de documentación..." "INFO"
    
    # Start a simple HTTP server
    cd "${SWAGGER_DIR}"
    python3 -m http.server 8000 &
    SERVER_PID=$!
    
    log_message "Documentación disponible en http://localhost:8000" "SUCCESS"
    log_message "Presione Ctrl+C para detener el servidor" "INFO"
    
    # Wait for user interrupt
    trap "kill $SERVER_PID" INT
    wait $SERVER_PID
}

# Function to publish documentation
publish_docs() {
    local env=$1
    log_message "Publicando documentación en ${env}..." "INFO"
    
    case "$env" in
        production)
            # Deploy to production documentation server
            rsync -av --delete "${SWAGGER_DIR}/" "docs.your-domain.com:/var/www/docs/"
            ;;
        staging)
            # Deploy to staging documentation server
            rsync -av --delete "${SWAGGER_DIR}/" "staging-docs.your-domain.com:/var/www/docs/"
            ;;
        *)
            log_message "Ambiente no válido: ${env}" "ERROR"
            return 1
            ;;
    esac
    
    log_message "Documentación publicada exitosamente" "SUCCESS"
    return 0
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/api-docs.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  swagger              Generar documentación Swagger"
    echo -e "  postman              Generar colección Postman"
    echo -e "  validate             Validar documentación"
    echo -e "  test                 Probar endpoints"
    echo -e "  markdown             Generar documentación Markdown"
    echo -e "  serve                Servir documentación localmente"
    echo -e "  publish <env>        Publicar documentación"
}

# Main execution
case "$1" in
    swagger)
        generate_swagger_docs
        ;;
    postman)
        generate_postman_collection
        ;;
    validate)
        validate_api_docs
        ;;
    test)
        test_api_endpoints
        ;;
    markdown)
        generate_markdown_docs
        ;;
    serve)
        serve_docs
        ;;
    publish)
        if [ -z "$2" ]; then
            log_message "Debe especificar el ambiente" "ERROR"
            exit 1
        fi
        publish_docs "$2"
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
chmod +x scripts/api-docs.sh
