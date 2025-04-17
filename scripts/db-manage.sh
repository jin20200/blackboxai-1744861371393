#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MIGRATIONS_DIR="./backend/migrations"
SEEDS_DIR="./backend/seeds"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/migrations"

# Create necessary directories
mkdir -p "${MIGRATIONS_DIR}" "${SEEDS_DIR}" "${BACKUP_DIR}"

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${level}] ${message}"
}

# Function to create a new migration
create_migration() {
    local name=$1
    local filename="${MIGRATIONS_DIR}/${TIMESTAMP}_${name}.js"
    
    cat > "$filename" << EOL
/**
 * Migration: ${name}
 * Timestamp: ${TIMESTAMP}
 */

const mongoose = require('mongoose');

module.exports = {
    up: async function() {
        try {
            // Write your migration code here
            // Example:
            // await mongoose.model('Collection').updateMany({}, { \$set: { newField: 'value' } });
            
        } catch (error) {
            console.error('Migration up error:', error);
            throw error;
        }
    },

    down: async function() {
        try {
            // Write your rollback code here
            // Example:
            // await mongoose.model('Collection').updateMany({}, { \$unset: { newField: '' } });
            
        } catch (error) {
            console.error('Migration down error:', error);
            throw error;
        }
    }
};
EOL

    log_message "Migración creada: ${filename}" "SUCCESS"
}

# Function to create a new seed
create_seed() {
    local name=$1
    local filename="${SEEDS_DIR}/${TIMESTAMP}_${name}.js"
    
    cat > "$filename" << EOL
/**
 * Seed: ${name}
 * Timestamp: ${TIMESTAMP}
 */

const mongoose = require('mongoose');

module.exports = {
    seed: async function() {
        try {
            // Write your seed data here
            // Example:
            // const data = [
            //     { name: 'Test User', email: 'test@example.com' }
            // ];
            // await mongoose.model('Collection').insertMany(data);
            
        } catch (error) {
            console.error('Seed error:', error);
            throw error;
        }
    },

    clear: async function() {
        try {
            // Write your cleanup code here
            // Example:
            // await mongoose.model('Collection').deleteMany({});
            
        } catch (error) {
            console.error('Clear error:', error);
            throw error;
        }
    }
};
EOL

    log_message "Seed creado: ${filename}" "SUCCESS"
}

