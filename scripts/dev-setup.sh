#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MIN_NODE_VERSION="14.0.0"
MIN_NPM_VERSION="6.0.0"
MIN_DOCKER_VERSION="20.10.0"
MIN_DOCKER_COMPOSE_VERSION="1.29.0"

# Function to check version numbers
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    local outdated_deps=()

    echo -e "${BLUE}Verificando dependencias del sistema...${NC}"

    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("Node.js")
    else
        local node_version=$(node -v | cut -d "v" -f 2)
        if version_gt $MIN_NODE_VERSION $node_version; then
            outdated_deps+=("Node.js (actual: $node_version, requerido: $MIN_NODE_VERSION)")
        fi
    fi

    # Check npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        local npm_version=$(npm -v)
        if version_gt $MIN_NPM_VERSION $npm_version; then
            outdated_deps+=("npm (actual: $npm_version, requerido: $MIN_NPM_VERSION)")
        fi
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("Docker")
    else
        local docker_version=$(docker --version | cut -d " " -f 3 | cut -d "," -f 1)
        if version_gt $MIN_DOCKER_VERSION $docker_version; then
            outdated_deps+=("Docker (actual: $docker_version, requerido: $MIN_DOCKER_VERSION)")
        fi
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("Docker Compose")
    else
        local compose_version=$(docker-compose --version | cut -d " " -f 3 | cut -d "," -f 1)
        if version_gt $MIN_DOCKER_COMPOSE_VERSION $compose_version; then
            outdated_deps+=("Docker Compose (actual: $compose_version, requerido: $MIN_DOCKER_COMPOSE_VERSION)")
        fi
    fi

    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("Git")
    fi

    # Report issues
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Dependencias faltantes:${NC}"
        printf '%s\n' "${missing_deps[@]}"
        return 1
    fi

    if [ ${#outdated_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}Dependencias desactualizadas:${NC}"
        printf '%s\n' "${outdated_deps[@]}"
        return 1
    fi

    echo -e "${GREEN}✓ Todas las dependencias están instaladas y actualizadas${NC}"
    return 0
}

# Function to setup development environment
setup_dev_environment() {
    echo -e "\n${BLUE}Configurando entorno de desarrollo...${NC}"

    # Create development environment file
    if [ ! -f ".env.development" ]; then
        echo -e "${BLUE}Creando archivo .env.development...${NC}"
        cat > .env.development << EOL
# Application
NODE_ENV=development
PORT=3000
JWT_SECRET=dev-secret-key-change-this
JWT_EXPIRATION=24h

# MongoDB
MONGO_URI=mongodb://localhost:27017/event-manager
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=devpassword
MONGO_APP_USER=event_manager_app
MONGO_APP_PASSWORD=devpassword

# Logging
LOG_LEVEL=debug
LOG_FORMAT=dev

# Security
CORS_ORIGIN=http://localhost:3000
ALLOWED_HOSTS=localhost

# Development specific
ENABLE_SWAGGER=true
ENABLE_METRICS=true
EOL
        echo -e "${GREEN}✓ Archivo .env.development creado${NC}"
    fi

    # Install backend dependencies
    echo -e "\n${BLUE}Instalando dependencias del backend...${NC}"
    cd backend
    npm install
    cd ..

    # Create development Docker Compose override
    if [ ! -f "docker-compose.override.yml" ]; then
        echo -e "${BLUE}Creando docker-compose.override.yml...${NC}"
        cat > docker-compose.override.yml << EOL
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    volumes:
      - ./backend:/usr/src/app
      - /usr/src/app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev

  mongodb:
    ports:
      - "27017:27017"

  mongo-express:
    image: mongo-express
    ports:
      - "8081:8081"
    environment:
      - ME_CONFIG_MONGODB_ADMINUSERNAME=admin
      - ME_CONFIG_MONGODB_ADMINPASSWORD=devpassword
      - ME_CONFIG_MONGODB_URL=mongodb://admin:devpassword@mongodb:27017/
    depends_on:
      - mongodb
EOL
        echo -e "${GREEN}✓ Archivo docker-compose.override.yml creado${NC}"
    fi

    # Setup Git hooks
    echo -e "\n${BLUE}Configurando Git hooks...${NC}"
    if [ -d ".git" ]; then
        # Create pre-commit hook
        mkdir -p .git/hooks
        cat > .git/hooks/pre-commit << EOL
#!/bin/bash
npm run lint
npm test
EOL
        chmod +x .git/hooks/pre-commit
        echo -e "${GREEN}✓ Git hooks configurados${NC}"
    fi

    # Create VSCode settings
    echo -e "\n${BLUE}Configurando VSCode...${NC}"
    mkdir -p .vscode
    cat > .vscode/settings.json << EOL
{
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true
    },
    "javascript.format.enable": false,
    "eslint.validate": ["javascript"],
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "node_modules": true,
        "coverage": true
    }
}
EOL
    echo -e "${GREEN}✓ Configuración de VSCode creada${NC}"
}

# Function to setup test data
setup_test_data() {
    echo -e "\n${BLUE}Configurando datos de prueba...${NC}"

    # Wait for MongoDB to be ready
    echo -e "Esperando que MongoDB esté listo..."
    sleep 5

    # Initialize test data
    node backend/scripts/init-db.js

    echo -e "${GREEN}✓ Datos de prueba configurados${NC}"
}

# Main execution
echo -e "${BLUE}Iniciando configuración del entorno de desarrollo...${NC}\n"

# Check dependencies
check_dependencies
if [ $? -ne 0 ]; then
    echo -e "${RED}Por favor, instale o actualice las dependencias faltantes antes de continuar.${NC}"
    exit 1
fi

# Setup development environment
setup_dev_environment

# Start development environment
echo -e "\n${BLUE}Iniciando entorno de desarrollo...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# Setup test data
setup_test_data

echo -e "\n${GREEN}¡Configuración completada!${NC}"
echo -e "\nAccesos:"
echo -e "- API: http://localhost:3000"
echo -e "- MongoDB Express: http://localhost:8081"
echo -e "  Usuario: admin"
echo -e "  Contraseña: devpassword"

echo -e "\n${BLUE}Comandos útiles:${NC}"
echo -e "- Iniciar entorno: docker-compose up -d"
echo -e "- Detener entorno: docker-compose down"
echo -e "- Logs: docker-compose logs -f"
echo -e "- Tests: npm test"
echo -e "- Lint: npm run lint"

# Make script executable
chmod +x scripts/dev-setup.sh
