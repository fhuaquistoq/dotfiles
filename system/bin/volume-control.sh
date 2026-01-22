#!/usr/bin/env bash

# ================================================
# VOLUME CONTROL TOOL
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

readonly SINK="@DEFAULT_AUDIO_SINK@"
readonly THRESHOLD=10
readonly NOTIFY_ID_FILE="/tmp/volume-control-notify-id"

# ================================
# Menú de Ayuda
# ================================

help() {
    echo "Usage: $(basename "$0") [flags] <command>"
    echo ""
    echo "Description:"
    echo "  Controla el volumen del sistema con ajuste dinámico de step."
    echo "  Step de 1% cuando volumen ≤10%, y 2% cuando >10%."
    echo ""
    echo "Flags:"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Commands:"
    echo "  up                Aumentar volumen"
    echo "  down              Disminuir volumen"
    echo "  mute              Alternar silencio"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") up           # Aumenta el volumen"
    echo "  $(basename "$0") down         # Disminuye el volumen"
    echo "  $(basename "$0") mute         # Silencia/activa el audio"
    echo ""
    echo "Dependencies:"
    echo "  wpctl, notify-send (mako)"
}

# ================================
# Funciones de Obtención de Estado
# ================================

get_volume() {
    local volume_info
    volume_info=$(wpctl get-volume "$SINK" 2>/dev/null)
    
    if [[ -z "$volume_info" ]]; then
        print_error "No se pudo obtener el volumen"
        return 1
    fi
    
    local volume
    volume=$(echo "$volume_info" | awk '{print $2}')
    
    local volume_percent
    volume_percent=$(awk "BEGIN {printf \"%.0f\", $volume * 100}")
    
    echo "$volume_percent"
}

is_muted() {
    local volume_info
    volume_info=$(wpctl get-volume "$SINK" 2>/dev/null)
    
    if echo "$volume_info" | grep -q "MUTED"; then
        return 0
    else
        return 1
    fi
}

# ================================
# Funciones de Control de Volumen
# ================================

get_step() {
    local current_volume="$1"
    
    if [[ $current_volume -lt $THRESHOLD ]]; then
        echo "0.01"  # 1% en formato decimal
    else
        echo "0.02"  # 2% en formato decimal
    fi
}

volume_up() {
    local current_volume
    if ! current_volume=$(get_volume); then
        return 1
    fi
    
    local step
    step=$(get_step "$current_volume")
    
    print_info "Aumentando volumen (step: $(awk "BEGIN {printf \"%.0f\", $step * 100}")%)"
    wpctl set-volume "$SINK" "${step}+" --limit 1.0
    
    return 0
}

volume_down() {
    local current_volume
    if ! current_volume=$(get_volume); then
        return 1
    fi
    
    local step
    step=$(get_step "$current_volume")
    
    print_info "Disminuyendo volumen (step: $(awk "BEGIN {printf \"%.0f\", $step * 100}")%)"
    wpctl set-volume "$SINK" "${step}-"
    
    return 0
}

toggle_mute() {
    print_info "Alternando silencio..."
    wpctl set-mute "$SINK" toggle
    
    return 0
}

# ================================
# Funciones de Notificación
# ================================

send_volume_notification() {
    local volume
    volume=$(get_volume)
    
    local message
    if is_muted; then
        message="Silenciado"
    else
        message="Volumen: ${volume}%"
    fi
    
    # Leer el ID anterior si existe
    local prev_id=""
    if [[ -f "$NOTIFY_ID_FILE" ]]; then
        prev_id=$(cat "$NOTIFY_ID_FILE")
    fi
    
    # Enviar notificación
    local new_id
    if [[ -n "$prev_id" ]]; then
        new_id=$(notify-send -a volume -u low -t 4000 -r "$prev_id" -p "$message")
    else
        new_id=$(notify-send -a volume -u low -t 4000 -p "$message")
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
        up|down|mute)
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
            if volume_up; then
                send_volume_notification
            else
                exit 1
            fi
            ;;
        down)
            if volume_down; then
                send_volume_notification
            else
                exit 1
            fi
            ;;
        mute)
            if toggle_mute; then
                send_volume_notification
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