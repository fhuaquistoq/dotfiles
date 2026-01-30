#!/usr/bin/env bash

# ================================================
# INSTALADOR DE DOTFILES
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

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
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

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$DOTFILES_DIR/scripts"
PACKAGES_DIR="$SCRIPT_DIR/packages"
SYSTEM_DIR="$DOTFILES_DIR/system"
HOME_DIR="$DOTFILES_DIR/home"
CONFIG_DIR="$DOTFILES_DIR/config"
APPS_DIR="$DOTFILES_DIR/apps"
USER_HOME="${HOME}"
TEMP_DIR="/tmp/dotfiles-install"

# ================================
# Funciones de Validación
# ================================

# Verificar que no se ejecuta como root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Este script NO debe ejecutarse como root"
        print_info "Ejecuta sin sudo: bash install-dotfiles.sh"
        print_info "El script pedirá permisos cuando sea necesario"
        exit 1
    fi
    print_success "Ejecutando como usuario normal"
}

# Verificar que existe sudo
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_error "sudo no está instalado"
        print_info "Instala sudo primero: pacman -S sudo"
        exit 1
    fi
    
    # Verificar permisos de sudo
    print_info "Verificando permisos de sudo..."
    if ! sudo -v; then
        print_error "El usuario no tiene permisos de sudo"
        exit 1
    fi
    print_success "Permisos de sudo verificados"
}

# Verificar directorios del dotfiles
check_dotfiles_structure() {
    print_info "Verificando estructura del repositorio..."
    
    local missing_dirs=()
    
    [[ ! -d "$PACKAGES_DIR" ]] && missing_dirs+=("scripts/packages")
    [[ ! -d "$SYSTEM_DIR" ]] && missing_dirs+=("system")
    [[ ! -d "$HOME_DIR" ]] && missing_dirs+=("home")
    [[ ! -d "$CONFIG_DIR" ]] && missing_dirs+=("config")
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        print_error "Faltan directorios necesarios:"
        for dir in "${missing_dirs[@]}"; do
            echo "  ✗ $dir"
        done
        exit 1
    fi
    
    print_success "Estructura del repositorio verificada"
}

# ================================
# Funciones de Instalación de Repositorios
# ================================

# Instalar repositorios de CachyOS
install_cachyos_repo() {
    print_header "INSTALACIÓN DE REPOSITORIOS CACHYOS"
    
    print_info "Los repositorios de CachyOS proporcionan:"
    echo "  • Kernel optimizado (linux-cachyos)"
    echo "  • Paquetes compilados con optimizaciones"
    echo "  • Herramientas de gaming y rendimiento"
    echo ""
    
    if ! ask_yes_no "¿Deseas instalar los repositorios de CachyOS?"; then
        print_warning "Saltando instalación de repositorios CachyOS"
        return 0
    fi
    
    echo ""
    print_info "Creando directorio temporal..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    print_info "[1/3] Descargando repositorio de CachyOS..."
    if ! curl -L https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz; then
        print_error "Error al descargar el repositorio"
        return 1
    fi
    print_success "Repositorio descargado"
    
    print_info "[2/3] Extrayendo archivos..."
    tar xvf cachyos-repo.tar.xz
    cd cachyos-repo
    print_success "Archivos extraídos"
    
    print_info "[3/3] Ejecutando instalador de CachyOS..."
    print_warning "Se te pedirá la contraseña de sudo"
    echo ""
    
    if sudo ./cachyos-repo.sh; then
        echo ""
        print_success "✓ Repositorios de CachyOS instalados correctamente"
    else
        print_error "Error al instalar repositorios de CachyOS"
        return 1
    fi
    
    cd "$USER_HOME"
}

