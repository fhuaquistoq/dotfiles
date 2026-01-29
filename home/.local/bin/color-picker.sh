#!/usr/bin/env bash

# ================================================
# HYPRPICKER COLOR PICKER
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

readonly CLIPBOARD_MANAGER="wl-copy"

# ================================
# Help Menu
# ================================

help() {
    echo "Usage: $(basename "$0") [flags]"
    echo ""
    echo "Description:"
    echo "  Selecciona un color de la pantalla usando hyprpicker."
    echo ""
    echo "Flags:"
    echo "  -h, --help        Muestra este mensaje de ayuda"
    echo "  -c, --copy        Copia el color al portapapeles (predeterminado)"
    echo "  -n, --no-copy     No copia el color al portapapeles"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Selecciona un color y lo copia"
    echo "  $(basename "$0") --no-copy    # Selecciona un color sin copiar"
    echo ""
    echo "Dependencies:"
    echo "  hyprpicker, notify-send (mako), wl-copy"
}

# ================================
# Validación de Dependencias
# ================================

check_dependencies() {
    local deps=("hyprpicker" "notify-send" "$CLIPBOARD_MANAGER")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Dependencia no encontrada: $dep"
            exit 1
        fi
    done
}

# ================================
# Funciones de Color Picker
# ================================

pick_color() {
    local color
    
    print_info "Selecciona un color moviendo el cursor..."
    color="$(hyprpicker 2>/dev/null)" || {
        print_warning "Selección de color cancelada por el usuario"
        return 1
    }
    
    echo "$color"
}

copy_to_clipboard() {
    local color="$1"
    echo -n "$color" | "$CLIPBOARD_MANAGER"
    print_info "Color copiado al portapapeles: $color"
}

send_notification() {
    local color="$1"
    local action="$2"
    
    local notif_text="Color seleccionado: $color"
    
    if [[ "$action" == "copied" ]]; then
        notif_text="$notif_text (copiado)"
    fi
    
    notify-send -a "color-picker" -u low -t 3000 "Color Picker" "$notif_text"
}

# ================================
# Función Principal
# ================================

main() {
    local copy_to_clip="true"
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                help
                exit 0
                ;;
            -c|--copy)
                copy_to_clip="true"
                shift
                ;;
            -n|--no-copy)
                copy_to_clip="false"
                shift
                ;;
            *)
                print_error "Argumento inválido: $1"
                echo ""
                echo "Use -h o --help para ver las opciones disponibles"
                exit 1
                ;;
        esac
    done
    
    print_header "Hyprpicker Color Picker"
    
    # Validar dependencias
    check_dependencies
    
    # Seleccionar color
    local selected_color
    if ! selected_color=$(pick_color); then
        exit 1
    fi
    
    # Copiar al portapapeles si se especifica
    if [[ "$copy_to_clip" == "true" ]]; then
        copy_to_clipboard "$selected_color"
        send_notification "$selected_color" "copied"
    else
        print_info "Color seleccionado: $selected_color"
        send_notification "$selected_color" "selected"
    fi
}

# ================================
# Ejecución
# ================================

main "$@"
