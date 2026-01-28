#!/usr/bin/env bash

# Script de configuración de Arch Linux - Parte 2
# Ejecutar dentro de arch-chroot

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

# Variables globales
TIMEZONE=""
SELECTED_LOCALE=""
HOSTNAME=""
USERNAME=""
BOOT_MODE=""

# Configurar zona horaria
configure_timezone() {
    print_header "CONFIGURACIÓN DE ZONA HORARIA"
    
    # Regiones priorizadas
    PRIORITY_REGIONS=("America" "Europe" "Asia" "Africa" "Australia" "Pacific")
    
    echo "Selecciona una región:"
    echo ""
    
    # Mostrar regiones priorizadas primero
    local idx=1
    for region in "${PRIORITY_REGIONS[@]}"; do
        if [[ -d "/usr/share/zoneinfo/$region" ]]; then
            echo "$idx) $region"
            ((idx++))
        fi
    done
    
    echo ""
    read -rp "Selecciona el número de la región: " region_choice
    
    SELECTED_REGION="${PRIORITY_REGIONS[$((region_choice-1))]}"
    
    if [[ ! -d "/usr/share/zoneinfo/$SELECTED_REGION" ]]; then
        print_error "Región inválida"
        SELECTED_REGION="America"
    fi
    
    print_success "Región seleccionada: $SELECTED_REGION"
    echo ""
    
    # Mostrar zonas horarias de la región
    print_info "Zonas horarias disponibles en $SELECTED_REGION:"
    echo ""
    
    # Listar zonas horarias con prioridad para países importantes
    local zones=()
    local priority_zones=()
    
    # Zonas prioritarias según la región
    case "$SELECTED_REGION" in
        "America")
            priority_zones=("Mexico_City" "Argentina/Buenos_Aires" "Santiago" "Lima" "Bogota" "Caracas" 
                          "Sao_Paulo" "Montevideo" "New_York" "Los_Angeles" "Chicago" "Toronto" "Vancouver")
            ;;
        "Europe")
            priority_zones=("Madrid" "Barcelona" "Lisbon" "London" "Paris" "Berlin" "Rome" "Amsterdam" "Brussels" "Zurich")
            ;;
        *)
            priority_zones=()
            ;;
    esac
    
    # Agregar zonas prioritarias primero
    for pz in "${priority_zones[@]}"; do
        if [[ -e "/usr/share/zoneinfo/$SELECTED_REGION/$pz" ]]; then
            zones+=("$pz")
        fi
    done
    
    # Agregar el resto de zonas (limitado a 20)
    while IFS= read -r zone; do
        zone=$(basename "$zone")
        # Evitar duplicados
        if [[ ! " ${zones[@]} " =~ " ${zone} " ]] && [[ -f "/usr/share/zoneinfo/$SELECTED_REGION/$zone" ]]; then
            zones+=("$zone")
        fi
    done < <(find "/usr/share/zoneinfo/$SELECTED_REGION" -type f 2>/dev/null | head -20)
    
    # Mostrar zonas
    local idx=1
    for zone in "${zones[@]}"; do
        echo "$idx) $zone"
        ((idx++))
    done
    
    echo ""
    read -rp "Selecciona el número de la zona horaria: " zone_choice
    
    SELECTED_ZONE="${zones[$((zone_choice-1))]}"
    TIMEZONE="$SELECTED_REGION/$SELECTED_ZONE"
    
    print_success "Zona horaria seleccionada: $TIMEZONE"
    
    # Aplicar configuración
    print_info "Configurando zona horaria..."
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
    print_success "Zona horaria configurada"
    
    # Configurar NTP
    print_info "Habilitando sincronización de tiempo con NTP..."
    if command -v timedatectl &> /dev/null; then
        timedatectl set-ntp true 2>/dev/null || print_warning "No se pudo habilitar NTP (se configurará en el próximo arranque)"
    fi
}