# Activar multilib en pacman
enable_multilib() {
    print_header "ACTIVACIÓN DE MULTILIB"
    
    print_info "Multilib permite instalar paquetes de 32 bits (necesario para gaming y Wine)"
    echo ""
    
    if ! ask_yes_no "¿Deseas activar multilib?"; then
        print_warning "Saltando activación de multilib"
        return 0
    fi
    
    echo ""
    print_info "Verificando estado de multilib..."
    
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_success "Multilib ya está activado"
        return 0
    fi
    
    print_info "Activando multilib en /etc/pacman.conf..."
    
    # Descomentar [multilib] y la línea Include que le sigue
    sudo sed -i '/^\[multilib\]/,/^Include/ s/^#//' /etc/pacman.conf
    
    print_success "✓ Multilib activado correctamente"
}

# ================================
# Funciones de Actualización del Sistema
# ================================

# Actualizar sistema
update_system() {
    print_header "ACTUALIZACIÓN DEL SISTEMA"
    
    print_info "Sincronizando bases de datos y actualizando paquetes..."
    print_warning "Este proceso puede tardar varios minutos"
    echo ""
    
    sudo pacman -Syyu --noconfirm
    
    echo ""
    print_success "✓ Sistema actualizado correctamente"
}

# Configurar sincronización de hora
configure_time_sync() {
    print_header "CONFIGURACIÓN DE SINCRONIZACIÓN DE HORA"
    
    print_info "Activando sincronización automática de hora con NTP..."
    
    if sudo timedatectl set-ntp true; then
        echo ""
        print_success "✓ Sincronización de hora configurada correctamente"
        
        # Mostrar estado actual
        print_info "Estado actual del reloj del sistema:"
        timedatectl status | grep -E "(Local time|Time zone|NTP|synchronized)"
    else
        print_error "Error al configurar sincronización de hora"
        return 1
    fi
}

# ================================
# Funciones de Instalación de Kernel
# ================================

# Instalar kernel CachyOS
install_cachyos_kernel() {
    print_header "INSTALACIÓN DE KERNEL CACHYOS-BORE"
    
    print_info "El kernel CachyOS-BORE incluye:"
    echo "  • Optimizaciones para gaming y baja latencia"
    echo "  • Scheduler BORE (Burst-Oriented Response Enhancer)"
    echo "  • Parches de rendimiento adicionales"
    echo ""
    
    if ! ask_yes_no "¿Deseas instalar el kernel linux-cachyos-bore?"; then
        print_warning "Saltando instalación del kernel CachyOS"
        return 0
    fi
    
    echo ""
    print_info "Instalando kernel linux-cachyos-bore..."
    print_warning "El kernel actual se mantendrá como respaldo"
    echo ""
    
    if sudo pacman -S --needed --noconfirm linux-cachyos-bore linux-cachyos-bore-headers; then
        echo ""
        print_success "✓ Kernel CachyOS-BORE instalado correctamente"
    else
        print_error "Error al instalar el kernel"
        return 1
    fi
}

# Regenerar GRUB
regenerate_grub() {
    print_header "REGENERACIÓN DE GRUB"
    
    print_info "Actualizando configuración de GRUB para incluir el nuevo kernel..."
    
    if ! command -v grub-mkconfig &> /dev/null; then
        print_warning "GRUB no está instalado, saltando regeneración"
        return 0
    fi
    
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
        echo ""
        print_success "✓ Configuración de GRUB regenerada"
        print_info "El nuevo kernel aparecerá en el menú de arranque"
    else
        print_error "Error al regenerar GRUB"
        return 1
    fi
}

# ================================
# Funciones de Instalación de Drivers
# ================================

# Instalar drivers automáticamente
install_drivers() {
    print_header "INSTALACIÓN DE DRIVERS"
    
    print_info "CHWD (CachyOS Hardware Detection) detecta e instala drivers automáticamente"
    echo ""
    
    if ! ask_yes_no "¿Deseas instalar drivers automáticamente?"; then
        print_warning "Saltando instalación de drivers"
        return 0
    fi
    
    echo ""
    print_info "[1/2] Instalando chwd..."
    if ! sudo pacman -S --needed --noconfirm chwd; then
        print_error "Error al instalar chwd"
        return 1
    fi
    print_success "chwd instalado"
    
    echo ""
    print_info "[2/2] Detectando e instalando drivers del sistema..."
    print_warning "Este proceso puede tardar varios minutos"
    echo ""
    
    if sudo chwd -a; then
        echo ""
        print_success "✓ Drivers instalados correctamente"
    else
        print_warning "Hubo problemas al instalar algunos drivers"
        print_info "Puedes revisar manualmente con: sudo chwd -l"
    fi
}

