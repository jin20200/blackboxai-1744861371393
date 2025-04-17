#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./logs/notifications-${TIMESTAMP}.log"
CONFIG_DIR="./config/notifications"
TEMPLATE_DIR="./templates/notifications"

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")" "$CONFIG_DIR" "$TEMPLATE_DIR"

# Load configuration if exists
if [ -f "${CONFIG_DIR}/config.env" ]; then
    source "${CONFIG_DIR}/config.env"
else
    # Default configuration
    SMTP_HOST="smtp.gmail.com"
    SMTP_PORT="587"
    SMTP_USER="your-email@gmail.com"
    SMTP_PASS="your-app-password"
    SLACK_WEBHOOK="https://hooks.slack.com/services/your/webhook/url"
    TELEGRAM_BOT_TOKEN="your-bot-token"
    TELEGRAM_CHAT_ID="your-chat-id"
    SMS_API_KEY="your-sms-api-key"
    SMS_FROM="EventManager"
fi

# Function to log messages
log_message() {
    local message=$1
    local level=${2:-INFO}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to send email
send_email() {
    local to=$1
    local subject=$2
    local body=$3
    local attachment=${4:-""}
    
    log_message "Enviando email a $to..." "INFO"
    
    # Prepare email content
    local email_content="Subject: $subject\nFrom: $SMTP_USER\nTo: $to\nMIME-Version: 1.0\nContent-Type: text/html\n\n$body"
    
    # Send email using curl
    if [ -n "$attachment" ]; then
        curl --url "smtp://${SMTP_HOST}:${SMTP_PORT}" \
            --ssl-reqd \
            --mail-from "$SMTP_USER" \
            --mail-rcpt "$to" \
            --upload-file "$attachment" \
            --user "$SMTP_USER:$SMTP_PASS"
    else
        echo -e "$email_content" | curl --url "smtp://${SMTP_HOST}:${SMTP_PORT}" \
            --ssl-reqd \
            --mail-from "$SMTP_USER" \
            --mail-rcpt "$to" \
            --upload-file - \
            --user "$SMTP_USER:$SMTP_PASS"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Email enviado exitosamente" "SUCCESS"
        return 0
    else
        log_message "Error al enviar email" "ERROR"
        return 1
    fi
}

# Function to send Slack notification
send_slack() {
    local channel=$1
    local message=$2
    local color=${3:-"good"}
    
    log_message "Enviando notificación a Slack ($channel)..." "INFO"
    
    # Prepare JSON payload
    local payload=$(cat << EOF
{
    "channel": "$channel",
    "attachments": [
        {
            "color": "$color",
            "text": "$message",
            "footer": "Event Manager Notification System",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
    
    # Send to Slack
    curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK"
    
    if [ $? -eq 0 ]; then
        log_message "Notificación de Slack enviada exitosamente" "SUCCESS"
        return 0
    else
        log_message "Error al enviar notificación de Slack" "ERROR"
        return 1
    fi
}

# Function to send Telegram message
send_telegram() {
    local message=$1
    
    log_message "Enviando mensaje a Telegram..." "INFO"
    
    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML"
    
    if [ $? -eq 0 ]; then
        log_message "Mensaje de Telegram enviado exitosamente" "SUCCESS"
        return 0
    else
        log_message "Error al enviar mensaje de Telegram" "ERROR"
        return 1
    fi
}

# Function to send SMS
send_sms() {
    local phone=$1
    local message=$2
    
    log_message "Enviando SMS a $phone..." "INFO"
    
    # Using Twilio-like API
    curl -X POST "https://api.twilio.com/2010-04-01/Accounts/${SMS_API_KEY}/Messages.json" \
        --data-urlencode "From=${SMS_FROM}" \
        --data-urlencode "To=${phone}" \
        --data-urlencode "Body=${message}"
    
    if [ $? -eq 0 ]; then
        log_message "SMS enviado exitosamente" "SUCCESS"
        return 0
    else
        log_message "Error al enviar SMS" "ERROR"
        return 1
    fi
}

# Function to send system alert
send_system_alert() {
    local level=$1
    local message=$2
    
    log_message "Enviando alerta del sistema (${level})..." "INFO"
    
    # Determine alert color for Slack
    local slack_color
    case "$level" in
        critical)
            slack_color="danger"
            ;;
        warning)
            slack_color="warning"
            ;;
        info)
            slack_color="good"
            ;;
        *)
            slack_color="#999999"
            ;;
    esac
    
    # Send to all configured channels
    send_slack "#alerts" "[${level}] ${message}" "$slack_color"
    send_email "$ADMIN_EMAIL" "System Alert: ${level}" "${message}"
    
    # Send SMS for critical alerts
    if [ "$level" == "critical" ]; then
        send_sms "$ADMIN_PHONE" "[CRITICAL] ${message}"
    fi
}

# Function to send daily report
send_daily_report() {
    log_message "Generando y enviando reporte diario..." "INFO"
    
    # Generate report content
    local report_content="<h2>Reporte Diario del Sistema</h2>"
    report_content+="<p>Fecha: $(date)</p>"
    report_content+="<h3>Estadísticas</h3>"
    report_content+="<ul>"
    report_content+="<li>Usuarios activos: $(get_active_users)</li>"
    report_content+="<li>Eventos registrados: $(get_events_count)</li>"
    report_content+="<li>Uso de sistema: $(get_system_usage)</li>"
    report_content+="</ul>"
    
    # Send report via email
    send_email "$ADMIN_EMAIL" "Reporte Diario - $(date +%Y-%m-%d)" "$report_content"
    
    # Send summary to Slack
    send_slack "#reports" "Reporte diario disponible. Revise su email para más detalles."
}

# Function to notify about maintenance
notify_maintenance() {
    local start_time=$1
    local duration=$2
    local type=$3
    
    log_message "Notificando sobre mantenimiento programado..." "INFO"
    
    local message="Mantenimiento programado:\nTipo: ${type}\nInicio: ${start_time}\nDuración estimada: ${duration}"
    
    # Notify all channels
    send_email "$ADMIN_EMAIL" "Mantenimiento Programado" "$message"
    send_slack "#general" "$message" "warning"
    send_telegram "$message"
}

# Function to get active users
get_active_users() {
    # This would typically query your database
    echo "250"
}

# Function to get events count
get_events_count() {
    # This would typically query your database
    echo "1000"
}

# Function to get system usage
get_system_usage() {
    # This would typically check system metrics
    echo "75%"
}

# Show help
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo -e "  ./scripts/notify-manager.sh <comando> [opciones]"
    echo -e "\n${BLUE}Comandos:${NC}"
    echo -e "  email <to> <subject> <message>    Enviar email"
    echo -e "  slack <channel> <message>         Enviar mensaje a Slack"
    echo -e "  telegram <message>                Enviar mensaje a Telegram"
    echo -e "  sms <phone> <message>             Enviar SMS"
    echo -e "  alert <level> <message>           Enviar alerta del sistema"
    echo -e "  report                            Enviar reporte diario"
    echo -e "  maintenance <start> <duration> <type>  Notificar mantenimiento"
}

# Main execution
case "$1" in
    email)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            log_message "Faltan argumentos para email" "ERROR"
            exit 1
        fi
        send_email "$2" "$3" "$4" "$5"
        ;;
    slack)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Faltan argumentos para Slack" "ERROR"
            exit 1
        fi
        send_slack "$2" "$3" "$4"
        ;;
    telegram)
        if [ -z "$2" ]; then
            log_message "Falta mensaje para Telegram" "ERROR"
            exit 1
        fi
        send_telegram "$2"
        ;;
    sms)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Faltan argumentos para SMS" "ERROR"
            exit 1
        fi
        send_sms "$2" "$3"
        ;;
    alert)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_message "Faltan argumentos para alerta" "ERROR"
            exit 1
        fi
        send_system_alert "$2" "$3"
        ;;
    report)
        send_daily_report
        ;;
    maintenance)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            log_message "Faltan argumentos para mantenimiento" "ERROR"
            exit 1
        fi
        notify_maintenance "$2" "$3" "$4"
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
chmod +x scripts/notify-manager.sh
