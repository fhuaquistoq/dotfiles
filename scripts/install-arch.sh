#!/usr/bin/env bash

# Script de instalación de Arch Linux
# Configuración interactiva de particiones y instalación base

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
    show_disks
    
    while true; do
        read -p "Ingresa el disco a usar (ejemplo: sda, nvme0n1, vda): " disk_input
        DISK="/dev/${disk_input}"
        
        if [[ -b "$DISK" ]]; then
            print_success "Disco seleccionado: $DISK"
            lsblk "$DISK"
            echo ""
            read -p "¿Es correcto este disco? (s/n): " confirm
            if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
                break
            fi
        else
            print_error "El disco $DISK no existe. Intenta de nuevo."
        fi
    done
}

# Preguntar si borrar todo el disco
ask_wipe_disk() {
    print_header "MODO DE PARTICIONADO"
    echo "1) Borrar TODO el disco y crear particiones nuevas"
    echo "2) Usar solo el espacio libre disponible"
    echo ""
    
    while true; do
        read -p "Selecciona una opción (1/2): " option
        case $option in
            1)
                WIPE_DISK="yes"
                print_warning "Se borrará TODO el contenido del disco $DISK"
                read -p "¿Estás seguro? (escriba 'SI' para confirmar): " confirm
                if [[ "$confirm" == "SI" ]]; then
                    break
                else
                    print_info "Operación cancelada"
                    exit 0
                fi
                ;;
            2)
                WIPE_DISK="no"
                print_info "Se usará el espacio libre disponible"
                break
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
    done
}

# Configurar tamaños de particiones
configure_partitions() {
    print_header "CONFIGURACIÓN DE PARTICIONES"
    
    # Partición Boot (EFI)
    echo -e "${BLUE}Partición BOOT (EFI):${NC}"
    echo "Tamaño recomendado: 512M - 1G"
    read -p "Tamaño de la partición boot [512M]: " boot_input
    BOOT_SIZE="${boot_input:-512M}"
    print_success "Boot: $BOOT_SIZE"
    echo ""
    
    # Partición Swap
    echo -e "${BLUE}Partición SWAP:${NC}"
    echo "Tamaño recomendado: RAM/2 para hibernación, o 2-4G sin hibernación"
    read -p "Tamaño de la partición swap [2G]: " swap_input
    SWAP_SIZE="${swap_input:-2G}"
    print_success "Swap: $SWAP_SIZE"
    echo ""
    
    # Partición Root
    echo -e "${BLUE}Partición ROOT:${NC}"
    echo "Por defecto se usará todo el espacio restante"
    read -p "Presiona Enter para continuar..."
    print_success "Root: Espacio restante"
    echo ""
    
    # Resumen
    print_header "RESUMEN DE PARTICIONES"
    echo "Disco: $DISK"
    echo "Boot (EFI): $BOOT_SIZE"
    echo "Swap: $SWAP_SIZE"
    echo "Root: Espacio restante"
    echo ""
    read -p "¿Continuar con esta configuración? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        print_info "Operación cancelada"
        exit 0
    fi
}

# Crear particiones
create_partitions() {
    print_header "CREANDO PARTICIONES"
    
    # Determinar el tipo de disco (SATA/SCSI vs NVMe)
    if [[ "$DISK" == *"nvme"* ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi
    
    if [[ "$WIPE_DISK" == "yes" ]]; then
        print_info "Borrando tabla de particiones..."
        wipefs -a "$DISK"
        
        print_info "Creando nueva tabla de particiones GPT..."
        parted -s "$DISK" mklabel gpt
        
        print_info "Creando partición boot..."
        parted -s "$DISK" mkpart "EFI" fat32 1MiB "$BOOT_SIZE"
        parted -s "$DISK" set 1 esp on
        
        print_info "Creando partición swap..."
        SWAP_END=$(parted -s "$DISK" unit MiB print free | grep "$BOOT_SIZE" | awk '{print $2}')
        parted -s "$DISK" mkpart "SWAP" linux-swap "$BOOT_SIZE" "${SWAP_SIZE}"
        
        print_info "Creando partición root..."
        parted -s "$DISK" mkpart "ROOT" ext4 "${SWAP_SIZE}" "100%"
        
        BOOT_PARTITION="${PART_PREFIX}1"
        SWAP_PARTITION="${PART_PREFIX}2"
        ROOT_PARTITION="${PART_PREFIX}3"
    else
        print_error "El modo 'espacio libre' requiere configuración manual"
        print_info "Por favor, crea las particiones manualmente con cfdisk o fdisk"
        print_info "Luego ejecuta el script nuevamente"
        exit 1
    fi
    
    # Esperar a que el kernel reconozca las particiones
    sleep 2
    partprobe "$DISK"
    sleep 2
    
    print_success "Particiones creadas:"
    lsblk "$DISK"
}

# Formatear particiones
format_partitions() {
    print_header "FORMATEANDO PARTICIONES"
    
    print_info "Formateando boot como FAT32..."
    mkfs.fat -F32 "$BOOT_PARTITION"
    print_success "Boot formateada"
    
    print_info "Configurando swap..."
    mkswap "$SWAP_PARTITION"
    print_success "Swap configurada"
    
    print_info "Formateando root como ext4..."
    mkfs.ext4 -F "$ROOT_PARTITION"
    print_success "Root formateada"
}

# Montar particiones
mount_partitions() {
    print_header "MONTANDO PARTICIONES"
    
    print_info "Montando root en /mnt..."
    mount "$ROOT_PARTITION" /mnt
    
    print_info "Creando directorio /mnt/boot..."
    mkdir -p /mnt/boot
    
    print_info "Montando boot en /mnt/boot..."
    mount "$BOOT_PARTITION" /mnt/boot
    
    print_info "Activando swap..."
    swapon "$SWAP_PARTITION"
    
    print_success "Todas las particiones montadas correctamente"
    echo ""
    df -h /mnt
    echo ""
    swapon --show
}

# Instalar sistema base
install_base() {
    print_header "INSTALACIÓN DEL SISTEMA BASE"
    
    print_info "Paquetes base: base linux linux-firmware"
    echo ""
    echo "¿Deseas añadir paquetes adicionales al pacstrap?"
    echo "Ejemplos: base-devel, vim, nano, networkmanager, grub, efibootmgr"
    echo ""
    read -p "Paquetes adicionales (separados por espacio) [ninguno]: " extra_packages
    
    PACKAGES="base linux linux-firmware"
    if [[ -n "$extra_packages" ]]; then
        PACKAGES="$PACKAGES $extra_packages"
    fi
    
    print_info "Instalando: $PACKAGES"
    print_warning "Esto puede tardar varios minutos..."
    echo ""
    
    pacstrap /mnt $PACKAGES
    
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
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_SCRIPT="$SCRIPT_DIR/config-arch.sh"
    
    if [[ -f "$CONFIG_SCRIPT" ]]; then
        print_info "Copiando script de configuración al sistema instalado..."
        cp "$CONFIG_SCRIPT" /mnt/root/config-arch.sh
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
    ask_wipe_disk
    configure_partitions
    create_partitions
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    copy_config_script
    show_next_steps
    
    print_success "¡Instalación base completada!"
}

# Ejecutar script
main