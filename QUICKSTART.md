```
 ____        _    __ _ _           
|  _ \  ___ | |_ / _(_) | ___  ___ 
| | | |/ _ \| __| |_| | |/ _ \/ __|
| |_| | (_) | |_|  _| | |  __/\__ \
|____/ \___/ \__|_| |_|_|\___||___/

Arch Linux + Hyprland/Sway + Fish
```

# 🚀 Guía de Inicio Rápido

## Instalación Express (5 minutos)

```bash
# 1. Clonar
git clone https://github.com/fhuaquistoq/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Instalar
./install.sh

# 3. Reiniciar
sudo reboot
```

## 🎯 Primeros Pasos

### 1. Selecciona tu compositor
En la pantalla de login (SDDM):
- Click en el icono de sesión (arriba a la derecha)
- Elige: **Hyprland** (con efectos) o **Sway** (ligero)

### 2. Atajos esenciales

| Tecla | Acción |
|-------|--------|
| `Super + Return` | Terminal |
| `Super + Shift + Q` | Cerrar ventana |
| `Super + 1-9` | Cambiar workspace |
| `Print` | Screenshot |

### 3. Comandos mejorados

Ya no usarás los comandos tradicionales:

```bash
ls    # → Ahora es eza con iconos
ll    # → Lista detallada bonita
cat   # → Ahora es bat con syntax highlight
cd    # → Ahora es zoxide (inteligente)
```

### 4. Configura tu entorno

```bash
# Wallpaper
waypaper

# Monitores (si es necesario)
nvim ~/.config/hypr/hyprland.conf.d/monitors.conf

# Git
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### 5. Instala lenguajes (opcional)

```bash
# Con Mise (version manager)
mise use --global node@lts
mise use --global python@3.12
mise install
```

## 📚 Documentación

- **[README.md](README.md)** - Documentación completa
- **[INSTALL.md](INSTALL.md)** - Guía paso a paso
- **[FAQ.md](FAQ.md)** - Preguntas frecuentes
- **[SECURITY.md](SECURITY.md)** - ⚠️ ¡Lee esto antes de hacer push!

## 🎨 Personalización Rápida

### Cambiar tema de terminal
```bash
nano ~/.config/kitty/themes/catppuccin-mocha.conf
```

### Modificar Waybar
```bash
nano ~/.config/waybar/config.jsonc
killall waybar && waybar &
```

### Añadir alias
```bash
nano ~/.config/fish/config.fish
# Añade: alias micomando="comando-real"
```

## ⚙️ Gestión de Paquetes

### Instalar nuevos paquetes

```bash
# Paquetes oficiales
sudo pacman -S nombre-paquete

# AUR (con paru)
paru -S nombre-paquete

# Y añádelo al archivo correspondiente
echo "nombre-paquete" >> packages/CATEGORIA.txt
```

### Actualizar sistema

```bash
paru -Syu  # Actualiza todo (oficial + AUR)
```

### Limpiar caché

```bash
sudo pacman -Sc   # Limpiar caché de paquetes
paru -Sc          # Incluir caché de AUR
```

## 🔧 Solución Rápida de Problemas

### Audio no funciona
```bash
systemctl --user restart pipewire wireplumber
pavucontrol
```

### Waybar desapareció
```bash
killall waybar
waybar &
```

### Notificaciones no aparecen
```bash
killall dunst
dunst &
```

### Terminal lenta
```bash
# Deshabilita comprobaciones en fish
set -U fish_greeting ""
```

## 🎯 Recursos Útiles

### Atajos de Sway
- `Super + H/J/K/L` - Mover foco (vim keys)
- `Super + Shift + 1-9` - Mover ventana a workspace
- `Super + Shift + Space` - Fullscreen
- `Super + Shift + F` - Toggle floating

### Comandos útiles
```bash
btop          # Monitor de sistema
ranger        # File manager TUI
nvim          # Editor de texto
```

### Directorios importantes
```
~/.config/              # Configuraciones
~/.config/fish/         # Shell config
~/.config/hypr/         # Hyprland config
~/.local/bin/           # Scripts personales
```

## 🆘 Ayuda

### ¿Algo salió mal?
1. Lee el mensaje de error
2. Busca en [FAQ.md](FAQ.md)
3. Revisa logs: `journalctl -xe`
4. Para Hyprland: `~/.local/share/hyprland/hyprland.log`

### ¿Quieres volver atrás?
```bash
./uninstall.sh
```

## 🎉 ¡Listo!

Tu sistema está configurado. Explora, personaliza y disfruta.

**Pro tip:** Presiona `Super + ?` en algunos compositores para ver todos los atajos.

---

**¿Preguntas?** Lee la [documentación completa](README.md) o abre un issue.