# Configurar locale
configure_locale() {
    print_header "CONFIGURACIÓN DE LOCALE"
    
    echo "¿Qué locale deseas usar?"
    echo ""
    echo "1) es_ES (Español - España)"
    echo "2) es_MX (Español - México)"
    echo "3) es_PE (Español - Perú)"
    echo "4) es_CL (Español - Chile)"
    echo "5) es_CO (Español - Colombia)"
    echo "6) en_US (English - USA)"
    echo "7) pt_BR (Português - Brasil)"
    echo "8) Otro (especificar)"
    echo ""
    
    read -rp "Selecciona una opción [1]: " locale_choice
    locale_choice=${locale_choice:-1}
    
    case $locale_choice in
        1) SELECTED_LOCALE="es_ES" ;;
        2) SELECTED_LOCALE="es_MX" ;;
        3) SELECTED_LOCALE="es_PE" ;;
        4) SELECTED_LOCALE="es_CL" ;;
        5) SELECTED_LOCALE="es_CO" ;;
        6) SELECTED_LOCALE="en_US" ;;
        7) SELECTED_LOCALE="pt_BR" ;;
        8)
            read -p "Ingresa el locale (ej: es_ES, en_US): " custom_locale
            SELECTED_LOCALE="$custom_locale"
            ;;
        *)
            SELECTED_LOCALE="es_ES"
            ;;
    esac
    
    print_success "Locale seleccionado: $SELECTED_LOCALE"
    
    # Descomentar locales UTF-8 e ISO
    print_info "Configurando /etc/locale.gen..."
    sed -i "s/^#${SELECTED_LOCALE}.UTF-8/${SELECTED_LOCALE}.UTF-8/" /etc/locale.gen
    sed -i "s/^#${SELECTED_LOCALE} ISO/${SELECTED_LOCALE} ISO/" /etc/locale.gen
    
    # Generar locales
    print_info "Generando locales..."
    locale-gen
    
    # Configurar locale.conf
    echo "LANG=${SELECTED_LOCALE}.UTF-8" > /etc/locale.conf
    print_success "Locale configurado correctamente"
}

configure_vconsole() {
    print_header "CONFIGURACIÓN DEL TECLADO (VCONSOLE)"

    echo "Configura el mapa de teclado para la consola después de reiniciar."
    echo "Ejemplos comunes: us, es, la-latin1, es_dvorak"
    echo ""

    while true; do
        read -p "Ingresa el keymap usado con loadkeys: " KEYMAP

        if [[ -z "$KEYMAP" ]]; then
            print_error "El keymap no puede estar vacío"
            continue
        fi

        if loadkeys "$KEYMAP" &>/dev/null; then
            print_success "Keymap válido: $KEYMAP"
            break
        else
            print_error "Keymap inválido o no encontrado"
        fi
    done

    print_info "Creando /etc/vconsole.conf..."
    cat > /etc/vconsole.conf <<EOF
KEYMAP=$KEYMAP
EOF

    print_success "Teclado configurado correctamente"
    echo ""
    print_info "Contenido de /etc/vconsole.conf:"
    cat /etc/vconsole.conf
}

# Configurar hostname
configure_hostname() {
    print_header "CONFIGURACIÓN DE HOSTNAME"
    
    while true; do
        read -p "Ingresa el nombre del host (hostname): " hostname_input
        
        if [[ -n "$hostname_input" ]]; then
            HOSTNAME="$hostname_input"
            print_success "Hostname: $HOSTNAME"
            break
        else
            print_error "El hostname no puede estar vacío"
        fi
    done
    
    # Configurar hostname
    echo "$HOSTNAME" > /etc/hostname
    
    # Configurar /etc/hosts
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
    
    print_success "Hostname configurado"
}

# Configurar contraseña de root
configure_root_password() {
    print_header "CONFIGURACIÓN DE CONTRASEÑA ROOT"
    
    print_warning "Configura una contraseña segura para el usuario root"
    while ! passwd; do
        print_error "Error al configurar la contraseña. Intenta de nuevo."
    done
    print_success "Contraseña de root configurada"
}

# Crear usuario nuevo
create_user() {
    print_header "CREACIÓN DE USUARIO"
    
    while true; do
        read -p "Ingresa el nombre de usuario: " username_input
        
        if [[ -n "$username_input" ]]; then
            USERNAME="$username_input"
            break
        else
            print_error "El nombre de usuario no puede estar vacío"
        fi
    done
    
    print_info "Creando usuario: $USERNAME"
    useradd -G wheel,audio,video,optical,storage,power,scanner,lp,rfkill,input "$USERNAME"
    
    print_warning "Configura una contraseña para $USERNAME"
    while ! passwd "$USERNAME"; do
        print_error "Error al configurar la contraseña. Intenta de nuevo."
    done
    
    print_success "Usuario $USERNAME creado correctamente"
}

# Instalar y configurar sudo
configure_sudo() {
    print_header "CONFIGURACIÓN DE SUDO"
    
    # Instalar sudo si no está instalado
    if ! command -v sudo &> /dev/null; then
        print_info "Instalando sudo..."
        pacman -S --noconfirm sudo
    fi
    
    print_info "Configurando sudoers para el grupo wheel..."
    
    # Descomentar línea de wheel en sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    print_success "Sudo configurado correctamente"
    print_info "Los usuarios del grupo wheel pueden usar sudo"
}

