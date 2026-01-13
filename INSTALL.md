# Guía de Instalación Paso a Paso

Esta guía te ayudará a instalar los dotfiles desde cero en un sistema Arch Linux limpio.

## 📋 Pre-requisitos

1. **Sistema Arch Linux instalado** con conexión a Internet
2. **Usuario con privilegios sudo** configurado
3. **5-10 GB de espacio libre** en disco

## 🚀 Opción 1: Instalación Automática (Recomendado)

### Paso 1: Clonar el repositorio

```bash
# Instalar git si no lo tienes
sudo pacman -S git

# Clonar el repositorio
git clone https://github.com/fhuaquistoq/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Paso 2: Ejecutar el instalador

```bash
./install.sh
```

El instalador te preguntará qué componentes deseas instalar. Responde:
- `Y` para instalar
- `N` para omitir

### Paso 3: Reiniciar

```bash
sudo reboot
```

### Paso 4: Seleccionar sesión

En la pantalla de inicio de sesión (SDDM):
1. Click en el icono de sesión (esquina superior derecha)
2. Selecciona **Hyprland** o **Sway**
3. Inicia sesión

¡Listo! 🎉

## 🔧 Opción 2: Instalación Manual

### 1. Habilitar Multilib

```bash
sudo nano /etc/pacman.conf
```

Busca y descomenta:
```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Guarda (Ctrl+O) y sal (Ctrl+X).

```bash
sudo pacman -Sy
```

### 2. Instalar Paquetes Base

```bash
cd ~/dotfiles

# Método 1: Instalación manual por categoría
sudo pacman -S $(grep -v '^#' packages/essential.txt | tr '\n' ' ')
sudo pacman -S $(grep -v '^#' packages/desktop.txt | tr '\n' ' ')
sudo pacman -S $(grep -v '^#' packages/fonts.txt | tr '\n' ' ')
sudo pacman -S $(grep -v '^#' packages/shell.txt | tr '\n' ' ')

# Método 2: Instalación selectiva
# Revisa cada archivo en packages/ y selecciona lo que necesitas
```

### 3. Habilitar Servicios

```bash
# NetworkManager (Internet)
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# SDDM (Display Manager)
sudo systemctl enable sddm
```

### 4. Instalar Paru (AUR Helper)

```bash
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ~/dotfiles
```

### 5. Instalar Paquetes AUR

```bash
paru -S $(grep -v '^#' packages/aur.txt | tr '\n' ' ')
```

### 6. Instalar Herramientas Adicionales

```bash
# Mise (gestor de versiones)
curl https://mise.run | sh

# Zed (editor, opcional)
curl -f https://zed.dev/install.sh | sh
```

### 7. Desplegar Configuraciones

```bash
# Crear backup
mkdir -p ~/.config-backup-$(date +%Y%m%d)
cp -r ~/.config/* ~/.config-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Copiar configs
cp -r fish kitty hypr sway waybar dunst environment.d mise ~/.config/
cp starship.toml ~/.config/

# Copiar scripts
mkdir -p ~/.local/bin
cp misc/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*
```

### 8. Configurar Fish

```bash
# Instalar Fisher (plugin manager)
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

# Instalar plugins
fish -c "fisher update"

# Establecer Fish como shell por defecto
chsh -s $(which fish)
```

### 9. Instalar Tema SDDM

```bash
cd ~/dotfiles/sddm/sddm-pixel
sudo bash setup.sh
cd ~/dotfiles
```

### 10. Reiniciar

```bash
sudo reboot
```

## ⚙️ Configuración Post-Instalación

### Configurar Monitores

Edita el archivo de monitores según tu compositor:

**Para Hyprland:**
```bash
nano ~/.config/hypr/hyprland.conf.d/monitors.conf
```

**Para Sway:**
```bash
nano ~/.config/sway/sway.config.d/variables.conf
```

Ejemplo para laptop:
```
monitor=eDP-1,1920x1080@60,0x0,1
```

Ejemplo para multi-monitor:
```
monitor=DP-1,2560x1440@144,0x0,1
monitor=DP-2,1920x1080@60,2560x0,1
```

### Configurar Wallpaper

```bash
waypaper
```

### Instalar Lenguajes de Programación con Mise

```bash
# Ver configuración actual
mise ls

# Instalar todo desde config.toml
mise install

# O instalar manualmente
mise use --global node@lts
mise use --global python@3.12
mise use --global php@8.4
```

### Configurar Git

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
git config --global init.defaultBranch main
```

### Habilitar Docker (si instalaste)

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Cerrar sesión y volver a entrar para aplicar cambios
```

## 🎨 Primeros Pasos

1. **Abre una terminal**: `Super + Return`
2. **Prueba los comandos modernos**:
   ```bash
   ls        # Ahora es eza con iconos
   ll        # Lista detallada con iconos
   cat file  # Ahora es bat con syntax highlighting
   cd        # Ahora es zoxide (cd inteligente)
   ```
3. **Toma un screenshot**: `Print` (región) o `Shift+Print` (completo)
4. **Cambia de workspace**: `Super + 1-9`
5. **Abre el launcher**: `Super + D` (si configuraste rofi)

## 📚 Próximos Pasos

- Lee el [README.md](README.md) principal para ver todos los atajos
- Personaliza los temas en los directorios `themes/`
- Revisa y edita `fish/config.fish` para ajustar aliases
- Explora Waybar en `waybar/config.jsonc`

## ❓ ¿Problemas?

Consulta la sección de [Solución de Problemas](README.md#-solución-de-problemas) en el README principal.