# Function to run migrations
run_migrations() {
    local direction=$1 # 'up' or 'down'
    local specific_migration=$2
    
    log_message "Ejecutando migraciones (${direction})..." "INFO"
    
    # Create backup before running migrations
    if [ "$direction" == "up" ]; then
        backup_database
    fi
    
    # Get list of migration files
    local migrations=($(ls -1 ${MIGRATIONS_DIR}/*.js | sort))
    
    if [ "$specific_migration" != "" ]; then
        # Run specific migration
        local migration_file="${MIGRATIONS_DIR}/${specific_migration}.js"
        if [ -f "$migration_file" ]; then
            run_single_migration "$migration_file" "$direction"
        else
            log_message "Migración no encontrada: ${specific_migration}" "ERROR"
            return 1
        fi
    else
        # Run all migrations
        if [ "$direction" == "down" ]; then
            # Reverse order for down migrations
            for ((i=${#migrations[@]}-1; i>=0; i--)); do
                run_single_migration "${migrations[i]}" "$direction"
            done
        else
            for migration in "${migrations[@]}"; do
                run_single_migration "$migration" "$direction"
            done
        fi
    fi
}

# Function to run a single migration
run_single_migration() {
    local migration_file=$1
    local direction=$2
    
    log_message "Ejecutando migración: $(basename "$migration_file")" "INFO"
    
    node << EOL
    const migration = require('${migration_file}');
    
    async function runMigration() {
        try {
            await migration.${direction}();
            console.log('Migración completada exitosamente');
        } catch (error) {
            console.error('Error en la migración:', error);
            process.exit(1);
        }
    }
    
    runMigration();
EOL
}

# Function to run seeds
run_seeds() {
    local operation=$1 # 'seed' or 'clear'
    local specific_seed=$2
    
    log_message "Ejecutando seeds (${operation})..." "INFO"
    
    # Get list of seed files
    local seeds=($(ls -1 ${SEEDS_DIR}/*.js | sort))
    
    if [ "$specific_seed" != "" ]; then
        # Run specific seed
        local seed_file="${SEEDS_DIR}/${specific_seed}.js"
        if [ -f "$seed_file" ]; then
            run_single_seed "$seed_file" "$operation"
        else
            log_message "Seed no encontrado: ${specific_seed}" "ERROR"
            return 1
        fi
    else
        # Run all seeds
        for seed in "${seeds[@]}"; do
            run_single_seed "$seed" "$operation"
        done
    fi
}

# Function to run a single seed
run_single_seed() {
    local seed_file=$1
    local operation=$2
    
    log_message "Ejecutando seed: $(basename "$seed_file")" "INFO"
    
    node << EOL
    const seed = require('${seed_file}');
    
    async function runSeed() {
        try {
            await seed.${operation}();
            console.log('Seed completado exitosamente');
        } catch (error) {
            console.error('Error en el seed:', error);
            process.exit(1);
        }
    }
    
    runSeed();
EOL
}

# Function to backup database
backup_database() {
    local backup_file="${BACKUP_DIR}/backup_${TIMESTAMP}.gz"
    
    log_message "Creando backup de la base de datos..." "INFO"
    
    docker-compose exec -T mongodb mongodump --archive --gzip > "$backup_file"
    
    if [ $? -eq 0 ]; then
        log_message "Backup creado: ${backup_file}" "SUCCESS"
    else
        log_message "Error al crear backup" "ERROR"
        exit 1
    fi
}

# Function to restore database
restore_database() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        log_message "Archivo de backup no encontrado: ${backup_file}" "ERROR"
        exit 1
    fi
    
    log_message "Restaurando base de datos desde backup..." "INFO"
    
    docker-compose exec -T mongodb mongorestore --archive --gzip < "$backup_file"
    
    if [ $? -eq 0 ]; then
        log_message "Restauración completada exitosamente" "SUCCESS"
    else
        log_message "Error al restaurar backup" "ERROR"
        exit 1
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/db-manage.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  create-migration <nombre>  Crear nueva migración"
    echo -e "  create-seed <nombre>       Crear nuevo seed"
    echo -e "  migrate-up [nombre]        Ejecutar migraciones (todas o una específica)"
    echo -e "  migrate-down [nombre]      Revertir migraciones (todas o una específica)"
    echo -e "  seed [nombre]              Ejecutar seeds (todos o uno específico)"
    echo -e "  clear-seeds [nombre]       Limpiar datos de seeds"
    echo -e "  backup                     Crear backup de la base de datos"
    echo -e "  restore <archivo>          Restaurar base de datos desde backup"
}

# Main execution
case "$1" in
    create-migration)
        if [ -z "$2" ]; then
            log_message "Debe especificar un nombre para la migración" "ERROR"
            exit 1
        fi
        create_migration "$2"
        ;;
    create-seed)
        if [ -z "$2" ]; then
            log_message "Debe especificar un nombre para el seed" "ERROR"
            exit 1
        fi
        create_seed "$2"
        ;;
    migrate-up)
        run_migrations "up" "$2"
        ;;
    migrate-down)
        run_migrations "down" "$2"
        ;;
    seed)
        run_seeds "seed" "$2"
        ;;
    clear-seeds)
        run_seeds "clear" "$2"
        ;;
    backup)
        backup_database
        ;;
    restore)
        if [ -z "$2" ]; then
            log_message "Debe especificar el archivo de backup" "ERROR"
            exit 1
        fi
        restore_database "$2"
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
chmod +x scripts/db-manage.sh
