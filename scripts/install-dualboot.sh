#!/usr/bin/env bash

# ================================================
# INSTALADOR DE ARCH LINUX - PARTE 3 (DUAL BOOT)
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
# Funciones de Validación
# ================================

# Verificar que se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (usa 'sudo bash install-dualboot.sh')"
        print_info "Ejecuta: sudo $0"
        exit 1
    fi
    print_success "Ejecutando con permisos de root"
}

# Verificar que GRUB está instalado
check_grub() {
    if ! command -v grub-mkconfig &> /dev/null; then
        print_error "GRUB no está instalado en el sistema"
        print_info "Debes instalar GRUB antes de configurar dual boot"
        print_info "Ejecuta primero el script config-arch.sh"
        exit 1
    fi
    print_success "GRUB detectado en el sistema"
}

# ================================
# Funciones de Instalación de Paquetes
# ================================

# Instalar paquetes necesarios
install_packages() {
    print_header "INSTALACIÓN DE PAQUETES NECESARIOS"
    
    print_info "Paquetes requeridos para dual boot:"
    echo "  • os-prober  (detecta otros sistemas operativos)"
    echo "  • ntfs-3g    (soporte para particiones NTFS de Windows)"
    echo ""
    
    print_info "Instalando paquetes..."
    pacman -S --needed --noconfirm os-prober ntfs-3g
    
    echo ""
    print_success "✓ Paquetes instalados correctamente"
}

# ================================
# Funciones de Detección y Montaje
# ================================

