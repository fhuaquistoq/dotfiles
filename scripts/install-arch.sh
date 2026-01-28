#!/usr/bin/env bash

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
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root"
   exit 1
fi

# Variables globales
DISK=""
BOOT_PARTITION=""
SWAP_PARTITION=""
ROOT_PARTITION=""
BOOT_SIZE="512M"
SWAP_SIZE="2G"
WIPE_DISK="no"

# Mostrar discos disponibles
show_disks() {
    print_header "DISCOS DISPONIBLES"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    echo ""
}

# Seleccionar disco
select_disk() {
    print_header "SELECCIÓN DE DISCO"

    mapfile -t DISKS < <(lsblk -dpno NAME,SIZE,MODEL | grep -E "/dev/(sd|nvme|vd)")

    if [[ ${#DISKS[@]} -eq 0 ]]; then
        print_error "No se encontraron discos disponibles"
        exit 1
    fi

    echo "Discos disponibles:"
    for i in "${!DISKS[@]}"; do
        echo "$((i+1))) ${DISKS[$i]}"
    done
    echo ""

    while true; do
        read -p "Selecciona el disco por número: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#DISKS[@]} )); then
            DISK=$(echo "${DISKS[$((choice-1))]}" | awk '{print $1}')
            print_success "Disco seleccionado: $DISK"
            lsblk "$DISK"
            break
        else
            print_error "Selección inválida"
        fi
    done
}

# Preguntar si borrar todo el disco
ask_partitioning() {
    print_header "PARTICIONADO DEL DISCO"

    read -p "¿Deseas particionar el disco ahora con cfdisk? (s/n): " confirm
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        print_info "Abriendo cfdisk en $DISK"
        cfdisk "$DISK"
    else
        print_info "Usando particiones existentes"
    fi

    print_info "Particiones actuales:"
    lsblk "$DISK"
}

# Configurar tamaños de particiones
select_partitions() {
    print_header "ASIGNACIÓN DE PARTICIONES"

    echo "Particiones disponibles:"
    lsblk -lp "$DISK"
    echo ""

    while true; do
        read -p "Ingresa la partición EFI/BOOT (ej: /dev/sda1): " BOOT_PARTITION
        [[ -b "$BOOT_PARTITION" ]] && break
        print_error "Partición inválida"
    done

    while true; do
        read -p "Ingresa la partición SWAP (ej: /dev/sda2): " SWAP_PARTITION
        [[ -b "$SWAP_PARTITION" ]] && break
        print_error "Partición inválida"
    done

    while true; do
        read -p "Ingresa la partición ROOT (ej: /dev/sda3): " ROOT_PARTITION
        [[ -b "$ROOT_PARTITION" ]] && break
        print_error "Partición inválida"
    done

    print_success "Resumen:"
    echo "BOOT: $BOOT_PARTITION"
    echo "SWAP: $SWAP_PARTITION"
    echo "ROOT: $ROOT_PARTITION"
    echo ""

    read -p "¿Continuar con estas particiones? (s/n): " confirm
    [[ "$confirm" == "s" || "$confirm" == "S" ]] || exit 0
}

# Crear particiones
format_partitions() {
    print_header "FORMATEANDO PARTICIONES"

    print_warning "ESTO BORRARÁ LOS DATOS DE LAS PARTICIONES SELECCIONADAS"
    read -p "Escribe 'SI' para continuar: " confirm
    [[ "$confirm" == "SI" ]] || exit 0

    print_info "Formateando BOOT como FAT32..."
    mkfs.fat -F32 "$BOOT_PARTITION"

    print_info "Configurando SWAP..."
    mkswap "$SWAP_PARTITION"

    print_info "Formateando ROOT como ext4..."
    mkfs.ext4 -F "$ROOT_PARTITION"

    print_success "Formateo completado"
}

# Montar particiones
mount_partitions() {
    print_header "MONTANDO PARTICIONES"

    print_info "Montando ROOT en /mnt..."
    mount "$ROOT_PARTITION" /mnt

    print_info "Creando /mnt/boot..."
    mkdir -p /mnt/boot

    print_info "Montando BOOT..."
    mount "$BOOT_PARTITION" /mnt/boot

    print_info "Activando SWAP..."
    swapon "$SWAP_PARTITION"

    print_success "Particiones montadas correctamente"
    echo ""
    lsblk
    echo ""
    df -h /mnt
    swapon --show
}

config_keyring() {
    print_header "CONFIGURANDO KEYRING DE PACMAN"

    print_info "Inicializando keyring..."
    pacman-key --init
    if [[ $? -ne 0 ]]; then
        print_error "Error al inicializar el keyring"
        exit 1
    fi
    print_success "Keyring inicializado"

    print_info "Poblando keyring con claves oficiales de Arch Linux..."
    pacman-key --populate archlinux
    if [[ $? -ne 0 ]]; then
        print_error "Error al poblar el keyring"
        exit 1
    fi
    print_success "Keyring poblado correctamente"

    print_info "Actualizando y refrescando claves..."
    pacman-key --refresh-keys
    if [[ $? -ne 0 ]]; then
        print_warning "Hubo errores al refrescar algunas claves (puede ser normal si no hay red)"
    else
        print_success "Claves refrescadas correctamente"
    fi

    print_success "Configuración del keyring completada"
}

# Instalar sistema base
install_base() {
    print_header "INSTALACIÓN DEL SISTEMA BASE"
    
    print_info "Paquetes base: base linux linux-firmware"
    echo ""
    echo "¿Deseas añadir paquetes adicionales al pacstrap?"
    echo "Ejemplos: base-devel, vim, nano, networkmanager, grub, efibootmgr"
    echo ""
    read -rp "Paquetes adicionales (separados por espacio) [ninguno]: " extra_packages
    
    PACKAGES="base linux linux-firmware"
    if [[ -n "$extra_packages" ]]; then
        PACKAGES="$PACKAGES $extra_packages"
    fi
    
    print_info "Instalando: $PACKAGES"
    print_warning "Esto puede tardar varios minutos..."
    echo ""
    
    pacstrap /mnt "$PACKAGES"
    
    print_success "Sistema base instalado correctamente"
}

# Generar fstab
generate_fstab() {
    print_header "GENERANDO FSTAB"
    
    print_info "Generando fstab con UUIDs..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    print_success "fstab generado:"
    echo ""
    cat /mnt/etc/fstab
}

# Copiar script de configuración
copy_config_script() {
    print_header "PREPARANDO SCRIPT DE CONFIGURACIÓN"
    
    # Determinar la ruta del script config-arch.sh
    # SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_SCRIPT="https://raw.githubusercontent.com/fhuaquistoq/dotfiles/main/scripts/config-arch.sh"
    
    if [[ -f "$CONFIG_SCRIPT" ]]; then
        print_info "Copiando script de configuración al sistema instalado..."
        curl -o /mnt/root/config-arch.sh "$CONFIG_SCRIPT"
        chmod +x /mnt/root/config-arch.sh
        print_success "Script copiado a /root/config-arch.sh"
    else
        print_error "No se encontró el script config-arch.sh en $SCRIPT_DIR"
        print_warning "Deberás copiar manualmente el script de configuración"
    fi
}

# Mostrar pasos siguientes
show_next_steps() {
    print_header "INSTALACIÓN BASE COMPLETADA"
    
    print_success "El sistema base ha sido instalado correctamente"
    echo ""
    echo -e "${YELLOW}PASOS SIGUIENTES:${NC}"
    echo ""
    echo "1. Entra al sistema instalado:"
    echo -e "   ${GREEN}arch-chroot /mnt${NC}"
    echo ""
    echo "2. Ejecuta el script de configuración:"
    echo -e "   ${GREEN}/root/config-arch.sh${NC}"
    echo ""
    echo "   O configura manualmente el sistema siguiendo la guía de instalación"
    echo ""
    echo -e "${BLUE}El script de configuración realizará:${NC}"
    echo "  • Configuración de zona horaria y locales"
    echo "  • Configuración de hostname y contraseña root"
    echo "  • Creación de usuario con sudo"
    echo "  • Instalación y configuración de GRUB (UEFI/BIOS)"
    echo "  • Instalación y activación de NetworkManager"
    echo ""
}

# Función principal
main() {
    print_header "INSTALADOR DE ARCH LINUX - PARTE 1"
    print_warning "Este script instalará el sistema base de Arch Linux"
    echo ""
    read -p "Presiona Enter para continuar..."
    
    select_disk
    ask_partitioning
    select_partitions
    format_partitions
    mount_partitions
    config_keyring
    install_base
    generate_fstab
    copy_config_script
    show_next_steps
    
    print_success "¡Instalación base completada!"
}

# Ejecutar script
main
