#!/usr/bin/env bash

# ================================================
# INSTALADOR DE ARCH LINUX - PARTE 1
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

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (usa 'sudo bash install-arch.sh')"
   exit 1
fi

print_success "Ejecutando con permisos de root"

# ================================
# Variables Globales
# ================================
DISK=""
BOOT_PARTITION=""
SWAP_PARTITION=""
ROOT_PARTITION=""
BOOT_SIZE="512M"
SWAP_SIZE="2G"
WIPE_DISK="no"

# ================================
# Funciones de Visualización
# ================================

# Mostrar discos disponibles
show_disks() {
    print_header "DISCOS DISPONIBLES"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    echo ""
}

# ================================
# Funciones de Selección de Disco
# ================================

# Seleccionar disco
select_disk() {
    print_header "SELECCIÓN DE DISCO"
    
    print_warning "⚠️  IMPORTANTE: Todo el contenido del disco seleccionado será BORRADO"
    echo ""

    mapfile -t DISKS < <(lsblk -dpno NAME,SIZE,MODEL | grep -E "/dev/(sd|nvme|vd)")

    if [[ ${#DISKS[@]} -eq 0 ]]; then
        print_error "No se encontraron discos disponibles"
        print_info "Verifica que los discos estén correctamente conectados"
        exit 1
    fi

    print_info "Discos disponibles en el sistema:"
    echo ""
    for i in "${!DISKS[@]}"; do
        echo "  $((i+1))) ${DISKS[$i]}"
    done
    echo ""

    while true; do
        read -p "Selecciona el disco por número [1-${#DISKS[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#DISKS[@]} )); then
            DISK=$(echo "${DISKS[$((choice-1))]}" | awk '{print $1}')
            echo ""
            print_success "Disco seleccionado: $DISK"
            echo ""
            print_info "Información del disco:"
            lsblk "$DISK"
            echo ""
            if ask_yes_no "¿Confirmas que quieres usar este disco?"; then
                break
            else
                echo ""
                print_info "Volviendo a seleccionar disco..."
                echo ""
            fi
        else
            print_error "Opción inválida. Por favor, ingresa un número entre 1 y ${#DISKS[@]}"
        fi
    done
}

# ================================
# Funciones de Particionado
# ================================

# Particionar el disco
ask_partitioning() {
    print_header "PARTICIONADO DEL DISCO"
    
    echo "Puedes particionar el disco manualmente usando cfdisk o usar particiones existentes."
    echo ""
    print_info "Esquema de particiones recomendado para UEFI:"
    echo "  1) EFI/BOOT:  512M  (Tipo: EFI System)"
    echo "  2) SWAP:      2-4G  (Tipo: Linux swap)"
    echo "  3) ROOT:      resto (Tipo: Linux filesystem)"
    echo ""

    if ask_yes_no "¿Deseas particionar el disco ahora con cfdisk?"; then
        print_info "Abriendo cfdisk para particionar $DISK..."
        print_warning "Guarda los cambios con 'Write' antes de salir"
        sleep 2
        cfdisk "$DISK"
        print_success "Particionado completado"
    else
        print_info "Se usarán las particiones existentes"
    fi
    
    echo ""
    print_info "Particiones actuales en $DISK:"
    lsblk "$DISK"
    echo ""
}

# ================================
# Funciones de Selección de Particiones
# ================================

# Seleccionar particiones
select_partitions() {
    print_header "ASIGNACIÓN DE PARTICIONES"
    
    print_info "Particiones disponibles en $DISK:"
    echo ""
    lsblk -lp "$DISK"
    echo ""
    
    print_warning "Debes asignar las particiones correctamente para el esquema UEFI"
    echo ""

    while true; do
        read -p "Partición EFI/BOOT (ejemplo: ${DISK}1 o ${DISK}p1): " BOOT_PARTITION
        if [[ -b "$BOOT_PARTITION" ]]; then
            print_success "Partición BOOT: $BOOT_PARTITION"
            break
        fi
        print_error "La partición '$BOOT_PARTITION' no existe. Intenta nuevamente."
    done
    echo ""

    while true; do
        read -p "Partición SWAP (ejemplo: ${DISK}2 o ${DISK}p2): " SWAP_PARTITION
        if [[ -b "$SWAP_PARTITION" ]]; then
            print_success "Partición SWAP: $SWAP_PARTITION"
            break
        fi
        print_error "La partición '$SWAP_PARTITION' no existe. Intenta nuevamente."
    done
    echo ""

    while true; do
        read -p "Partición ROOT (ejemplo: ${DISK}3 o ${DISK}p3): " ROOT_PARTITION
        if [[ -b "$ROOT_PARTITION" ]]; then
            print_success "Partición ROOT: $ROOT_PARTITION"
            break
        fi
        print_error "La partición '$ROOT_PARTITION' no existe. Intenta nuevamente."
    done
    
    echo ""
    print_header "RESUMEN DE PARTICIONES"
    echo ""
    echo "  📁 BOOT (EFI): $BOOT_PARTITION"
    echo "  💾 SWAP:       $SWAP_PARTITION"
    echo "  🖥️  ROOT:       $ROOT_PARTITION"
    echo ""
    
    if ! ask_yes_no "¿Son correctas estas particiones?"; then
        print_warning "Cancelando instalación..."
        exit 0
    fi
}

# ================================
# Funciones de Formateo
# ================================

# Formatear particiones
format_partitions() {
    print_header "FORMATEO DE PARTICIONES"
    
    echo ""
    print_warning "⚠️  ADVERTENCIA CRÍTICA ⚠️"
    print_warning "Esto BORRARÁ PERMANENTEMENTE todos los datos en:"
    echo "  • $BOOT_PARTITION (BOOT)"
    echo "  • $SWAP_PARTITION (SWAP)"
    echo "  • $ROOT_PARTITION (ROOT)"
    echo ""
    print_error "Esta acción NO se puede deshacer"
    echo ""
    
    read -p "Escribe 'SI' en mayúsculas para confirmar: " confirm
    if [[ "$confirm" != "SI" ]]; then
        print_warning "Formateo cancelado. Saliendo..."
        exit 0
    fi
    
    echo ""
    print_info "Iniciando formateo de particiones..."
    echo ""

    print_info "[1/3] Formateando partición BOOT como FAT32..."
    mkfs.fat -F32 "$BOOT_PARTITION"
    print_success "Partición BOOT formateada correctamente"
    echo ""

    print_info "[2/3] Configurando partición SWAP..."
    mkswap "$SWAP_PARTITION"
    print_success "Partición SWAP configurada correctamente"
    echo ""

    print_info "[3/3] Formateando partición ROOT como ext4..."
    mkfs.ext4 -F "$ROOT_PARTITION"
    print_success "Partición ROOT formateada correctamente"
    echo ""

    print_success "✓ Todas las particiones han sido formateadas exitosamente"
}

# ================================
# Funciones de Montaje
# ================================

# Montar particiones
mount_partitions() {
    print_header "MONTAJE DE PARTICIONES"
    
    print_info "Preparando el sistema de archivos..."
    echo ""

    print_info "[1/4] Montando partición ROOT en /mnt..."
    mount "$ROOT_PARTITION" /mnt
    print_success "ROOT montado correctamente"
    echo ""

    print_info "[2/4] Creando punto de montaje para BOOT..."
    mkdir -p /mnt/boot
    print_success "Directorio /mnt/boot creado"
    echo ""

    print_info "[3/4] Montando partición BOOT..."
    mount "$BOOT_PARTITION" /mnt/boot
    print_success "BOOT montado correctamente"
    echo ""

    print_info "[4/4] Activando partición SWAP..."
    swapon "$SWAP_PARTITION"
    print_success "SWAP activado correctamente"
    echo ""

    print_success "✓ Sistema de archivos preparado y montado"
    echo ""
    print_info "Estado actual de las particiones:"
    echo ""
    lsblk
    echo ""
    print_info "Espacio disponible:"
    df -h /mnt
    echo ""
    print_info "Memoria SWAP:"
    swapon --show
}

# ================================
# Funciones de Configuración del Sistema
# ================================

# Configurar keyring de Pacman
config_keyring() {
    print_header "CONFIGURACIÓN DEL KEYRING DE PACMAN"
    
    print_info "El keyring permite verificar la autenticidad de los paquetes"
    echo ""

    print_info "[1/3] Inicializando el keyring..."
    pacman-key --init
    if [[ $? -ne 0 ]]; then
        print_error "No se pudo inicializar el keyring"
        print_info "Verifica tu conexión a internet y vuelve a intentar"
        exit 1
    fi
    print_success "Keyring inicializado exitosamente"
    echo ""

    print_info "[2/3] Poblando keyring con claves oficiales de Arch Linux..."
    pacman-key --populate archlinux
    if [[ $? -ne 0 ]]; then
        print_error "No se pudo poblar el keyring"
        exit 1
    fi
    print_success "Keyring poblado correctamente"
    echo ""

    print_info "[3/3] Refrescando claves del sistema..."
    print_warning "Este paso puede tardar algunos minutos"
    pacman-key --refresh-keys
    if [[ $? -ne 0 ]]; then
        print_warning "Algunas claves no se pudieron refrescar"
        print_info "Esto es normal si la conexión es lenta. Puedes continuar."
    else
        print_success "Claves refrescadas exitosamente"
    fi
    echo ""

    print_success "✓ Configuración del keyring completada"
}

# ================================
# Funciones de Instalación
# ================================

# Instalar sistema base
install_base() {
    print_header "INSTALACIÓN DEL SISTEMA BASE"
    
    print_info "Paquetes base requeridos:"
    echo "  • base (sistema base de Arch Linux)"
    echo "  • linux (kernel de Linux)"
    echo "  • linux-firmware (firmware para hardware)"
    echo ""
    
    print_info "Paquetes adicionales recomendados:"
    echo "  • base-devel (herramientas de desarrollo)"
    echo "  • networkmanager (gestión de red)"
    echo "  • grub efibootmgr (bootloader para UEFI)"
    echo "  • vim o nano (editor de texto)"
    echo ""
    
    if ask_yes_no "¿Deseas añadir paquetes adicionales?"; then
        echo ""
        read -rp "Ingresa los paquetes separados por espacio: " extra_packages
        PACKAGES="base linux linux-firmware $extra_packages"
    else
        PACKAGES="base linux linux-firmware"
    fi
    
    echo ""
    print_info "Paquetes a instalar:"
    echo "  $PACKAGES"
    echo ""
    print_warning "La descarga e instalación puede tardar varios minutos"
    print_info "Esto depende de tu conexión a internet"
    echo ""
    
    if ask_yes_no "¿Continuar con la instalación?"; then
        echo ""
        print_info "Iniciando instalación del sistema base..."
        pacstrap -K /mnt $PACKAGES
        
        if [[ $? -eq 0 ]]; then
            echo ""
            print_success "✓ Sistema base instalado exitosamente"
        else
            echo ""
            print_error "Hubo un error durante la instalación"
            print_info "Verifica tu conexión a internet e intenta nuevamente"
            exit 1
        fi
    else
        print_warning "Instalación cancelada"
        exit 0
    fi
}

# ================================
# Funciones de Configuración Post-Instalación
# ================================

# Generar fstab
generate_fstab() {
    print_header "GENERACIÓN DE FSTAB"
    
    print_info "Generando archivo fstab con UUIDs..."
    print_info "Este archivo define cómo se montan las particiones al arrancar"
    echo ""
    
    genfstab -U /mnt >> /mnt/etc/fstab
    
    if [[ $? -eq 0 ]]; then
        print_success "✓ Archivo fstab generado correctamente"
        echo ""
        print_info "Contenido de /etc/fstab:"
        echo ""
        cat /mnt/etc/fstab
    else
        print_error "Error al generar el archivo fstab"
        exit 1
    fi
}

# Copiar script de configuración
copy_config_script() {
    print_header "DESCARGA DE SCRIPT DE CONFIGURACIÓN"
    
    CONFIG_SCRIPT="https://raw.githubusercontent.com/fhuaquistoq/dotfiles/main/scripts/config-arch.sh"
    
    print_info "Descargando script de configuración desde GitHub..."
    echo ""
    
    if curl -o /mnt/root/config-arch.sh "$CONFIG_SCRIPT" 2>/dev/null; then
        chmod +x /mnt/root/config-arch.sh
        print_success "✓ Script descargado correctamente"
        print_info "Ubicación: /root/config-arch.sh"
    else
        print_warning "No se pudo descargar el script de configuración"
        print_info "Puedes configurar el sistema manualmente siguiendo la wiki de Arch"
        print_info "O descarga el script después desde: $CONFIG_SCRIPT"
    fi
}

# ================================
# Funciones de Finalización
# ================================

# Mostrar pasos siguientes
show_next_steps() {
    print_header "¡INSTALACIÓN BASE COMPLETADA!"
    
    echo ""
    print_success "El sistema base de Arch Linux ha sido instalado exitosamente"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 PRÓXIMOS PASOS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Entra al sistema recién instalado:"
    echo -e "   ${BLUE}→${NC} arch-chroot /mnt"
    echo ""
    echo -e "${GREEN}2.${NC} Ejecuta el script de configuración:"
    echo -e "   ${BLUE}→${NC} /root/config-arch.sh"
    echo ""
    echo -e "   ${YELLOW}O configura manualmente${NC} el sistema siguiendo la ArchWiki"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚙️  EL SCRIPT DE CONFIGURACIÓN INCLUYE:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ✓ Configuración de zona horaria y locales (idioma)"
    echo "  ✓ Configuración de hostname (nombre del equipo)"
    echo "  ✓ Establecimiento de contraseña root"
    echo "  ✓ Creación de usuario con privilegios sudo"
    echo "  ✓ Instalación y configuración de GRUB (bootloader)"
    echo "  ✓ Instalación y activación de NetworkManager (red)"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ================================
# Función Principal
# ================================

main() {
    clear
    print_header "INSTALADOR DE ARCH LINUX - PARTE 1"
    
    echo ""
    echo "Bienvenido al instalador automatizado de Arch Linux"
    echo ""
    print_info "Este script te guiará paso a paso para instalar:"
    echo "  • Sistema base de Arch Linux"
    echo "  • Particionado y formateo de disco"
    echo "  • Configuración inicial del sistema"
    echo ""
    print_warning "⚠️  IMPORTANTE: Este proceso BORRARÁ datos del disco seleccionado"
    print_warning "Asegúrate de tener respaldos de información importante"
    echo ""
    print_info "Presiona Ctrl+C en cualquier momento para cancelar"
    echo ""
    read -p "Presiona Enter para comenzar..."
    
    # Ejecutar pasos de instalación
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
    
    echo ""
    print_success "¡Instalación base completada exitosamente!"
    print_info "Recuerda seguir los pasos indicados arriba"
    echo ""
}

# ================================
# Ejecución del Script
# ================================

main
