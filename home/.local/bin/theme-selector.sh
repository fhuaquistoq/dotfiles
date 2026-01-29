#!/usr/bin/env bash

# ================================================
# THEME SELECTOR
# ================================================


# ================================
# Utilidades
# ================================

set -e

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
# Constantes (pueden ser sobrescritas por flags)
# ================================

CONFIG_DIR="$HOME/.local/share/theme-selector"
THEMES_DIR=""
CONFIG_FILE=""

# ================================
# Menú de Ayuda
# ================================

help() {
    echo "Usage: theme-selector.sh [global-flags] <command> [command-flags] [arguments]"
    echo ""
    echo "Global Flags:"
    echo "  -c, --config-dir <dir>    Set configuration directory (default: ~/.local/share/theme-selector)"
    echo "  -t, --themes-dir <dir>    Set themes directory (default: <config-dir>/themes)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Commands:"
    echo "  init                  Initialize configuration directory"
    echo "  list                  List available themes and validate them"
    echo "  generate <theme>      Generate theme files from templates"
    echo "  apply <theme>         Apply theme by creating symbolic links"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  theme-selector.sh init"
    echo "  theme-selector.sh --config-dir ~/.config/themes generate catppuccin-mocha"
    echo "  theme-selector.sh generate catppuccin-mocha --apply"
    echo "  theme-selector.sh apply catppuccin-mocha --sources ~/.config --apps waybar"
    echo ""
    echo "For command-specific help, use: theme-selector.sh <command> --help"
}

help_generate() {
    echo "Usage: theme-selector.sh generate <theme> [flags]"
    echo ""
    echo "Generate theme files from templates using a theme definition."
    echo ""
    echo "Arguments:"
    echo "  <theme>               Theme name (must exist in themes directory)"
    echo ""
    echo "Flags:"
    echo "  -a, --apply               Automatically apply the theme after generation"
    echo "  -s, --sources <src>...    Only process specific sources (space-separated)"
    echo "  -p, --apps <app>...       Only process specific apps (space-separated)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  theme-selector.sh generate catppuccin-mocha"
    echo "  theme-selector.sh generate catppuccin-mocha --apply"
    echo "  theme-selector.sh generate catppuccin-mocha --sources ~/.config"
    echo "  theme-selector.sh generate catppuccin-mocha --apps waybar kitty"
    echo "  theme-selector.sh generate catppuccin-mocha --sources ~/.config --apps waybar --apply"
}

help_apply() {
    echo "Usage: theme-selector.sh apply <theme> [flags]"
    echo ""
    echo "Apply a generated theme by creating symbolic links."
    echo ""
    echo "Arguments:"
    echo "  <theme>               Theme name (must be already generated)"
    echo ""
    echo "Flags:"
    echo "  -s, --sources <src>...    Only process specific sources (space-separated)"
    echo "  -p, --apps <app>...       Only process specific apps (space-separated)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  theme-selector.sh apply catppuccin-mocha"
    echo "  theme-selector.sh apply catppuccin-mocha --sources ~/.config"
    echo "  theme-selector.sh apply catppuccin-mocha --apps waybar kitty"
    echo "  theme-selector.sh apply catppuccin-mocha --sources ~/.config --apps waybar"
}

# ================================
# Utilidades JSON
# ================================

check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it to use this script."
        exit 1
    fi
}

