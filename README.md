# 🚀 Dotfiles para Arch Linux

Configuración completa de un entorno de escritorio Wayland moderno con Hyprland/Sway, enfocado en productividad y estética.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00D9FF?style=for-the-badge)
![Fish Shell](https://img.shields.io/badge/Fish_Shell-4EAA25?style=for-the-badge)

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Capturas de Pantalla](#-capturas-de-pantalla)
- [Componentes](#️-componentes)
- [Requisitos Previos](#-requisitos-previos)
- [🚀 Inicio Rápido](QUICKSTART.md) ← **Empieza aquí**
- [Instalación Rápida](#-instalación-rápida)
- [Instalación Manual](#-instalación-manual)
- [Gestión de Paquetes](#-gestión-de-paquetes)
- [Configuración Post-Instalación](#️-configuración-post-instalación)
- [Atajos de Teclado](#-atajos-de-teclado)
- [Personalización](#-personalización)
- [Solución de Problemas](#-solución-de-problemas)

## ✨ Características

- **🎨 Tema Catppuccin Mocha**: Esquema de color consistente en toda la configuración
- **🪟 Compositors Wayland**: Soporte para Hyprland y Sway
- **🐚 Fish Shell**: Shell moderno con autocompletado inteligente
- **⚡ Starship Prompt**: Prompt minimalista y rápido
- **📊 Waybar**: Barra de estado altamente personalizable
- **🔔 Dunst/Mako**: Sistema de notificaciones elegante
- **📸 Screenshot Tools**: Capturas con anotaciones (Satty)
- **🖼️ Gestión de Wallpapers**: Waypaper con soporte para videos
- **🔧 Mise**: Gestor de versiones para entornos de desarrollo
- **🎯 SDDM Pixel Theme**: Tema de inicio de sesión personalizado

## 🖼️ Capturas de Pantalla

> Añade tus capturas de pantalla aquí

## 🛠️ Componentes

### Window Managers
- **Hyprland**: Compositor Wayland dinámico con efectos y animaciones
- **Sway**: Compositor Wayland i3-compatible

### Terminal & Shell
- **Kitty**: Emulador de terminal acelerado por GPU
- **Fish**: Shell amigable e inteligente
- **Starship**: Prompt minimalista y rápido

### Desktop Environment
- **Waybar**: Barra de estado personalizable
- **Dunst/Mako**: Daemon de notificaciones
- **Rofi**: Lanzador de aplicaciones
- **SDDM**: Display manager con tema pixel-art

### Utilities
- **grim + slurp + satty**: Capturas de pantalla con anotaciones
- **wl-clipboard**: Gestor de portapapeles
- **hyprpaper/waypaper**: Gestión de fondos de pantalla
- **brightnessctl**: Control de brillo

### Development Tools
- **Mise**: Gestor de versiones (Node, Python, PHP, etc.)
- **Neovim**: Editor de texto moderno
- **Docker**: Containerización

## 📌 Requisitos Previos

- Sistema Arch Linux instalado
- Conexión a Internet
- Usuario con privilegios sudo
- 5-10 GB de espacio en disco

## 🔒 Seguridad - IMPORTANTE

**⚠️ ANTES DE USAR ESTOS DOTFILES:**

1. **Elimina/Cambia el token de GitHub** en [fish/config.fish](fish/config.fish)
2. **Revisa todos los archivos** por información personal
3. **Lee la [Guía de Seguridad](SECURITY.md)** completa
4. **Usa archivos secrets** para credenciales (ver [.env.example](.env.example))

**Nunca hagas commit de tokens, contraseñas o información sensible.**

Ver [SECURITY.md](SECURITY.md) para más detalles.

## 🚀 Instalación Rápida

```bash
# Clonar el repositorio
git clone https://github.com/fhuaquistoq/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 
chmod +x ./install.sh

# Ejecutar el script de instalación
./install.sh
```

El script te guiará a través de un proceso interactivo donde podrás elegir qué componentes instalar.

## 📖 Instalación Manual

### 1. Habilitar Multilib

```bash
sudo nano /etc/pacman.conf
```

Descomenta las siguientes líneas:
```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

```bash
sudo pacman -Sy
```

### 2. Instalar Paquetes Esenciales

```bash
# Leer y instalar desde el archivo
cat packages/essential.txt | grep -v '^#' | xargs sudo pacman -S --needed
```

### 3. Instalar Desktop Environment

```bash
cat packages/desktop.txt | grep -v '^#' | xargs sudo pacman -S --needed
```

### 4. Instalar Fuentes

```bash
cat packages/fonts.txt | grep -v '^#' | xargs sudo pacman -S --needed
```

### 5. Instalar Shell y CLI Tools

```bash
cat packages/shell.txt | grep -v '^#' | xargs sudo pacman -S --needed
```

### 6. Instalar Paru (AUR Helper)

```bash
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### 7. Instalar Paquetes AUR

```bash
cat packages/aur.txt | grep -v '^#' | xargs paru -S --needed
```

### 8. Instalar Herramientas de Desarrollo (Opcional)

```bash
cat packages/development.txt | grep -v '^#' | xargs sudo pacman -S --needed

# Instalar Mise
curl https://mise.run | sh

# Instalar Zed (opcional)
curl -f https://zed.dev/install.sh | sh
```

### 9. Desplegar Dotfiles

```bash
# Backup de configuraciones existentes
mkdir -p ~/.config-backup
cp -r ~/.config/* ~/.config-backup/ 2>/dev/null || true

# Copiar configuraciones
cp -r fish kitty hypr sway waybar dunst environment.d mise ~/.config/
cp starship.toml ~/.config/

# Copiar scripts
mkdir -p ~/.local/bin
cp misc/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*
```

### 10. Instalar Fish Plugins

```bash
# Instalar Fisher
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

# Instalar plugins
fish -c "fisher update"
```

### 11. Configurar Servicios

```bash
# Habilitar NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Habilitar Docker (opcional)
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Habilitar SDDM
sudo systemctl enable sddm
```

### 12. Instalar Tema SDDM

```bash
cd sddm/sddm-pixel
sudo bash setup.sh
```

## 📦 Gestión de Paquetes

Los paquetes están organizados en archivos separados en el directorio `packages/`:

- **essential.txt**: Paquetes del sistema base (requeridos)
- **desktop.txt**: Componentes del entorno de escritorio
- **fonts.txt**: Fuentes del sistema
- **shell.txt**: Shell y herramientas CLI
- **development.txt**: Herramientas de desarrollo
- **applications.txt**: Aplicaciones de usuario
- **aur.txt**: Paquetes del AUR

### Añadir/Quitar Paquetes

Edita los archivos correspondientes en `packages/` y ejecuta:

```bash
# Para paquetes oficiales
cat packages/ARCHIVO.txt | grep -v '^#' | xargs sudo pacman -S --needed

# Para paquetes AUR
cat packages/aur.txt | grep -v '^#' | xargs paru -S --needed
```

## ⚙️ Configuración Post-Instalación

### 1. Configurar Monitores

Edita `hypr/hyprland.conf.d/monitors.conf`:

```conf
monitor=eDP-1,1920x1080@60,0x0,1
monitor=,preferred,auto,1
```

### 2. Configurar Wallpaper

```bash
waypaper
```

### 3. Instalar Versiones de Lenguajes con Mise

```bash
# Ver herramientas disponibles
mise ls-remote node

# Instalar desde mise/config.toml
mise install

# O instalar manualmente
mise use --global node@lts
mise use --global python@3.12
```

### 4. Configurar Fish como Shell por Defecto

```bash
chsh -s $(which fish)
```

### 5. Configurar Git

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

## ⌨️ Atajos de Teclado

### Hyprland/Sway

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir terminal |
| `Super + Q` | Cerrar ventana |
| `Super + 1-9` | Cambiar a workspace |
| `Super + Shift + 1-9` | Mover ventana a workspace |
| `Super + H/J/K/L` | Mover foco (vim keys) |
| `Super + Tab` | Workspace anterior |
| `Super + F` | Fullscreen |
| `Super + Space` | Floating toggle |
| `Print` | Screenshot región |
| `Shift + Print` | Screenshot completa |

### Multimedia

| Atajo | Acción |
|-------|--------|
| `XF86AudioRaiseVolume` | Subir volumen |
| `XF86AudioLowerVolume` | Bajar volumen |
| `XF86AudioMute` | Silenciar |
| `XF86MonBrightnessUp` | Subir brillo |
| `XF86MonBrightnessDown` | Bajar brillo |

## 🎨 Personalización

### Cambiar Tema

Todos los temas están en directorios `themes/` dentro de cada configuración:

```
hypr/themes/catppuccin-mocha.conf
kitty/themes/catppuccin-mocha.conf
sway/themes/catppuccin-mocha.conf
waybar/themes/catppuccin-mocha.css
```

### Modificar Waybar

Edita los módulos en `waybar/modules/` para personalizar la barra.

### Cambiar Fuente

Edita `dunst/dunstrc` y `kitty/kitty.conf.d/general.conf` para cambiar las fuentes.

## 🔧 Solución de Problemas

### Hyprland no inicia

```bash
# Verificar logs
journalctl -xe
cat ~/.local/share/hyprland/hyprland.log
```

### Problemas de audio

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Dunst no muestra notificaciones

```bash
killall dunst
dunst &
```

### Waybar no aparece

```bash
killall waybar
waybar &
```

### Docker: permission denied

```bash
sudo usermod -aG docker $USER
# Cerrar sesión y volver a iniciar
```

## 📝 Notas Importantes

- **Seguridad**: Lee [SECURITY.md](SECURITY.md) antes de hacer fork/commit
- **Tokens**: No incluyas tokens reales en archivos versionados
- **Backup**: Siempre haz backup de tus configuraciones antes de aplicar estos dotfiles
- **Hardware**: Algunos ajustes están optimizados para hardware Intel. Ajusta según tu GPU

## 📚 Documentación Adicional

- [🚀 QUICKSTART.md](QUICKSTART.md) - **Guía de inicio rápido (5 minutos)**
- [INSTALL.md](INSTALL.md) - Guía de instalación paso a paso
- [SECURITY.md](SECURITY.md) - Guía de seguridad y manejo de secretos
- [FAQ.md](FAQ.md) - Preguntas frecuentes
- [CHANGELOG.md](CHANGELOG.md) - Registro de cambios
- [packages/README.md](packages/README.md) - Gestión de paquetes

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Lee la [Guía de Seguridad](SECURITY.md)
2. Asegúrate de no incluir información sensible
3. Abre un issue o pull request
4. Describe claramente tus cambios

## 📄 Licencia

MIT License - Siéntete libre de usar y modificar estos dotfiles.

## 🙏 Créditos

- [Catppuccin](https://github.com/catppuccin) - Tema de colores
- [Hyprland](https://hyprland.org/) - Compositor Wayland
- [Starship](https://starship.rs/) - Prompt
- Comunidad de Arch Linux

---

**¡Disfruta de tu nuevo entorno!** 🎉
