#!/usr/bin/env bash

# ================================================
# INSTALADOR DE ARCH LINUX - PARTE 2
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

TIMEZONE=""
SELECTED_LOCALE=""
HOSTNAME=""
USERNAME=""
BOOT_MODE=""

# ================================
# Funciones de Configuración Regional
# ================================

# Configurar zona horaria
configure_timezone() {
    print_header "CONFIGURACIÓN DE ZONA HORARIA"
    
    print_info "La zona horaria determina la hora local de tu sistema"
    echo ""
    
    # Regiones priorizadas
    PRIORITY_REGIONS=("America" "Europe" "Asia" "Africa" "Australia" "Pacific")
    
    print_info "Regiones disponibles:"
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
    echo ""
    print_info "Aplicando configuración de zona horaria..."
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    print_success "Enlace simbólico creado correctamente"
    
    print_info "Sincronizando el reloj del sistema con el hardware..."
    hwclock --systohc
    print_success "✓ Reloj del hardware sincronizado"
    
    # Configurar NTP
    print_info "Habilitando sincronización automática de tiempo (NTP)..."
    if command -v timedatectl &> /dev/null; then
        timedatectl set-ntp true 2>/dev/null || print_warning "NTP se configurará en el próximo arranque"
    fi
    
    echo ""
    print_success "✓ Zona horaria configurada: $TIMEZONE"
}

# Configurar locale
configure_locale() {
    print_header "CONFIGURACIÓN DE LOCALE (IDIOMA)"
    
    print_info "El locale define el idioma del sistema y formatos regionales"
    echo ""
    
    echo "Selecciona el idioma y región de tu sistema:"
    echo ""
    echo "  1) 🇪🇸 es_ES (Español - España)"
    echo "  2) 🇲🇽 es_MX (Español - México)"
    echo "  3) 🇵🇪 es_PE (Español - Perú)"
    echo "  4) 🇨🇱 es_CL (Español - Chile)"
    echo "  5) 🇨🇴 es_CO (Español - Colombia)"
    echo "  6) 🇺🇸 en_US (English - USA)"
    echo "  7) 🇧🇷 pt_BR (Português - Brasil)"
    echo "  8) 🌍 Otro (especificar)"
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
    
    echo ""
    print_success "Locale seleccionado: $SELECTED_LOCALE"
    echo ""
    
    # Descomentar locales UTF-8 e ISO
    print_info "[1/3] Habilitando locale en /etc/locale.gen..."
    sed -i "s/^#${SELECTED_LOCALE}.UTF-8/${SELECTED_LOCALE}.UTF-8/" /etc/locale.gen
    sed -i "s/^#${SELECTED_LOCALE} ISO/${SELECTED_LOCALE} ISO/" /etc/locale.gen
    print_success "Locale habilitado"
    
    # Generar locales
    print_info "[2/3] Generando archivos de locale..."
    locale-gen
    print_success "Locales generados"
    
    # Configurar locale.conf
    print_info "[3/3] Creando /etc/locale.conf..."
    echo "LANG=${SELECTED_LOCALE}.UTF-8" > /etc/locale.conf
    print_success "Archivo de configuración creado"
    
    echo ""
    print_success "✓ Locale configurado: ${SELECTED_LOCALE}.UTF-8"
}

# ================================
# Funciones de Configuración del Sistema
# ================================

# Configurar teclado de consola
configure_vconsole() {
    print_header "CONFIGURACIÓN DEL TECLADO (CONSOLA)"
    
    print_info "Configura el mapa de teclado para la consola virtual (TTY)"
    echo ""
    echo "Ejemplos comunes de keymaps:"
    echo "  • us         (Teclado inglés americano)"
    echo "  • es         (Teclado español)"
    echo "  • la-latin1  (Teclado latinoamericano)"
    echo "  • dvorak     (Distribución Dvorak)"
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

    echo ""
    print_info "Creando archivo /etc/vconsole.conf..."
    cat > /etc/vconsole.conf <<EOF
KEYMAP=$KEYMAP
EOF

    print_success "Archivo creado exitosamente"
    echo ""
    print_info "Configuración aplicada:"
    cat /etc/vconsole.conf
    echo ""
    print_success "✓ Mapa de teclado configurado: $KEYMAP"
}

