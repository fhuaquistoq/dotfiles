#!/usr/bin/env bash

# Script de configuración de Dual Boot con Windows
# Ejecutar después de instalar y configurar Arch Linux

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Verificar que se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root o con sudo"
        print_info "Ejecuta: sudo $0"
        exit 1
    fi
}

# Verificar que GRUB está instalado
check_grub() {
    if ! command -v grub-mkconfig &> /dev/null; then
        print_error "GRUB no está instalado"
        print_info "Instala GRUB antes de ejecutar este script"
        exit 1
    fi
}

# Instalar paquetes necesarios
install_packages() {
    print_header "INSTALACIÓN DE PAQUETES NECESARIOS"
    
    print_info "Instalando os-prober y ntfs-3g..."
    pacman -S --needed --noconfirm os-prober ntfs-3g
    
    print_success "Paquetes instalados correctamente"
}

# Detectar partición de Windows
detect_windows_partition() {
    print_header "DETECCIÓN DE PARTICIÓN DE WINDOWS"
    
    print_info "Buscando particiones de Windows..."
    echo ""
    
    # Listar particiones NTFS
    local ntfs_partitions=()
    while IFS= read -r line; do
        ntfs_partitions+=("$line")
    done < <(lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -i ntfs | awk '{print $1}')
    
    if [[ ${#ntfs_partitions[@]} -eq 0 ]]; then
        print_error "No se encontraron particiones NTFS (Windows)"
        print_info "Verifica que Windows esté instalado en este sistema"
        exit 1
    fi
    
    print_success "Particiones NTFS encontradas:"
    echo ""
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -E "NAME|ntfs"
    echo ""
}

# Montar partición de Windows
mount_windows() {
    print_header "MONTAJE DE PARTICIÓN DE WINDOWS"
    
    print_info "Selecciona la partición de Windows que contiene el bootloader"
    print_warning "Normalmente es la partición EFI si es UEFI, o la partición del sistema si es BIOS"
    echo ""
    
    # Mostrar todas las particiones
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
    echo ""
    
    read -p "Ingresa la partición de Windows (ejemplo: sda1, nvme0n1p1): " win_partition
    
    WIN_PARTITION="/dev/$win_partition"
    
    if [[ ! -b "$WIN_PARTITION" ]]; then
        print_error "La partición $WIN_PARTITION no existe"
        exit 1
    fi
    
    print_info "Creando punto de montaje temporal..."
    mkdir -p /mnt/windows
    
    print_info "Montando $WIN_PARTITION en /mnt/windows..."
    
    # Intentar montar la partición
    if mount "$WIN_PARTITION" /mnt/windows 2>/dev/null; then
        print_success "Partición montada correctamente"
        echo ""
        print_info "Contenido de la partición:"
        ls -la /mnt/windows | head -15
    else
        print_warning "No se pudo montar la partición automáticamente"
        print_info "Esto es normal si es una partición EFI"
    fi
}

# Configurar GRUB para detectar Windows
configure_grub() {
    print_header "CONFIGURACIÓN DE GRUB"
    
    print_info "Habilitando os-prober en GRUB..."
    
    # Verificar si el archivo de configuración existe
    if [[ ! -f /etc/default/grub ]]; then
        print_error "No se encontró /etc/default/grub"
        exit 1
    fi
    
    # Descomentar GRUB_DISABLE_OS_PROBER si está comentado
    if grep -q "^#GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
        print_info "Descomentando GRUB_DISABLE_OS_PROBER..."
        sed -i 's/^#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub
    fi
    
    # Asegurar que GRUB_DISABLE_OS_PROBER=false
    if grep -q "^GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
        print_info "Cambiando GRUB_DISABLE_OS_PROBER a false..."
        sed -i 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    elif ! grep -q "^GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        print_info "Agregando GRUB_DISABLE_OS_PROBER=false..."
        echo "" >> /etc/default/grub
        echo "# Enable os-prober to detect other operating systems" >> /etc/default/grub
        echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    fi
    
    print_success "Configuración de GRUB actualizada"
}

# Regenerar configuración de GRUB
regenerate_grub() {
    print_header "REGENERACIÓN DE GRUB"
    
    print_info "Ejecutando os-prober para detectar sistemas operativos..."
    os-prober || print_warning "os-prober no encontró otros sistemas (esto puede ser normal)"
    
    echo ""
    print_info "Regenerando configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg
    
    print_success "Configuración de GRUB regenerada"
    
    # Verificar si Windows fue detectado
    if grep -qi "windows" /boot/grub/grub.cfg; then
        print_success "¡Windows detectado en GRUB!"
    else
        print_warning "Windows no fue detectado automáticamente"
        print_info "Posibles soluciones:"
        echo "  1. Verifica que la partición EFI de Windows esté montada"
        echo "  2. Reinicia y verifica si aparece en el menú de GRUB"
        echo "  3. Ejecuta manualmente: os-prober && grub-mkconfig -o /boot/grub/grub.cfg"
    fi
}

# Limpiar montajes
cleanup() {
    print_header "LIMPIEZA"
    
    if mountpoint -q /mnt/windows 2>/dev/null; then
        print_info "Desmontando partición de Windows..."
        umount /mnt/windows
    fi
    
    if [[ -d /mnt/windows ]]; then
        print_info "Eliminando punto de montaje temporal..."
        rmdir /mnt/windows 2>/dev/null || true
    fi
    
    print_success "Limpieza completada"
}

# Mostrar resultado final
show_result() {
    print_header "CONFIGURACIÓN DE DUAL BOOT COMPLETADA"
    
    print_success "¡El dual boot ha sido configurado correctamente!"
    echo ""
    echo -e "${BLUE}INFORMACIÓN:${NC}"
    echo "  • os-prober: Instalado"
    echo "  • ntfs-3g: Instalado"
    echo "  • GRUB: Configurado para detectar Windows"
    echo ""
    echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
    echo ""
    echo "1. Reinicia el sistema:"
    echo -e "   ${GREEN}reboot${NC}"
    echo ""
    echo "2. En el arranque, deberías ver el menú de GRUB con:"
    echo "   • Arch Linux"
    echo "   • Windows (o Windows Boot Manager)"
    echo ""
    echo -e "${BLUE}SOLUCIÓN DE PROBLEMAS:${NC}"
    echo ""
    echo "Si Windows no aparece en el menú:"
    echo "  1. Arranca en Arch Linux"
    echo "  2. Ejecuta: sudo os-prober"
    echo "  3. Ejecuta: sudo grub-mkconfig -o /boot/grub/grub.cfg"
    echo "  4. Reinicia nuevamente"
    echo ""
    
    if [[ -d /sys/firmware/efi/efivars ]]; then
        print_info "Sistema UEFI detectado"
        echo "Verifica que ambos sistemas usen el mismo modo de arranque (UEFI)"
    else
        print_info "Sistema BIOS detectado"
        echo "Verifica que ambos sistemas usen el mismo modo de arranque (Legacy BIOS)"
    fi
    echo ""
}

# Función principal
main() {
    print_header "CONFIGURACIÓN DE DUAL BOOT - ARCH LINUX + WINDOWS"
    
    print_warning "Este script configurará GRUB para detectar Windows"
    echo ""
    echo "Requisitos:"
    echo "  • Arch Linux ya instalado y funcionando"
    echo "  • Windows instalado en otra partición"
    echo "  • GRUB instalado como bootloader"
    echo ""
    read -p "¿Deseas continuar? (s/n): " confirm
    
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        print_info "Operación cancelada"
        exit 0
    fi
    
    check_root
    check_grub
    install_packages
    detect_windows_partition
    mount_windows
    configure_grub
    regenerate_grub
    cleanup
    show_result
    
    print_success "¡Configuración completada exitosamente!"
}

# Manejo de errores
trap 'print_error "Error en la línea $LINENO. Limpiando..."; cleanup; exit 1' ERR

# Ejecutar script
main