# ================================
# Funciones de Configuración Gaming
# ================================

# Instalar meta-paquete gaming
install_gaming_meta() {
    print_header "INSTALACIÓN DE CONFIGURACIÓN GAMING"
    
    print_info "cachyos-gaming-meta incluye:"
    echo "  • gamemode (optimización de rendimiento en juegos)"
    echo "  • mangohud (overlay de rendimiento)"
    echo "  • wine y dependencias"
    echo "  • Herramientas de compatibilidad"
    echo ""
    
    if ! ask_yes_no "¿Deseas instalar cachyos-gaming-meta?"; then
        print_warning "Saltando instalación de configuración gaming"
        return 0
    fi
    
    echo ""
    print_info "Instalando cachyos-gaming-meta..."
    
    if sudo pacman -S --needed --noconfirm cachyos-gaming-meta; then
        echo ""
        print_success "✓ Configuración gaming instalada correctamente"
    else
        print_error "Error al instalar cachyos-gaming-meta"
        return 1
    fi
}

# ================================
# Funciones de Instalación de AUR Helper
# ================================

# Instalar paru
install_paru() {
    print_header "INSTALACIÓN DE PARU (AUR HELPER)"
    
    print_info "Paru es un AUR helper escrito en Rust que facilita la instalación de paquetes del AUR"
    echo ""
    
    if command -v paru &> /dev/null; then
        print_success "Paru ya está instalado"
        return 0
    fi
    
    if ! ask_yes_no "¿Deseas instalar paru?"; then
        print_warning "Saltando instalación de paru"
        return 0
    fi
    
    echo ""
    print_info "Verificando dependencias..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    print_info "Clonando repositorio de paru..."
    cd "$TEMP_DIR"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    
    print_info "Compilando e instalando paru..."
    makepkg -si --noconfirm
    
    cd "$USER_HOME"
    
    echo ""
    print_success "✓ Paru instalado correctamente"
}

# ================================
# Funciones de Instalación de Paquetes
# ================================

