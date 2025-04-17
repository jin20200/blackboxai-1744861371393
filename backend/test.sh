#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Iniciando pruebas del Sistema de Control de Eventos...${NC}\n"

# Check if Node.js and npm are installed
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: Node.js y npm son requeridos para ejecutar las pruebas.${NC}"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}Instalando dependencias...${NC}"
    npm install
fi

# Run linting if eslint is configured
if [ -f ".eslintrc" ]; then
    echo -e "\n${BLUE}Ejecutando análisis de código...${NC}"
    npm run lint
fi

# Run the tests with coverage
echo -e "\n${BLUE}Ejecutando pruebas con cobertura...${NC}"
npm test -- --coverage

# Check the exit status of the tests
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}¡Todas las pruebas pasaron exitosamente!${NC}"
else
    echo -e "\n${RED}Algunas pruebas fallaron. Por favor revise los errores arriba.${NC}"
    exit 1
fi

# Make the script executable
chmod +x test.sh

echo -e "\n${BLUE}Reporte de cobertura disponible en:${NC} coverage/lcov-report/index.html"
