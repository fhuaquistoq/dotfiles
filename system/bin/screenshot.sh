#!/usr/bin/env bash

# ================================================
# SCREENSHOT TOOL
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

readonly SCREENSHOT_DIR="${HOME}/media/images/screenshots"

# ================================
# Help Menu
# ================================

help() {
    echo "Usage: $(basename "$0") [flags] <mode>"
    echo ""
    echo "Description:"
    echo "  Captura capturas de pantalla y las guarda en el directorio de screenshots."
    echo ""
    echo "Flags:"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Modes:"
    echo "  region            Captura una región seleccionada (predeterminado)"
    echo "  full              Captura la pantalla completa"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Captura una región"
    echo "  $(basename "$0") region       # Captura una región"
    echo "  $(basename "$0") full         # Captura pantalla completa"
    echo ""
    echo "Dependencies:"
    echo "  grim, slurp, satty, dunstify"
}

# ================================
# Funciones de Inicialización
# ================================

init_screenshot_dir() {
    if [[ ! -d "$SCREENSHOT_DIR" ]]; then
        print_info "Creando directorio de screenshots: $SCREENSHOT_DIR"
        mkdir -p "$SCREENSHOT_DIR"
    fi
}

# ================================
# Funciones de Captura
# ================================

capture_region() {
    local img="$1"
    local geom
    
    print_info "Selecciona la región a capturar..."
    geom="$(slurp 2>/dev/null)"
    
    if [[ -z "$geom" ]]; then
        print_warning "Captura cancelada por el usuario"
        return 1
    fi
    
    print_info "Capturando región..."
    grim -g "$geom" "$img"
    return 0
}

capture_fullscreen() {
    local img="$1"
    print_info "Capturando pantalla completa..."
    grim "$img"
}

# ================================
# Funciones de Procesamiento
# ================================

edit_screenshot() {
    local img="$1"
    print_info "Abriendo editor de screenshots..."
    satty --disable-notifications --filename "$img" --output-filename "$img"
}

send_notification() {
    local img="$1"
    local filename="$2"
    dunstify -a "screenshot" -I "$img" -u low -t 3000 "Screenshot saved" "$filename"
}

# ================================
# Función Principal
# ================================

main() {
    local mode="${1:-region}"
    
    # Verificar ayuda
    if [[ "$mode" == "-h" ]] || [[ "$mode" == "--help" ]] || [[ "$mode" == "help" ]]; then
        help
        exit 0
    fi
    
    # Validar modo
    if [[ "$mode" != "region" ]] && [[ "$mode" != "full" ]]; then
        print_error "Modo inválido: '$mode'"
        echo ""
        echo "Use -h o --help para ver los modos disponibles"
        exit 1
    fi
    
    print_header "Screenshot Tool"
    
    # Inicializar directorio
    init_screenshot_dir
    
    # Preparar archivo
    local timestamp
    timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
    local screenshot_file="screenshot_${timestamp}.png"
    local img="$SCREENSHOT_DIR/$screenshot_file"
    
    # Capturar según el modo
    case "$mode" in
        full)
            capture_fullscreen "$img"
            ;;
        region)
            if ! capture_region "$img"; then
                exit 1
            fi
            ;;
    esac
    
    # Editar y notificar
    edit_screenshot "$img"
    print_info "Screenshot guardado: $screenshot_file"
    send_notification "$img" "$screenshot_file"
}

# ================================
# Ejecución
# ================================

main "$@"