# Detectar partición de Windows
detect_windows_partition() {
    print_header "DETECCIÓN DE PARTICIONES DE WINDOWS"
    
    print_info "Buscando particiones NTFS (Windows) en el sistema..."
    echo ""
    
    # Listar particiones NTFS
    local ntfs_partitions=()
    while IFS= read -r line; do
        ntfs_partitions+=("$line")
    done < <(lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -i ntfs | awk '{print $1}')
    
    if [[ ${#ntfs_partitions[@]} -eq 0 ]]; then
        print_error "No se encontraron particiones NTFS (Windows)"
        print_info "Verifica que Windows esté instalado en este sistema"
        print_warning "Si usas Windows 11/10, las particiones deberían ser NTFS"
        exit 1
    fi
    
    print_success "¡Particiones NTFS encontradas!"
    echo ""
    print_info "Particiones detectadas:"
    echo ""
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -E "NAME|ntfs"
    echo ""
}

# Montar partición de Windows
mount_windows() {
    print_header "MONTAJE DE PARTICIÓN DE WINDOWS"
    
    print_info "Necesitas seleccionar la partición del bootloader de Windows"
    echo ""
    print_warning "📋 Guía de selección:"
    echo "  • UEFI:  Selecciona la partición EFI (tipo vfat, ~100-500 MB)"
    echo "  • BIOS:  Selecciona la partición del sistema Windows (tipo ntfs)"
    echo ""
    
    # Mostrar todas las particiones
    print_info "Particiones disponibles en el sistema:"
    echo ""
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
    echo ""
    
    read -p "Ingresa la partición de Windows (ejemplo: sda1, nvme0n1p1): " win_partition
    
    WIN_PARTITION="/dev/$win_partition"
    
    if [[ ! -b "$WIN_PARTITION" ]]; then
        print_error "La partición $WIN_PARTITION no existe"
        print_info "Verifica el nombre e intenta nuevamente"
        exit 1
    fi
    
    echo ""
    print_success "Partición seleccionada: $WIN_PARTITION"
    echo ""
    
    print_info "Creando punto de montaje temporal..."
    mkdir -p /mnt/windows
    print_success "Directorio /mnt/windows creado"
    
    print_info "Intentando montar $WIN_PARTITION..."
    
    # Intentar montar la partición
    if mount "$WIN_PARTITION" /mnt/windows 2>/dev/null; then
        print_success "✓ Partición montada correctamente en /mnt/windows"
        echo ""
        print_info "Contenido de la partición (primeros 15 archivos):"
        ls -la /mnt/windows | head -15
    else
        print_warning "No se pudo montar la partición automáticamente"
        print_info "Esto es normal si seleccionaste una partición EFI"
        print_info "El script continuará con la configuración"
    fi
}

# ================================
# Funciones de Configuración de GRUB
# ================================

# Configurar GRUB para detectar Windows
configure_grub() {
    print_header "CONFIGURACIÓN DE GRUB"
    
    print_info "Configurando GRUB para detectar sistemas operativos adicionales..."
    echo ""
    
    # Verificar si el archivo de configuración existe
    if [[ ! -f /etc/default/grub ]]; then
        print_error "No se encontró el archivo /etc/default/grub"
        print_info "Verifica que GRUB esté correctamente instalado"
        exit 1
    fi
    
    print_info "[1/3] Verificando configuración actual..."
    
    # Descomentar GRUB_DISABLE_OS_PROBER si está comentado
    if grep -q "^#GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
        print_info "[2/3] Descomentando GRUB_DISABLE_OS_PROBER..."
        sed -i 's/^#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub
        print_success "Línea descomentada"
    fi
    
    # Asegurar que GRUB_DISABLE_OS_PROBER=false
    if grep -q "^GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
        print_info "[3/3] Habilitando os-prober..."
        sed -i 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        print_success "os-prober habilitado"
    elif ! grep -q "^GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        print_info "[3/3] Agregando configuración de os-prober..."
        echo "" >> /etc/default/grub
        echo "# Enable os-prober to detect other operating systems" >> /etc/default/grub
        echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
        print_success "Configuración agregada"
    else
        print_info "[2-3/3] os-prober ya está habilitado"
    fi
    
    echo ""
    print_success "✓ Configuración de GRUB actualizada correctamente"
}

# Regenerar configuración de GRUB
regenerate_grub() {
    print_header "REGENERACIÓN DE CONFIGURACIÓN DE GRUB"
    
    print_info "[1/2] Ejecutando os-prober para buscar sistemas operativos..."
    print_warning "Este proceso puede tardar unos segundos"
    echo ""
    
    os-prober || print_warning "os-prober no encontró otros sistemas (puede ser normal)"
    
    echo ""
    print_info "[2/2] Generando nueva configuración de GRUB..."
    print_info "Analizando sistemas detectados y creando menú de arranque"
    echo ""
    
    grub-mkconfig -o /boot/grub/grub.cfg
    
    echo ""
    print_success "✓ Configuración de GRUB regenerada exitosamente"
    echo ""
    
    # Verificar si Windows fue detectado
    print_info "Verificando detección de Windows..."
    if grep -qi "windows" /boot/grub/grub.cfg; then
        print_success "🎉 ¡Windows detectado correctamente en GRUB!"
        echo ""
        print_info "Windows aparecerá en el menú de arranque"
    else
        print_warning "⚠️  Windows no fue detectado automáticamente"
        echo ""
        print_info "Posibles soluciones:"
        echo "  1. Verifica que la partición EFI de Windows esté montada"
        echo "  2. Reinicia y verifica si aparece en el menú de GRUB"
        echo "  3. Ejecuta manualmente:"
        echo "     sudo os-prober"
        echo "     sudo grub-mkconfig -o /boot/grub/grub.cfg"
    fi
}

# ================================
# Funciones de Limpieza
# ================================

# Limpiar montajes
cleanup() {
    print_header "LIMPIEZA DE ARCHIVOS TEMPORALES"
    
    if mountpoint -q /mnt/windows 2>/dev/null; then
        print_info "Desmontando partición de Windows..."
        umount /mnt/windows
        print_success "Partición desmontada"
    fi
    
    if [[ -d /mnt/windows ]]; then
        print_info "Eliminando punto de montaje temporal..."
        rmdir /mnt/windows 2>/dev/null || true
        print_success "Directorio eliminado"
    fi
    
    echo ""
    print_success "✓ Limpieza completada"
}

# ================================
# Funciones de Finalización
# ================================

# Mostrar resultado final
show_result() {
    print_header "¡DUAL BOOT CONFIGURADO EXITOSAMENTE!"
    
    echo ""
    print_success "El dual boot entre Arch Linux y Windows ha sido configurado"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 RESUMEN DE LA CONFIGURACIÓN:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ✓ os-prober instalado y habilitado"
    echo "  ✓ ntfs-3g instalado (soporte NTFS)"
    echo "  ✓ GRUB configurado para detectar Windows"
    echo "  ✓ Configuración de GRUB regenerada"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 PRÓXIMOS PASOS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Reinicia el sistema:"
    echo -e "   ${BLUE}→${NC} reboot"
    echo ""
    echo -e "${GREEN}2.${NC} En el arranque verás el menú de GRUB con:"
    echo "   • Arch Linux (sistema principal)"
    echo "   • Windows Boot Manager (Windows)"
    echo "   • Opciones avanzadas"
    echo ""
    echo -e "${GREEN}3.${NC} Usa las flechas del teclado para seleccionar el sistema"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔧 SOLUCIÓN DE PROBLEMAS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_warning "Si Windows NO aparece en el menú de arranque:"
    echo ""
    echo -e "${GREEN}1.${NC} Arranca en Arch Linux"
    echo ""
    echo -e "${GREEN}2.${NC} Ejecuta estos comandos:"
    echo -e "   ${BLUE}→${NC} sudo os-prober"
    echo -e "   ${BLUE}→${NC} sudo grub-mkconfig -o /boot/grub/grub.cfg"
    echo ""
    echo -e "${GREEN}3.${NC} Reinicia nuevamente:"
    echo -e "   ${BLUE}→${NC} reboot"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}ℹ️  INFORMACIÓN ADICIONAL:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ -d /sys/firmware/efi/efivars ]]; then
        print_info "Modo de arranque: UEFI (moderno)"
        echo ""
        print_warning "Verifica que ambos sistemas usen el mismo modo:"
        echo "  • Arch Linux: UEFI ✓"
        echo "  • Windows: Debe estar en modo UEFI"
    else
        print_info "Modo de arranque: BIOS Legacy (tradicional)"
        echo ""
        print_warning "Verifica que ambos sistemas usen el mismo modo:"
        echo "  • Arch Linux: BIOS Legacy ✓"
        echo "  • Windows: Debe estar en modo BIOS Legacy"
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ================================
# Función Principal
# ================================

# Función principal
main() {
    clear
    print_header "CONFIGURACIÓN DE DUAL BOOT - ARCH LINUX + WINDOWS"
    
    echo ""
    echo "Bienvenido al asistente de configuración de dual boot"
    echo ""
    print_info "Este script configurará GRUB para detectar Windows y crear un menú de arranque"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 REQUISITOS PREVIOS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ✓ Arch Linux instalado y funcionando"
    echo "  ✓ Windows instalado en otra partición"
    echo "  ✓ GRUB instalado como bootloader"
    echo "  ✓ Ambos sistemas usando el mismo modo de arranque (UEFI o BIOS)"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_warning "⚠️  Este proceso modificará la configuración de GRUB"
    print_info "Presiona Ctrl+C en cualquier momento para cancelar"
    echo ""
    
    if ! ask_yes_no "¿Deseas continuar con la configuración?"; then
        print_info "Operación cancelada por el usuario"
        exit 0
    fi
    
    echo ""
    
    # Ejecutar pasos de configuración
    check_root
    check_grub
    install_packages
    detect_windows_partition
    mount_windows
    configure_grub
    regenerate_grub
    cleanup
    show_result
    
    echo ""
    print_success "¡Configuración de dual boot completada exitosamente!"
    print_info "Recuerda reiniciar el sistema para ver los cambios"
    echo ""
}

# ================================
# Manejo de Errores y Ejecución
# ================================

# Manejo de errores
trap 'print_error "Error detectado en la línea $LINENO. Ejecutando limpieza..."; cleanup; exit 1' ERR

# Ejecutar script principal
main