# Instalar paquetes desde archivos
install_packages() {
    print_header "INSTALACIÓN DE PAQUETES"
    
    print_info "Instalando paquetes desde la carpeta packages/..."
    echo ""
    
    local package_files=(
        "$PACKAGES_DIR/essential.txt"
        "$PACKAGES_DIR/shell.txt"
        "$PACKAGES_DIR/development.txt"
        "$PACKAGES_DIR/desktop.txt"
        "$PACKAGES_DIR/applications.txt"
    )
    
    local aur_file="$PACKAGES_DIR/aur.txt"
    
    # Instalar paquetes oficiales
    for file in "${package_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_warning "Archivo no encontrado: $(basename "$file")"
            continue
        fi
        
        local category=$(basename "$file" .txt)
        print_info "Categoría: $category"
        
        # Leer paquetes (ignorar líneas vacías y comentarios)
        local packages=()
        while IFS= read -r line; do
            # Ignorar líneas vacías y comentarios
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            packages+=("$line")
        done < "$file"
        
        if [[ ${#packages[@]} -eq 0 ]]; then
            print_warning "No hay paquetes en $category"
            continue
        fi
        
        echo "  Paquetes a instalar: ${#packages[@]}"
        
        if sudo pacman -S --needed --noconfirm "${packages[@]}"; then
            print_success "✓ Paquetes de $category instalados"
        else
            print_warning "Algunos paquetes de $category no se pudieron instalar"
        fi
        echo ""
    done
    
    # Instalar paquetes del AUR si paru está disponible
    if [[ -f "$aur_file" ]] && command -v paru &> /dev/null; then
        print_info "Categoría: aur"
        
        local aur_packages=()
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            aur_packages+=("$line")
        done < "$aur_file"
        
        if [[ ${#aur_packages[@]} -gt 0 ]]; then
            echo "  Paquetes AUR a instalar: ${#aur_packages[@]}"
            
            if paru -S --needed --noconfirm "${aur_packages[@]}"; then
                print_success "✓ Paquetes AUR instalados"
            else
                print_warning "Algunos paquetes AUR no se pudieron instalar"
            fi
        fi
    fi
    
    echo ""
    print_success "✓ Instalación de paquetes completada"
}

# ================================
# Funciones de Instalación de Dotfiles
# ================================

# Instalar fuentes del sistema
install_fonts() {
    print_header "INSTALACIÓN DE FUENTES"
    
    local fonts_dir="$SYSTEM_DIR/fonts"
    
    if [[ ! -d "$fonts_dir" ]]; then
        print_warning "Directorio de fuentes no encontrado"
        return 0
    fi
    
    print_info "Instalando fuentes en /usr/share/fonts..."
    
    # Crear directorio si no existe
    sudo mkdir -p /usr/share/fonts
    
    # Copiar cada directorio de fuente
    local font_count=0
    for font_dir in "$fonts_dir"/*/ ; do
        if [[ -d "$font_dir" ]]; then
            local font_name=$(basename "$font_dir")
            print_info "Instalando fuente: $font_name"
            sudo cp -r "$font_dir" /usr/share/fonts
            font_count=$((font_count + 1))
        fi
    done
    
    # Actualizar caché de fuentes
    print_info "Actualizando caché de fuentes..."
    sudo fc-cache -fv
    
    echo ""
    print_success "✓ $font_count fuentes instaladas correctamente"
}

# Configurar SDDM
configure_sddm() {
    print_header "CONFIGURACIÓN DE SDDM"
    
    local sddm_theme_dir="$SYSTEM_DIR/sddm/sddm-pixel"
    
    if [[ ! -d "$sddm_theme_dir" ]]; then
        print_warning "Tema de SDDM no encontrado"
        return 0
    fi
    
    if ! ask_yes_no "¿Deseas instalar y configurar el tema SDDM?"; then
        print_warning "Saltando configuración de SDDM"
        return 0
    fi
    
    echo ""
    
    # Verificar si SDDM está instalado
    if ! command -v sddm &> /dev/null; then
        print_warning "SDDM no está instalado"
        if ask_yes_no "¿Deseas instalar SDDM?"; then
            sudo pacman -S --needed --noconfirm sddm
        else
            return 0
        fi
    fi
    
    print_info "[1/3] Copiando tema a /usr/share/sddm/themes..."
    sudo mkdir -p /usr/share/sddm/themes
    sudo rm -rf /usr/share/sddm/themes/sddm-pixel
    sudo cp -r "$sddm_theme_dir" /usr/share/sddm/themes/
    print_success "Tema copiado"
    
    print_info "[2/3] Configurando SDDM..."
    
    # Crear o actualizar /etc/sddm.conf
    if [[ -f /etc/sddm.conf ]]; then
        sudo cp /etc/sddm.conf /etc/sddm.conf.bak
    fi
    
    sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Theme]
Current=sddm-pixel

[General]
Theme=sddm-pixel
EOF
    
    print_success "Configuración actualizada"
    
    print_info "[3/4] Configurando teclado virtual..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/virtualkbd.conf > /dev/null << 'EOF'
# Virtual Keyboard Configuration
# Manual activation via button

[General]
# InputMethod=qtvirtualkeyboard
EOF
    
    print_success "Teclado virtual configurado"
    
    print_info "[4/4] Habilitando servicio SDDM..."
    sudo systemctl enable sddm.service
    print_success "Servicio SDDM habilitado"
    
    echo ""
    print_success "✓ Tema SDDM instalado correctamente"
    print_info "SDDM se iniciará automáticamente en el próximo arranque"
}

# Instalar archivos del home
install_home_files() {
    print_header "INSTALACIÓN DE ARCHIVOS HOME"
    
    print_info "Copiando archivos de $HOME_DIR a $USER_HOME..."
    echo ""
    
    local copied_count=0
    
    # Copiar cada directorio/archivo del home
    for item in "$HOME_DIR"/*; do
        if [[ -e "$item" ]]; then
            local item_name=$(basename "$item")
            print_info "Copiando: $item_name"
            
            # Crear backup si existe
            if [[ -e "$USER_HOME/$item_name" ]]; then
                print_warning "Ya existe $item_name, creando backup..."
                mv "$USER_HOME/$item_name" "$USER_HOME/${item_name}.backup.$(date +%Y%m%d_%H%M%S)"
            fi
            
            cp -r "$item" "$USER_HOME/"
            copied_count=$((copied_count + 1))
        fi
    done
    
    echo ""
    print_success "✓ $copied_count elementos copiados al home"
}

# Instalar archivos de configuración
install_config_files() {
    print_header "INSTALACIÓN DE ARCHIVOS DE CONFIGURACIÓN"
    
    print_info "Copiando configuraciones a $USER_HOME/.config..."
    echo ""
    
    # Crear directorio .config si no existe
    mkdir -p "$USER_HOME/.config"
    
    local copied_count=0
    
    # Copiar cada directorio de configuración
    for config_item in "$CONFIG_DIR"/*; do
        if [[ -d "$config_item" ]]; then
            local config_name=$(basename "$config_item")
            print_info "Copiando configuración: $config_name"
            
            # Crear backup si existe
            if [[ -e "$USER_HOME/.config/$config_name" ]]; then
                print_warning "Ya existe configuración de $config_name, creando backup..."
                mv "$USER_HOME/.config/$config_name" "$USER_HOME/.config/${config_name}.backup.$(date +%Y%m%d_%H%M%S)"
            fi
            
            cp -r "$config_item" "$USER_HOME/.config/"
            copied_count=$((copied_count + 1))
        fi
    done
    
    echo ""
    print_success "✓ $copied_count configuraciones instaladas"
}

# Configurar aplicaciones (placeholder)
configure_apps() {
    print_header "CONFIGURACIÓN DE APLICACIONES"
    
    print_info "Función reservada para futuras configuraciones de aplicaciones"
    echo ""
    print_warning "No hay configuraciones de apps por el momento"
    
    # Aquí se agregarán configuraciones específicas de aplicaciones en el futuro
    # Ejemplos: VSCode, Zed, Spicetify, etc.
}

# ================================
# Funciones de Configuración Final
# ================================

# Aplicar tema
apply_theme() {
    print_header "APLICACIÓN DE TEMA"
    
    local theme_script="$USER_HOME/.local/bin/theme-selector.sh"
    
    if [[ ! -f "$theme_script" ]]; then
        print_warning "theme-selector.sh no encontrado"
        print_info "Asegúrate de que los archivos home se hayan copiado correctamente"
        return 0
    fi
    
    print_info "Aplicando tema Catppuccin Mocha..."
    echo ""
    
    # Hacer el script ejecutable
    chmod +x "$theme_script"
    
    # Ejecutar theme-selector
    if bash "$theme_script" generate catppuccin-mocha --apply; then
        echo ""
        print_success "✓ Tema Catppuccin Mocha aplicado correctamente"
    else
        print_warning "Hubo problemas al aplicar el tema"
        print_info "Puedes aplicarlo manualmente más tarde"
    fi
}

# ================================
# Funciones de Limpieza
# ================================

# Limpiar archivos temporales
cleanup() {
    print_header "LIMPIEZA DE ARCHIVOS TEMPORALES"
    
    if [[ -d "$TEMP_DIR" ]]; then
        print_info "Eliminando directorio temporal..."
        rm -rf "$TEMP_DIR"
        print_success "✓ Archivos temporales eliminados"
    fi
}

# ================================
# Funciones de Finalización
# ================================

# Mostrar resumen final
show_summary() {
    print_header "¡INSTALACIÓN COMPLETADA!"
    
    echo ""
    print_success "Los dotfiles se han instalado exitosamente"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 RESUMEN DE LA INSTALACIÓN:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ✓ Repositorios CachyOS configurados"
    echo "  ✓ Multilib activado"
    echo "  ✓ Sistema actualizado"
    echo "  ✓ Kernel CachyOS-BORE instalado"
    echo "  ✓ Drivers instalados automáticamente"
    echo "  ✓ Configuración gaming instalada"
    echo "  ✓ Paru (AUR helper) instalado"
    echo "  ✓ Paquetes esenciales instalados"
    echo "  ✓ Fuentes del sistema instaladas"
    echo "  ✓ Tema SDDM configurado"
    echo "  ✓ Archivos home copiados"
    echo "  ✓ Configuraciones instaladas"
    echo "  ✓ Tema Catppuccin Mocha aplicado"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 PRÓXIMOS PASOS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Reinicia el sistema para aplicar todos los cambios:"
    echo -e "   ${BLUE}→${NC} reboot"
    echo ""
    echo -e "${GREEN}2.${NC} En el arranque, selecciona el kernel CachyOS-BORE en GRUB"
    echo ""
    echo -e "${GREEN}3.${NC} Verifica que todo funcione correctamente:"
    echo -e "   ${BLUE}→${NC} uname -r  (para ver el kernel activo)"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}ℹ️  NOTAS IMPORTANTES:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  • Los archivos originales se respaldaron con extensión .backup"
    echo "  • Puedes cambiar temas con: theme-selector.sh"
    echo "  • Para actualizar el sistema: sudo pacman -Syu"
    echo "  • Para paquetes AUR: paru -Syu"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ================================
# Función Principal
# ================================

main() {
    clear
    print_header "INSTALADOR DE DOTFILES - FHUAQUISTO"
    
    echo ""
    echo "Bienvenido al instalador automatizado de dotfiles"
    echo ""
    print_info "Este script instalará y configurará:"
    echo "  • Repositorios CachyOS optimizados"
    echo "  • Kernel CachyOS-BORE (gaming y baja latencia)"
    echo "  • Drivers automáticos del sistema"
    echo "  • Configuración gaming completa"
    echo "  • Paquetes esenciales y aplicaciones"
    echo "  • Dotfiles personalizados (configs, temas, scripts)"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_warning "⚠️  ADVERTENCIAS IMPORTANTES:"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  • Este proceso puede tardar entre 30-60 minutos"
    echo "  • Se requiere conexión a internet estable"
    echo "  • Se instalarán varios GB de paquetes"
    echo "  • Los archivos existentes se respaldarán automáticamente"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if ! ask_yes_no "¿Deseas continuar con la instalación?"; then
        print_info "Instalación cancelada por el usuario"
        exit 0
    fi
    
    echo ""
    
    # Validaciones iniciales
    check_not_root
    check_sudo
    check_dotfiles_structure
    
    # Mantener sudo activo
    sudo -v
    
    # Instalación paso a paso
    install_cachyos_repo
    enable_multilib
    update_system
    configure_time_sync
    install_cachyos_kernel
    regenerate_grub
    install_drivers
    install_gaming_meta
    install_paru
    install_packages
    
    # Instalación de dotfiles
    install_fonts
    configure_sddm
    install_home_files
    install_config_files
    configure_apps
    apply_theme
    
    # Limpieza y finalización
    cleanup
    show_summary
    
    echo ""
    print_success "¡Instalación completada exitosamente!"
    print_info "Recuerda reiniciar el sistema para aplicar todos los cambios"
    echo ""
}

# ================================
# Manejo de Errores y Ejecución
# ================================

# Manejo de errores
trap 'print_error "Error detectado en la línea $LINENO. Ejecutando limpieza..."; cleanup; exit 1' ERR

# Manejo de interrupción
trap 'echo ""; print_warning "Instalación interrumpida por el usuario"; cleanup; exit 130' INT

# Ejecutar script principal
main "$@"