# 🚀 Dotfiles para Arch Linux

Configuración completa de un entorno de escritorio Wayland moderno con Hyprland/Sway, enfocado en productividad y estética.

sudo pacman -S bluez bluez-utils


![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)
![Sway](https://img.shields.io/badge/Sway-68751C?style=for-the-badge&logo=sway&logoColor=white)

## 📋 Índice

- [Instalación de Arch Linux](#-instalación-de-arch-linux)
  - [Requisitos](#requisitos)
  - [Instalación Automática](#instalación-automática)
  - [Instalación Manual](#instalación-manual)
- [Características de Dotfiles](#-características-de-dotfiles)
- [Capturas de Pantalla](#️-capturas-de-pantalla)
- [Instalación de Dotfiles](#-instalación-de-dotfiles)
  - [Requisitos](#requisitos-1)
  - [Instalación Automática](#instalación-automática-1)
  - [Instalación Manual](#instalación-manual-1)
- [Licencia](#-licencia)

---

## 🔧 Instalación de Arch Linux

### Requisitos

Antes de ejecutar los scripts de instalación, asegúrate de:

- ✅ Haber arrancado desde el medio de instalación de Arch Linux
- ✅ Tener conexión a Internet configurada
- ✅ Haber configurado el teclado (si es necesario)

```bash
# Configurar teclado latinoamericano
loadkeys la-latin1

# Conectar a WiFi (si es necesario)
iwctl
# device list
# station wlan0 connect <SSID>

# Verificar conexión
ping -c 3 archlinux.org
```

### Instalación Automática

Scripts automatizados para instalar Arch Linux de manera rápida y sencilla:

```bash
# 1. Descargar scripts
curl -O https://raw.githubusercontent.com/fhuaquistoq/dotfiles/main/scripts/install-arch.sh
curl -O https://raw.githubusercontent.com/fhuaquistoq/dotfiles/main/scripts/config-arch.sh

# Dar permisos de ejecución
chmod +x install-arch.sh config-arch.sh

# 2. Ejecutar instalación base (particionado, formateo, pacstrap)
./install-arch.sh

# 3. Entrar al sistema instalado
arch-chroot /mnt

# 4. Ejecutar configuración (timezone, locale, usuario, GRUB, etc.)
/root/config-arch.sh

# 5. Salir y reiniciar
exit
umount -R /mnt
reboot
```

**Opcional - Dual Boot con Windows:**

```bash
# Después de instalar y configurar Arch Linux
curl -O https://raw.githubusercontent.com/fhuaquistoq/dotfiles/main/scripts/install-dualboot.sh
chmod +x install-dualboot.sh
sudo ./install-dualboot.sh
```

#### ¿Qué hace cada script?

**install-arch.sh** - Instalación base:
- Selección de disco y particionado automático
- Formateo de particiones (EFI, Swap, Root)
- Instalación del sistema base con `pacstrap`
- Generación de `fstab`

**config-arch.sh** - Configuración del sistema:
- Configuración de zona horaria y locales
- Configuración de hostname
- Creación de usuario con sudo
- Detección automática UEFI/BIOS e instalación de GRUB
- Instalación y configuración de NetworkManager

**install-dualboot.sh** - Dual boot (opcional):
- Instalación de os-prober y ntfs-3g
- Detección automática de Windows
- Configuración de GRUB para dual boot

### Instalación Manual

Si prefieres realizar la instalación manualmente, sigue estos pasos:

<details>
<summary>Ver guía manual completa</summary>

#### 1. Particionar el disco

```bash
# Listar discos disponibles
lsblk

# Particionar el disco
cfdisk /dev/sdX
```

**Esquema de particiones recomendado:**

| Punto de montaje | Tipo | Tamaño |
|-----------------|------|--------|
| /boot | EFI System | 512M |
| [SWAP] | Linux Swap | 2-8G |
| / | Linux filesystem | Restante |

#### 2. Formatear particiones

```bash
# Formatear EFI
mkfs.fat -F32 /dev/sdX1

# Configurar Swap
mkswap /dev/sdX2
swapon /dev/sdX2

# Formatear Root
mkfs.ext4 /dev/sdX3
```

#### 3. Montar particiones

```bash
mount /dev/sdX3 /mnt
mount --mkdir /dev/sdX1 /mnt/boot
```

#### 4. Instalar sistema base

```bash
pacstrap -K /mnt base linux linux-firmware
```

#### 5. Generar fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

#### 6. Configurar el sistema

```bash
arch-chroot /mnt

# Zona horaria
ln -sf /usr/share/zoneinfo/<region>/<location> /etc/localtime
hwclock --systohc

# Locale
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf

# Hostname
echo "mi-arch" > /etc/hostname

# Contraseña root
passwd

# Crear usuario
useradd -m -G wheel,audio,video,storage -s /bin/bash usuario
passwd usuario

# Configurar sudo
pacman -S sudo
EDITOR=nano visudo
# Descomentar: %wheel ALL=(ALL:ALL) ALL

# Instalar GRUB
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# NetworkManager
pacman -S networkmanager
systemctl enable NetworkManager
```

#### 7. Reiniciar

```bash
exit
umount -R /mnt
reboot
```

</details>

---

## ✨ Características de Dotfiles

Una vez instalado Arch Linux, estos dotfiles proporcionan:

### Window Managers
- **Hyprland**: Compositor Wayland dinámico con efectos
- **Sway**: Compositor Wayland i3-compatible

### Terminal & Shell
- **Kitty**: Terminal acelerado por GPU
- **Fish**: Shell moderno con autocompletado
- **Starship**: Prompt minimalista

### Desktop Environment
- **Waybar**: Barra de estado personalizable
- **Dunst**: Notificaciones elegantes
- **Rofi**: Lanzador de aplicaciones
- **SDDM**: Display manager con tema pixel-art

### Temas
- **Catppuccin Mocha**: Esquema de colores pasteles consistente

### Utilidades
- Screenshots con anotaciones (satty)
- Gestión de fondos de pantalla (mpvpaper)
- Control de brillo y audio

### Desarrollo
- **Mise**: Gestor de versiones (Node, Python, etc.)
- **Neovim**: Editor moderno
- **Docker**: Containerización

---

## 🖼️ Capturas de Pantalla

> Próximamente

---

## 📦 Instalación de Dotfiles

### Requisitos

- Arch Linux instalado y funcionando
- Conexión a Internet
- Usuario con privilegios sudo

### Instalación Automática

> Próximamente

### Instalación Manual

> Próximamente

---

## 📄 Licencia

MIT License - Siéntete libre de usar y modificar estos dotfiles.

---

**¡Disfruta de tu nuevo sistema!** 🎉
