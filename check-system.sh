#!/usr/bin/env bash

# ==============================================
# System Check Script
# ==============================================
# Verifica que todos los componentes principales
# estén instalados correctamente
# ==============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

check_command() {
    local cmd="$1"
    local name="$2"
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "${RED}✗${NC} $name (no encontrado: $cmd)"
        return 1
    fi
}

check_file() {
    local file="$1"
    local name="$2"
    
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        echo -e "${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "${RED}✗${NC} $name (no encontrado: $file)"
        return 1
    fi
}

check_service() {
    local service="$1"
    local name="$2"
    
    if systemctl is-enabled "$service" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name (habilitado)"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $name (no habilitado)"
        return 1
    fi
}

# ==============================================
# Check Window Managers
# ==============================================

print_header "Compositores Wayland"

check_command "Hyprland" "Hyprland"
check_command "sway" "Sway"
check_command "waybar" "Waybar"

# ==============================================
# Check Terminal & Shell
# ==============================================

print_header "Terminal y Shell"

check_command "kitty" "Kitty Terminal"
check_command "fish" "Fish Shell"
check_command "starship" "Starship Prompt"

# ==============================================
# Check CLI Tools
# ==============================================

print_header "Herramientas CLI"

check_command "eza" "eza (ls moderno)"
check_command "bat" "bat (cat con colores)"
check_command "zoxide" "zoxide (cd inteligente)"
check_command "fzf" "fzf (fuzzy finder)"
check_command "rg" "ripgrep (búsqueda rápida)"
check_command "fd" "fd (find moderno)"

# ==============================================
# Check Desktop Tools
# ==============================================

print_header "Herramientas de Escritorio"

check_command "grim" "grim (screenshot)"
check_command "slurp" "slurp (selección de región)"
check_command "satty" "satty (anotaciones)"
check_command "wl-copy" "wl-clipboard"
check_command "dunst" "dunst (notificaciones)"
check_command "rofi" "rofi (launcher)"

# ==============================================
# Check Development Tools
# ==============================================

print_header "Herramientas de Desarrollo"

check_command "mise" "mise (version manager)"
check_command "git" "Git"
check_command "docker" "Docker"
check_command "nvim" "Neovim"

# ==============================================
# Check Configurations
# ==============================================

print_header "Configuraciones"

check_file "$HOME/.config/fish" "Fish config"
check_file "$HOME/.config/kitty" "Kitty config"
check_file "$HOME/.config/hypr" "Hyprland config"
check_file "$HOME/.config/sway" "Sway config"
check_file "$HOME/.config/waybar" "Waybar config"
check_file "$HOME/.config/dunst" "Dunst config"
check_file "$HOME/.config/starship.toml" "Starship config"
check_file "$HOME/.local/bin/screenshot.sh" "Screenshot script"

# ==============================================
# Check Services
# ==============================================

print_header "Servicios del Sistema"

check_service "NetworkManager" "NetworkManager"
check_service "sddm" "SDDM"

if command -v docker &> /dev/null; then
    check_service "docker" "Docker"
fi

# ==============================================
# Check Audio
# ==============================================

print_header "Sistema de Audio"

if systemctl --user is-active pipewire &> /dev/null; then
    echo -e "${GREEN}✓${NC} PipeWire (activo)"
else
    echo -e "${RED}✗${NC} PipeWire (no activo)"
fi

if systemctl --user is-active wireplumber &> /dev/null; then
    echo -e "${GREEN}✓${NC} WirePlumber (activo)"
else
    echo -e "${RED}✗${NC} WirePlumber (no activo)"
fi

# ==============================================
# Additional Checks
# ==============================================

print_header "Información del Sistema"

echo -e "Shell actual: ${GREEN}$SHELL${NC}"
echo -e "Terminal: ${GREEN}$TERM${NC}"

if [[ -n "$WAYLAND_DISPLAY" ]]; then
    echo -e "Wayland: ${GREEN}✓ Activo${NC} ($WAYLAND_DISPLAY)"
else
    echo -e "Wayland: ${RED}✗ No detectado${NC}"
fi

if [[ -n "$XDG_SESSION_TYPE" ]]; then
    echo -e "Sesión: ${GREEN}$XDG_SESSION_TYPE${NC}"
fi

# ==============================================
# Summary
# ==============================================

print_header "Resumen"

echo "Para más información sobre componentes específicos:"
echo "  - Hyprland: hyprctl version"
echo "  - Sway: sway --version"
echo "  - Fish: fish --version"
echo "  - Mise: mise --version"
echo ""
echo "Para ver logs:"
echo "  - Sistema: journalctl -xe"
echo "  - Hyprland: ~/.local/share/hyprland/hyprland.log"
echo "  - Sway: ~/.local/share/sway/sway.log"
echo ""
echo "Si algo falta, ejecuta: ./install.sh"