# Detectar modo de arranque (UEFI o BIOS)
detect_boot_mode() {
    print_header "DETECCIÓN DE MODO DE ARRANQUE"
    
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_MODE="UEFI"
        print_success "Sistema detectado: UEFI"
    else
        BOOT_MODE="BIOS"
        print_success "Sistema detectado: BIOS Legacy"
    fi
}

# Instalar y configurar GRUB
install_grub() {
    print_header "INSTALACIÓN DE BOOTLOADER (GRUB)"
    
    # Instalar paquetes necesarios
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        print_info "Instalando GRUB para UEFI..."
        pacman -S --noconfirm grub efibootmgr
        
        print_info "Instalando GRUB en /boot..."
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    else
        print_info "Instalando GRUB para BIOS..."
        pacman -S --noconfirm grub
        
        # Detectar el disco principal
        ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))
        print_info "Instalando GRUB en /dev/$ROOT_DISK..."
        grub-install --target=i386-pc --recheck /dev/$ROOT_DISK
    fi
    
    # Generar configuración de GRUB
    print_info "Generando configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg
    
    print_success "GRUB instalado y configurado correctamente"
}

# Instalar y configurar NetworkManager
install_networkmanager() {
    print_header "INSTALACIÓN DE NETWORKMANAGER"
    
    print_info "Instalando NetworkManager..."
    pacman -S --noconfirm networkmanager
    
    print_info "Habilitando NetworkManager..."
    systemctl enable NetworkManager
    
    print_success "NetworkManager instalado y habilitado"
}

# Mostrar instrucciones finales
show_final_instructions() {
    print_header "CONFIGURACIÓN COMPLETADA"
    
    print_success "¡Arch Linux ha sido configurado correctamente!"
    echo ""
    echo -e "${BLUE}RESUMEN DE LA CONFIGURACIÓN:${NC}"
    echo "  • Hostname: $HOSTNAME"
    echo "  • Zona horaria: $TIMEZONE"
    echo "  • Locale: $SELECTED_LOCALE.UTF-8"
    echo "  • Usuario: $USERNAME"
    echo "  • Bootloader: GRUB ($BOOT_MODE)"
    echo ""
    echo -e "${YELLOW}PASOS FINALES:${NC}"
    echo ""
    echo "1. Sal del chroot:"
    echo -e "   ${GREEN}exit${NC}"
    echo ""
    echo "2. Desmonta las particiones:"
    echo -e "   ${GREEN}umount -R /mnt${NC}"
    echo ""
    echo "3. Reinicia el sistema:"
    echo -e "   ${GREEN}reboot${NC}"
    echo ""
    echo -e "${BLUE}CONECTARSE A INTERNET:${NC}"
    echo ""
    echo "Después de reiniciar, para conectarte a internet:"
    echo ""
    echo "• WiFi:"
    echo -e "  ${GREEN}nmcli device wifi list${NC}                    # Listar redes"
    echo -e "  ${GREEN}nmcli device wifi connect SSID password PASS${NC}  # Conectar"
    echo ""
    echo "• Ethernet (se conecta automáticamente)"
    echo ""
    echo "• Verificar conexión:"
    echo -e "  ${GREEN}ping -c 3 archlinux.org${NC}"
    echo ""
}

# Función principal
main() {
    print_header "CONFIGURACIÓN DE ARCH LINUX - PARTE 2"
    
    # Verificar que estamos en chroot
    if [[ ! -f /.dockerenv ]] && [[ $(stat -c %d:%i /) == $(stat -c %d:%i /proc/1/root/.) ]]; then
        print_error "Este script debe ejecutarse dentro de arch-chroot"
        print_info "Ejecuta primero: arch-chroot /mnt"
        exit 1
    fi
    
    print_info "Iniciando configuración del sistema..."
    echo ""
    read -p "Presiona Enter para continuar..."
    
    configure_timezone
    configure_locale
    configure_vconsole
    configure_hostname
    configure_root_password
    create_user
    configure_sudo
    detect_boot_mode
    install_grub
    install_networkmanager
    show_final_instructions
    
    print_success "¡Configuración completada exitosamente!"
    
    # Autolimpieza
    print_info "Limpiando script de configuración..."
    rm -f /root/config-arch.sh
}

# Ejecutar script
main
