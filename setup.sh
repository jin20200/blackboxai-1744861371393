#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Iniciando configuración del Sistema de Control de Eventos...${NC}\n"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js no está instalado. Por favor, instale Node.js para continuar.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm no está instalado. Por favor, instale npm para continuar.${NC}"
    exit 1
fi

# Create necessary directories if they don't exist
echo -e "${BLUE}Creando estructura de directorios...${NC}"
mkdir -p backend/node_modules

# Install backend dependencies
echo -e "${BLUE}Instalando dependencias del backend...${NC}"
cd backend
npm install

# Initialize database
echo -e "${BLUE}Inicializando base de datos...${NC}"
node scripts/init-db.js

# Return to root directory
cd ..

echo -e "${GREEN}¡Instalación completada!${NC}"
echo -e "\nPara iniciar la aplicación:"
echo -e "1. cd backend"
echo -e "2. npm run dev"
echo -e "\nCredenciales iniciales:"
echo -e "Usuario: admin"
echo -e "Contraseña: admin123"
echo -e "\n${RED}¡IMPORTANTE! Cambie la contraseña después del primer inicio de sesión${NC}"

# Make the script executable
chmod +x setup.sh

echo -e "\n${BLUE}La aplicación estará disponible en:${NC} http://localhost:3000"
