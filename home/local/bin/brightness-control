#!/usr/bin/env bash

# ================================================
# BRIGHTNESS CONTROL TOOL
# ================================================

set -e

# ================================
# Utilidades
# ================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY && "$default" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

# ================================
# Variables Globales
# ================================

readonly THRESHOLD=10
readonly NOTIFY_ID_FILE="/tmp/brightness-control-notify-id"

# ================================
# Menú de Ayuda
# ================================

help() {
    echo "Usage: $(basename "$0") [flags] <command>"
    echo ""
    echo "Description:"
    echo "  Controla el brillo del sistema con ajuste dinámico de step."
    echo "  Step de 1% cuando brillo ≤10%, y 2% cuando >10%."
    echo ""
    echo "Flags:"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Commands:"
    echo "  up                Aumentar brillo"
    echo "  down              Disminuir brillo"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") up           # Aumenta el brillo"
    echo "  $(basename "$0") down         # Disminuye el brillo"
    echo ""
    echo "Dependencies:"
    echo "  brightnessctl, notify-send (mako)"
}

# ================================
# Funciones de Obtención de Estado
# ================================

get_brightness() {
    local brightness_info
    brightness_info=$(brightnessctl get 2>/dev/null)
    
    if [[ -z "$brightness_info" ]]; then
        print_error "No se pudo obtener el brillo"
        return 1
    fi
    
    local max_brightness
    max_brightness=$(brightnessctl max 2>/dev/null)
    
    if [[ -z "$max_brightness" ]] || [[ "$max_brightness" -eq 0 ]]; then
        print_error "No se pudo obtener el brillo máximo"
        return 1
    fi
    
    # Calcular porcentaje
    local brightness_percent
    brightness_percent=$(awk "BEGIN {printf \"%.0f\", ($brightness_info / $max_brightness) * 100}")
    
    echo "$brightness_percent"
}

# ================================
# Funciones de Control de Brillo
# ================================

get_step() {
    local current_brightness="$1"
    
    if [[ $current_brightness -lt $THRESHOLD ]]; then
        echo "1%"
    else
        echo "2%"
    fi
}

brightness_up() {
    local current_brightness
    if ! current_brightness=$(get_brightness); then
        return 1
    fi
    
    local step
    step=$(get_step "$current_brightness")
    
    print_info "Aumentando brillo (step: $step)"
    brightnessctl set "${step}+" -q
    
    return 0
}

brightness_down() {
    local current_brightness
    if ! current_brightness=$(get_brightness); then
        return 1
    fi
    
    # Evitar que baje a 0% (se apaga la pantalla)
    if [[ $current_brightness -le 1 ]]; then
        print_warning "El brillo ya está al mínimo (1%)"
        return 0
    fi
    
    local step
    step=$(get_step "$current_brightness")
    
    print_info "Disminuyendo brillo (step: $step)"
    brightnessctl set "${step}-" -q
    
    return 0
}

# ================================
# Funciones de Notificación
# ================================

send_brightness_notification() {
    local brightness
    brightness=$(get_brightness)
    
    local message="Brillo: ${brightness}%"
    
    # Leer el ID anterior si existe
    local prev_id=""
    if [[ -f "$NOTIFY_ID_FILE" ]]; then
        prev_id=$(cat "$NOTIFY_ID_FILE")
    fi
    
    # Enviar notificación
    local new_id
    if [[ -n "$prev_id" ]]; then
        new_id=$(notify-send -a brightness -u low -t 4000 -r "$prev_id" -p "$message")
    else
        new_id=$(notify-send -a brightness -u low -t 4000 -p "$message")
    fi
    
    # Guardar el nuevo ID
    echo "$new_id" > "$NOTIFY_ID_FILE"
}

# ================================
# Función Principal
# ================================

main() {
    local command="${1:-help}"
    
    if [[ "$command" == "-h" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "help" ]]; then
        help
        exit 0
    fi
    
    case "$command" in
        up|down)
            # Comando válido
            ;;
        *)
            print_error "Comando inválido: '$command'"
            echo ""
            echo "Use -h o --help para ver los comandos disponibles"
            exit 1
            ;;
    esac
    
    case "$command" in
        up)
            if brightness_up; then
                send_brightness_notification
            else
                exit 1
            fi
            ;;
        down)
            if brightness_down; then
                send_brightness_notification
            else
                exit 1
            fi
            ;;
    esac
}

# ================================
# Ejecución
# ================================

main "$@"