# Configurar hostname
configure_hostname() {
    print_header "CONFIGURACIÓN DEL NOMBRE DEL EQUIPO"
    
    print_info "El hostname es el nombre que identifica tu computadora en la red"
    echo ""
    echo "Ejemplos: archlinux, pc-casa, laptop-trabajo, servidor-1"
    echo ""
    
    while true; do
        read -p "Ingresa el nombre del equipo (hostname): " hostname_input
        
        if [[ -n "$hostname_input" ]]; then
            HOSTNAME="$hostname_input"
            print_success "Hostname: $HOSTNAME"
            break
        else
            print_error "El hostname no puede estar vacío"
        fi
    done
    
    # Configurar hostname
    echo ""
    print_info "Creando archivo /etc/hostname..."
    echo "$HOSTNAME" > /etc/hostname
    print_success "Hostname guardado"
    
    # Configurar /etc/hosts
    print_info "Configurando archivo /etc/hosts..."
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
    print_success "Archivo hosts configurado"
    
    echo ""
    print_success "✓ Nombre del equipo: $HOSTNAME"
}

# ================================
# Funciones de Usuarios y Permisos
# ================================

# Configurar contraseña de root
configure_root_password() {
    print_header "CONFIGURACIÓN DE CONTRASEÑA ROOT"
    
    print_info "El usuario root tiene control total sobre el sistema"
    echo ""
    print_warning "⚠️  Importante: Usa una contraseña segura"
    print_info "Requisitos recomendados:"
    echo "  • Mínimo 8 caracteres"
    echo "  • Combinar mayúsculas, minúsculas, números y símbolos"
    echo ""
    
    while ! passwd; do
        echo ""
        print_error "Error al configurar la contraseña. Intenta nuevamente."
        echo ""
    done
    
    echo ""
    print_success "✓ Contraseña de root configurada exitosamente"
}

# Crear usuario nuevo
create_user() {
    print_header "CREACIÓN DE USUARIO PERSONAL"
    
    print_info "Crea un usuario para uso diario (no uses root para tareas normales)"
    echo ""
    
    while true; do
        read -p "Ingresa el nombre de usuario: " username_input
        
        if [[ -n "$username_input" ]]; then
            USERNAME="$username_input"
            echo ""
            print_success "Usuario a crear: $USERNAME"
            break
        else
            print_error "El nombre de usuario no puede estar vacío"
        fi
    done
    
    echo ""
    print_info "Creando usuario con grupos del sistema..."
    useradd -m -G wheel,audio,video,optical,storage,power,scanner,lp,rfkill,input "$USERNAME"
    print_success "Usuario creado con directorio home"
    
    print_info "Grupos asignados:"
    echo "  • wheel (sudo), audio, video, storage, power, input"
    echo ""
    
    print_warning "Configura una contraseña para $USERNAME"
    echo ""
    while ! passwd "$USERNAME"; do
        echo ""
        print_error "Error al configurar la contraseña. Intenta nuevamente."
        echo ""
    done
    
    echo ""
    print_success "✓ Usuario $USERNAME creado y configurado"
}

# Instalar y configurar sudo
configure_sudo() {
    print_header "CONFIGURACIÓN DE SUDO"
    
    print_info "Sudo permite a usuarios ejecutar comandos como root"
    echo ""
    
    # Instalar sudo si no está instalado
    if ! command -v sudo &> /dev/null; then
        print_info "Instalando paquete sudo..."
        pacman -S --noconfirm sudo
        print_success "Sudo instalado"
    else
        print_info "Sudo ya está instalado"
    fi
    
    echo ""
    print_info "Habilitando permisos sudo para el grupo wheel..."
    
    # Descomentar línea de wheel en sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    print_success "Configuración de sudoers actualizada"
    echo ""
    print_info "Los usuarios del grupo 'wheel' ahora pueden usar sudo"
    print_info "Uso: sudo <comando>"
    echo ""
    print_success "✓ Sudo configurado correctamente"
}

# ================================
# Funciones de Bootloader
# ================================

# Detectar modo de arranque (UEFI o BIOS)
detect_boot_mode() {
    print_header "DETECCIÓN DE MODO DE ARRANQUE"
    
    print_info "Detectando modo de firmware del sistema..."
    echo ""
    
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_MODE="UEFI"
        print_success "✓ Modo detectado: UEFI (moderno)"
        print_info "Se instalará GRUB para UEFI x86_64"
    else
        BOOT_MODE="BIOS"
        print_success "✓ Modo detectado: BIOS Legacy (tradicional)"
        print_info "Se instalará GRUB para BIOS i386-pc"
    fi
}