validate_path_within_dir() {
    local path="$1"
    local allowed_dir="$2"
    
    path="${path/#\~/$HOME}"
    allowed_dir="${allowed_dir/#\~/$HOME}"
    
    local path_dir="$(dirname "$path")"
    
    local abs_allowed=$(cd "$allowed_dir" 2>/dev/null && pwd -P)
    if [ -z "$abs_allowed" ]; then
        print_error "Allowed directory does not exist: $allowed_dir"
        return 1
    fi
    
    if [ -d "$path_dir" ]; then
        local abs_path=$(cd "$path_dir" 2>/dev/null && pwd -P)
    else
        # Construir la ruta absoluta manualmente para directorios no existentes
        # Primero, hacerla absoluta si es relativa
        if [[ "$path_dir" != /* ]]; then
            path_dir="$allowed_dir/$path_dir"
        fi
        # Normalizar la ruta (remover .., ., etc.)
        abs_path=$(readlink -m "$path_dir")
    fi
    
    if [[ "$abs_path" != "$abs_allowed"* ]]; then
        print_error "Path '$path' is outside allowed directory '$allowed_dir'"
        print_error "Resolved: '$abs_path' not in '$abs_allowed'"
        return 1
    fi
    
    return 0
}

resolve_json_value() {
    local json_file="$1"
    local key="$2"
    local visited="$3"
    
    # Verificar referencia circular
    if [[ "$visited" == *"|$key|"* ]]; then
        print_error "Circular reference detected: $key"
        return 1
    fi
    
    visited="${visited}|${key}|"
    
    # Obtener valor del JSON
    # Dividir clave por el primer punto para manejar objetos anidados
    local value
    if [[ "$key" =~ ^([^.]+)\.(.+)$ ]]; then
        local parent="${BASH_REMATCH[1]}"
        local child="${BASH_REMATCH[2]}"
        # Usar jq para acceder a objetos anidados con notación de corchetes para caracteres especiales
        value=$(jq -r ".[\"${parent}\"][\"${child}\"]" "$json_file" 2>/dev/null)
    else
        # Acceso directo a la clave
        value=$(jq -r ".[\"${key}\"]" "$json_file" 2>/dev/null)
    fi
    
    if [ "$value" == "null" ] || [ -z "$value" ]; then
        print_error "Key not found in $(basename "$json_file"): $key"
        return 1
    fi
    
    # Verificar si el valor es un color (hex, rgb, rgba)
    if [[ "$value" =~ ^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$ ]] || \
       [[ "$value" =~ ^rgb\([0-9]+,\ ?[0-9]+,\ ?[0-9]+\)$ ]] || \
       [[ "$value" =~ ^rgba\([0-9]+,\ ?[0-9]+,\ ?[0-9]+,\ ?[0-9.]+\)$ ]]; then
        echo "$value"
        return 0
    fi
    
    # Si es una referencia a otra clave, resolver recursivamente
    if [[ "$value" =~ ^[a-zA-Z0-9._:-]+$ ]] && [[ ! "$value" =~ ^[0-9]+$ ]]; then
        resolve_json_value "$json_file" "$value" "$visited"
        return $?
    fi
    
    # De lo contrario, devolver el valor tal como está
    echo "$value"
    return 0
}

transform_color_value() {
    local value="$1"
    local transform="$2"

    if [[ ! "$value" =~ ^#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$ ]]; then
        echo "$value"
        return 0
    fi

    local hex="${value#\#}"
    local hex_len=${#hex}
    if [ $hex_len -lt 6 ]; then
        echo "$value"
        return 0
    fi

    local r_hex="${hex:0:2}"
    local g_hex="${hex:2:2}"
    local b_hex="${hex:4:2}"

    local r=$(printf "%d" "0x${r_hex}")
    local g=$(printf "%d" "0x${g_hex}")
    local b=$(printf "%d" "0x${b_hex}")

    case "$transform" in
        hex)
            echo "$hex"
            ;;
        hex_hash)
            echo "#${hex}"
            ;;
        rgb)
            echo "${r},${g},${b}"
            ;;
        rgb_fn)
            echo "rgb(${r},${g},${b})"
            ;;
        hsl|hsl_fn)
            local hsl_values
            hsl_values=$(awk -v r="$r" -v g="$g" -v b="$b" 'BEGIN{
                r/=255; g/=255; b/=255;
                max=r; if (g>max) max=g; if (b>max) max=b;
                min=r; if (g<min) min=g; if (b<min) min=b;
                l=(max+min)/2;
                if (max==min) { h=0; s=0; }
                else {
                    d=max-min;
                    if (l>0.5) s=d/(2-max-min); else s=d/(max+min);
                    if (max==r) { h=(g-b)/d; if (g<b) h+=6; }
                    else if (max==g) { h=(b-r)/d+2; }
                    else { h=(r-g)/d+4; }
                    h*=60;
                }
                s*=100; l*=100;
                h=int(h+0.5); s=int(s+0.5); l=int(l+0.5);
                printf "%d,%d%%,%d%%", h, s, l;
            }')
            if [ "$transform" = "hsl_fn" ]; then
                echo "hsl(${hsl_values})"
            else
                echo "$hsl_values"
            fi
            ;;
        *)
            echo "$hex"
            ;;
    esac
}

# ================================
# Inicializar rutas
# ================================

init_paths() {
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="$CONFIG_DIR/config.json"
    fi
    if [ -z "$THEMES_DIR" ]; then
        THEMES_DIR="$CONFIG_DIR/themes"
    fi
}

# ================================
# Inicialización
# ================================

init_config() {
    init_paths
    
    print_header "INITIALIZING CONFIGURATION"
    
    # Crear directorio de configuración
    if [ -d "$CONFIG_DIR" ]; then
        if ask_yes_no "Configuration directory already exists. Reinitialize?"; then
            print_info "Backing up existing configuration..."
            mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        else
            print_warning "Initialization cancelled"
            return 0
        fi
    fi
    
    print_info "Creating configuration directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$THEMES_DIR"
    
    # Crear config.json predeterminado
    print_info "Creating default config.json"
    cat > "$CONFIG_FILE" << 'EOF'
{
  "sources": [
    "~/.config"
  ],
  "apps": [
    {
      "name": "waybar",
      "template": "themes/template",
      "target": "theme.css",
    "format": "css",
    "transform": "hex",
    "sudo": false
    }
  ]
}
EOF
    
    print_info "Configuration initialized successfully!"
    print_info "Configuration directory: $CONFIG_DIR"
    print_info "Edit $CONFIG_FILE to configure your apps"
    print_info "Add theme files to $THEMES_DIR"
}

# ================================
# Listar temas
# ================================

list_themes() {
    init_paths
    
    print_header "AVAILABLE THEMES"
    
    check_jq
    
    if [ ! -d "$THEMES_DIR" ]; then
        print_error "Themes directory not found: $THEMES_DIR"
        print_info "Run 'theme-selector.sh init' first"
        return 1
    fi
    
    local found_themes=false
    
    for theme_file in "$THEMES_DIR"/*.json; do
        [ -e "$theme_file" ] || continue
        
        local theme_name=$(basename "$theme_file" .json)
        
        found_themes=true
        
        echo -e "${GREEN}✓${NC} $theme_name"
    done
    
    if [ "$found_themes" = false ]; then
        print_warning "No theme files found in $THEMES_DIR"
        print_info "Add .json theme files to this directory"
    fi
}

# ================================
# Generar temas
# ================================

generate_themes() {
    # Parsear flags específicos del comando primero
    local theme_name=""
    local auto_apply=false
    local filter_sources=()
    local filter_apps=()
    
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        help_generate
        return 0
    fi
    
    if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
        theme_name="$1"
        shift
    fi
    
    # Parse remaining flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--apply)
                auto_apply=true
                shift
                ;;
            -s|--sources)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    filter_sources+=("$1")
                    shift
                done
                ;;
            -p|--apps)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    filter_apps+=("$1")
                    shift
                done
                ;;
            -h|--help)
                help_generate
                return 0
                ;;
            *)
                print_error "Unknown flag: $1"
                help_generate
                return 1
                ;;
        esac
    done
    
    if [ -z "$theme_name" ]; then
        print_error "Theme name is required"
        help_generate
        return 1
    fi
    
    init_paths
    
    print_header "GENERATING THEME: $theme_name"
    
    check_jq
    
    local theme_file="$THEMES_DIR/${theme_name}.json"
    
    if [ ! -f "$theme_file" ]; then
        print_error "Theme file not found: $theme_file"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file not found: $CONFIG_FILE"
        print_info "Run 'theme-selector.sh init' first"
        return 1
    fi
    
    # Leer fuentes y apps de la configuración
    local all_sources=$(jq -r '.sources[]' "$CONFIG_FILE")
    local apps_count=$(jq '.apps | length' "$CONFIG_FILE")
    
    # Filtrar fuentes si se especifica
    local sources_to_process=()
    if [ ${#filter_sources[@]} -gt 0 ]; then
        for filter_src in "${filter_sources[@]}"; do
            filter_src="${filter_src/#\~/$HOME}"
            local found=false
            for src in $all_sources; do
                src="${src/#\~/$HOME}"
                if [ "$src" == "$filter_src" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == "false" ]; then
                print_warning "Source '$filter_src' not found in config.json"
            fi
            sources_to_process+=("$filter_src")
        done
    else
        for src in $all_sources; do
            sources_to_process+=("$src")
        done
    fi
    
    # Validate filter_apps if specified
    if [ ${#filter_apps[@]} -gt 0 ]; then
        for filter_app in "${filter_apps[@]}"; do
            local found=false
            for ((i=0; i<apps_count; i++)); do
                local app_name=$(jq -r ".apps[$i].name" "$CONFIG_FILE")
                if [ "$app_name" == "$filter_app" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == "false" ]; then
                print_error "App '$filter_app' not found in config.json"
                return 1
            fi
        done
    fi
    
    local missing_apps=()
    
    # Verificar si todos los directorios de apps existen en todas las fuentes
    for source in "${sources_to_process[@]}"; do
        source="${source/#\~/$HOME}"
        
        if [ ! -d "$source" ]; then
            print_error "Source directory not found: $source"
            continue
        fi
        
        for ((i=0; i<apps_count; i++)); do
            local app_name=$(jq -r ".apps[$i].name" "$CONFIG_FILE")
            
            # Omitir si se está filtrando apps y esta app no está en el filtro
            if [ ${#filter_apps[@]} -gt 0 ]; then
                local should_process=false
                for filter_app in "${filter_apps[@]}"; do
                    if [ "$app_name" == "$filter_app" ]; then
                        should_process=true
                        break
                    fi
                done
                if [ "$should_process" == "false" ]; then
                    continue
                fi
            fi
            
            local app_dir="$source/$app_name"
            
            if [ ! -d "$app_dir" ]; then
                missing_apps+=("$app_name in $source")
            fi
        done
    done
    
    if [ ${#missing_apps[@]} -gt 0 ]; then
        print_error "Missing app directories:"
        for missing in "${missing_apps[@]}"; do
            echo -e "  ${RED}✗${NC} $missing"
        done
        return 1
    fi
    
    # Generar temas para cada app en cada fuente
    for source in "${sources_to_process[@]}"; do
        source="${source/#\~/$HOME}"
        
        print_info "Processing source: $source"
        
        for ((i=0; i<apps_count; i++)); do
            local app_name=$(jq -r ".apps[$i].name" "$CONFIG_FILE")
            
            # Omitir si se está filtrando apps y esta app no está en el filtro
            if [ ${#filter_apps[@]} -gt 0 ]; then
                local should_process=false
                for filter_app in "${filter_apps[@]}"; do
                    if [ "$app_name" == "$filter_app" ]; then
                        should_process=true
                        break
                    fi
                done
                if [ "$should_process" == "false" ]; then
                    continue
                fi
            fi
            
            local template=$(jq -r ".apps[$i].template" "$CONFIG_FILE")
            local format=$(jq -r ".apps[$i].format" "$CONFIG_FILE")
            local use_sudo=$(jq -r ".apps[$i].sudo" "$CONFIG_FILE")
            local transform=$(jq -r ".apps[$i].transform" "$CONFIG_FILE")
            
            # Establecer sudo a false por defecto si no se especifica
            if [ "$use_sudo" == "null" ]; then
                use_sudo="false"
            fi
            # Establecer transform a hex por defecto si no se especifica
            if [ "$transform" == "null" ] || [ -z "$transform" ]; then
                transform="hex"
            fi
            
            local app_dir="$source/$app_name"
            
            # Expandir tilde y hacer la ruta del template absoluta relativa a app_dir si es relativa
            template="${template/#\~/$HOME}"
            if [[ "$template" != /* ]]; then
                template="$app_dir/$template"
            fi
            
            # Validar que la ruta del template esté dentro de app_dir
            if ! validate_path_within_dir "$template" "$app_dir"; then
                print_error "Invalid template path for $app_name"
                continue
            fi
            
            # Crear archivo de salida en el mismo directorio que el template
            local template_dir="$(dirname "$template")"
            local output_file="$template_dir/${theme_name}.${format}"
            
            if [ ! -f "$template" ]; then
                print_warning "Template not found: $template (skipping $app_name)"
                continue
            fi
            
            print_info "Generating $app_name theme..."
            
            # Leer template y reemplazar placeholders
            local content=$(cat "$template")
            
            # Encontrar todos los patrones [[key]]
            while [[ "$content" =~ \[\[([a-zA-Z0-9._:-]+)\]\] ]]; do
                local placeholder="${BASH_REMATCH[1]}"
                local value=$(resolve_json_value "$theme_file" "$placeholder" "")
                
                if [ $? -ne 0 ]; then
                    print_error "Failed to resolve in $(basename "$theme_file"): $placeholder"
                    continue 2
                fi
                value=$(transform_color_value "$value" "$transform")
                
                # Reemplazar todas las ocurrencias de este placeholder
                content="${content//\[\[${placeholder}\]\]/$value}"
            done
            
            # Escribir archivo de salida (con sudo si es necesario)
            if [ "$use_sudo" == "true" ]; then
                print_info "Writing with sudo: $output_file"
                echo "$content" | sudo tee "$output_file" > /dev/null
            else
                echo "$content" > "$output_file"
            fi
            print_info "Generated: $output_file"
        done
    done
    
    print_info "Theme generation completed!"
    
    # Aplicar automáticamente si se estableció el flag
    if [ "$auto_apply" == "true" ]; then
        echo ""
        local apply_args=("$theme_name")
        if [ ${#filter_sources[@]} -gt 0 ]; then
            apply_args+=("--sources" "${filter_sources[@]}")
        fi
        if [ ${#filter_apps[@]} -gt 0 ]; then
            apply_args+=("--apps" "${filter_apps[@]}")
        fi
        apply_theme "${apply_args[@]}"
    fi
}

# ================================
# Aplicar temas
# ================================

apply_theme() {
    # Parsear flags específicos del comando primero
    local theme_name=""
    local filter_sources=()
    local filter_apps=()
    
    # Verificar flag de ayuda primero
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        help_apply
        return 0
    fi
    
    # Obtener nombre del tema (primer argumento que no sea flag)
    if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
        theme_name="$1"
        shift
    fi
    
    # Parse remaining flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--sources)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    filter_sources+=("$1")
                    shift
                done
                ;;
            -p|--apps)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    filter_apps+=("$1")
                    shift
                done
                ;;
            -h|--help)
                help_apply
                return 0
                ;;
            *)
                print_error "Unknown flag: $1"
                help_apply
                return 1
                ;;
        esac
    done
    
    if [ -z "$theme_name" ]; then
        print_error "Theme name is required"
        help_apply
        return 1
    fi
    
    init_paths
    
    print_header "APPLYING THEME: $theme_name"
    
    check_jq
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file not found: $CONFIG_FILE"
        print_info "Run 'theme-selector.sh init' first"
        return 1
    fi
    
    # Leer fuentes y apps de la configuración
    local all_sources=$(jq -r '.sources[]' "$CONFIG_FILE")
    local apps_count=$(jq '.apps | length' "$CONFIG_FILE")
    
    # Filtrar fuentes si se especifica
    local sources_to_process=()
    if [ ${#filter_sources[@]} -gt 0 ]; then
        for filter_src in "${filter_sources[@]}"; do
            filter_src="${filter_src/#\~/$HOME}"
            local found=false
            for src in $all_sources; do
                src="${src/#\~/$HOME}"
                if [ "$src" == "$filter_src" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == "false" ]; then
                print_warning "Source '$filter_src' not found in config.json"
            fi
            sources_to_process+=("$filter_src")
        done
    else
        for src in $all_sources; do
            sources_to_process+=("$src")
        done
    fi
    
    # Validate filter_apps if specified
    if [ ${#filter_apps[@]} -gt 0 ]; then
        for filter_app in "${filter_apps[@]}"; do
            local found=false
            for ((i=0; i<apps_count; i++)); do
                local app_name=$(jq -r ".apps[$i].name" "$CONFIG_FILE")
                if [ "$app_name" == "$filter_app" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == "false" ]; then
                print_error "App '$filter_app' not found in config.json"
                return 1
            fi
        done
    fi
    
    # Aplicar temas para cada app en cada fuente
    for source in "${sources_to_process[@]}"; do
        source="${source/#\~/$HOME}"
        
        print_info "Processing source: $source"
        
        for ((i=0; i<apps_count; i++)); do
            local app_name=$(jq -r ".apps[$i].name" "$CONFIG_FILE")
            
            # Omitir si se está filtrando apps y esta app no está en el filtro
            if [ ${#filter_apps[@]} -gt 0 ]; then
                local should_process=false
                for filter_app in "${filter_apps[@]}"; do
                    if [ "$app_name" == "$filter_app" ]; then
                        should_process=true
                        break
                    fi
                done
                if [ "$should_process" == "false" ]; then
                    continue
                fi
            fi
            
            local target=$(jq -r ".apps[$i].target" "$CONFIG_FILE")
            local format=$(jq -r ".apps[$i].format" "$CONFIG_FILE")
            local use_sudo=$(jq -r ".apps[$i].sudo" "$CONFIG_FILE")
            
            # Establecer sudo a false por defecto si no se especifica
            if [ "$use_sudo" == "null" ]; then
                use_sudo="false"
            fi
            
            local app_dir="$source/$app_name"
            
            # Obtener template para encontrar dónde está el archivo de tema generado
            local template=$(jq -r ".apps[$i].template" "$CONFIG_FILE")
            template="${template/#\~/$HOME}"
            if [[ "$template" != /* ]]; then
                template="$app_dir/$template"
            fi
            
            # El archivo fuente está en el mismo directorio que el template
            local template_dir="$(dirname "$template")"
            local source_file="$template_dir/${theme_name}.${format}"
            
            if [ ! -f "$source_file" ]; then
                print_warning "Theme file not found: $source_file (skipping $app_name)"
                print_info "Run 'theme-selector.sh generate $theme_name' first"
                continue
            fi
            
            # Hacer la ruta target absoluta relativa a app_dir si es relativa
            target="${target/#\~/$HOME}"
            if [[ "$target" != /* ]]; then
                target="$app_dir/$target"
            fi
            
            # Validar que la ruta target esté dentro de app_dir
            if ! validate_path_within_dir "$target" "$app_dir"; then
                print_error "Invalid target path for $app_name"
                continue
            fi
            
            print_info "Applying $app_name theme..."
            
            # Preparar comandos basándose en el requerimiento de sudo
            if [ "$use_sudo" == "true" ]; then
                print_info "Applying with sudo privileges"
                
                # Remover enlace/archivo existente si existe
                if [ -e "$target" ] || [ -L "$target" ]; then
                    sudo rm -f "$target"
                fi
                
                # Crear directorio padre si no existe
                local target_dir=$(dirname "$target")
                sudo mkdir -p "$target_dir"
                
                # Crear enlace simbólico
                sudo ln -sf "$source_file" "$target"
            else
                # Remover enlace/archivo existente si existe
                if [ -e "$target" ] || [ -L "$target" ]; then
                    rm -f "$target"
                fi
                
                # Crear directorio padre si no existe
                local target_dir=$(dirname "$target")
                mkdir -p "$target_dir"
                
                # Crear enlace simbólico
                ln -sf "$source_file" "$target"
            fi
            
            print_info "Created symlink: $target -> $source_file"
        done
    done
    
    print_info "Theme applied successfully!"
    print_warning "You may need to restart applications for changes to take effect"
}

# ================================
# Función principal
# ================================

main() {
    # Parsear flags globales primero
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config-dir)
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "--config-dir requires a directory path"
                    exit 1
                fi
                CONFIG_DIR="${2/#\~/$HOME}"
                CONFIG_FILE="$CONFIG_DIR/config.json"
                shift 2
                ;;
            -t|--themes-dir)
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "--themes-dir requires a directory path"
                    exit 1
                fi
                THEMES_DIR="${2/#\~/$HOME}"
                shift 2
                ;;
            -h|--help)
                help
                exit 0
                ;;
            -*)
                print_error "Unknown global flag: $1"
                help
                exit 1
                ;;
            *)
                # El primer argumento que no sea flag es el comando
                break
                ;;
        esac
    done
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        init)
            init_config
            ;;
        list)
            list_themes
            ;;
        generate)
            generate_themes "$@"
            ;;
        apply)
            apply_theme "$@"
            ;;
        help)
            help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