# Instalar y configurar GRUB
install_grub() {
    print_header "INSTALACIÓN DEL BOOTLOADER (GRUB)"
    
    print_info "GRUB es el gestor de arranque que inicia el sistema operativo"
    echo ""
    
    # Instalar paquetes necesarios
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        print_info "[1/3] Instalando paquetes para UEFI..."
        print_info "Paquetes: grub, efibootmgr"
        pacman -S --noconfirm grub efibootmgr
        print_success "Paquetes instalados"
        echo ""
        
        print_info "[2/3] Instalando GRUB en la partición EFI (/boot)..."
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
        print_success "GRUB instalado en modo UEFI"
    else
        print_info "[1/3] Instalando paquetes para BIOS..."
        print_info "Paquete: grub"
        pacman -S --noconfirm grub
        print_success "Paquetes instalados"
        echo ""
        
        # Detectar el disco principal
        ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))
        print_info "[2/3] Instalando GRUB en el MBR del disco..."
        print_info "Disco detectado: /dev/$ROOT_DISK"
        grub-install --target=i386-pc --recheck /dev/$ROOT_DISK
        print_success "GRUB instalado en modo BIOS"
    fi
    
    # Generar configuración de GRUB
    echo ""
    print_info "[3/3] Generando archivo de configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg
    print_success "Configuración generada"
    
    echo ""
    print_success "✓ GRUB instalado y configurado exitosamente"
}

# ================================
# Funciones de Red
# ================================

# Instalar y configurar NetworkManager
install_networkmanager() {
    print_header "INSTALACIÓN DE GESTOR DE RED"
    
    print_info "NetworkManager facilita la conexión a redes WiFi y Ethernet"
    echo ""
    
    print_info "[1/2] Instalando NetworkManager..."
    pacman -S --noconfirm networkmanager
    print_success "NetworkManager instalado"
    
    echo ""
    print_info "[2/2] Habilitando servicio para inicio automático..."
    systemctl enable NetworkManager
    print_success "Servicio habilitado"
    
    echo ""
    print_info "NetworkManager se iniciará automáticamente al arrancar"
    print_success "✓ Gestor de red configurado correctamente"
}

# ================================
# Funciones de Finalización
# ================================

# Mostrar instrucciones finales
show_final_instructions() {
    print_header "¡CONFIGURACIÓN COMPLETADA!"
    
    echo ""
    print_success "Arch Linux ha sido configurado exitosamente"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 RESUMEN DE LA CONFIGURACIÓN:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  🖥️  Hostname:      $HOSTNAME"
    echo "  🌍 Zona horaria:  $TIMEZONE"
    echo "  🌐 Idioma:        $SELECTED_LOCALE.UTF-8"
    echo "  👤 Usuario:       $USERNAME"
    echo "  🚀 Bootloader:    GRUB ($BOOT_MODE)"
    echo "  📡 Red:           NetworkManager"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🎯 PASOS FINALES PARA COMPLETAR LA INSTALACIÓN:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Sal del entorno chroot:"
    echo -e "   ${BLUE}→${NC} exit"
    echo ""
    echo -e "${GREEN}2.${NC} Desmonta todas las particiones:"
    echo -e "   ${BLUE}→${NC} umount -R /mnt"
    echo ""
    echo -e "${GREEN}3.${NC} Reinicia el sistema:"
    echo -e "   ${BLUE}→${NC} reboot"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📡 CONECTARSE A INTERNET (después de reiniciar):${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}WiFi:${NC}"
    echo -e "  ${BLUE}→${NC} nmcli device wifi list"
    echo "     (lista las redes WiFi disponibles)"
    echo ""
    echo -e "  ${BLUE}→${NC} nmcli device wifi connect NOMBRE_RED password TU_CONTRASEÑA"
    echo "     (conecta a una red WiFi)"
    echo ""
    echo -e "${GREEN}Ethernet:${NC}"
    echo "  • Se conecta automáticamente al enchufar el cable"
    echo ""
    echo -e "${GREEN}Verificar conexión:${NC}"
    echo -e "  ${BLUE}→${NC} ping -c 3 archlinux.org"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ================================
# Función Principal
# ================================

main() {
    clear
    print_header "CONFIGURACIÓN DE ARCH LINUX - PARTE 2"
    
    # Verificar que estamos en chroot
    if [[ ! -f /.dockerenv ]] && [[ $(stat -c %d:%i /) == $(stat -c %d:%i /proc/1/root/.) ]]; then
        print_error "Este script debe ejecutarse dentro de arch-chroot"
        print_info "Ejecuta primero: arch-chroot /mnt"
        exit 1
    fi
    
    echo ""
    echo "Bienvenido al asistente de configuración de Arch Linux"
    echo ""
    print_info "Este script configurará:"
    echo "  • Zona horaria e idioma del sistema"
    echo "  • Teclado de consola"
    echo "  • Nombre del equipo y usuarios"
    echo "  • Bootloader (GRUB)"
    echo "  • Gestor de red (NetworkManager)"
    echo ""
    print_warning "El proceso tomará varios minutos"
    print_info "Presiona Ctrl+C en cualquier momento para cancelar"
    echo ""
    read -p "Presiona Enter para comenzar..."
    
    # Ejecutar configuraciones paso a paso
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
    
    echo ""
    print_success "¡Configuración completada exitosamente!"
    print_info "Sigue los pasos indicados arriba para finalizar"
    echo ""
}

# ================================
# Ejecución del Script
# ================================

main
