# Preguntas Frecuentes (FAQ)

## General

### ¿Qué es esto?
Un conjunto de archivos de configuración (dotfiles) para crear un entorno de escritorio Wayland moderno en Arch Linux.

### ¿Puedo usar esto en otra distribución?
Está diseñado específicamente para Arch Linux, pero puedes adaptar las configuraciones a otras distribuciones. Los archivos de configuración son compatibles, pero los scripts de instalación necesitarían modificaciones.

### ¿Cuánto espacio necesito?
Aproximadamente 5-10 GB para todos los paquetes y herramientas.

## Instalación

### ¿Puedo instalar solo algunas partes?
Sí, el script de instalación es interactivo. Puedes elegir qué componentes instalar.

### ¿Qué pasa con mis configuraciones actuales?
El script crea un backup automático en `~/.config-backup-FECHA/`. Siempre puedes restaurar tus configuraciones anteriores.

### ¿Necesito instalar Hyprland Y Sway?
No, puedes elegir solo uno. Ambos están incluidos para dar opciones.

### El script falló, ¿qué hago?
1. Lee el mensaje de error
2. Verifica tu conexión a Internet
3. Asegúrate de tener espacio en disco
4. Consulta la sección de solución de problemas

## Uso

### ¿Cómo cambio entre Hyprland y Sway?
En la pantalla de inicio de sesión (SDDM), haz clic en el selector de sesión y elige el compositor deseado.

### ¿Cómo cambio el wallpaper?
Ejecuta `waypaper` en la terminal.

### ¿Cómo tomo screenshots?
- `Print`: Screenshot de una región (selecciona con el mouse)
- `Shift + Print`: Screenshot completa

### ¿Dónde se guardan los screenshots?
En `~/media/images/screenshots/`

### No funciona el audio, ¿qué hago?
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
pavucontrol  # Para configurar audio
```

### No aparece Waybar
```bash
killall waybar
waybar &
```

## Personalización

### ¿Cómo cambio el tema de colores?
Actualmente usa Catppuccin Mocha. Para cambiar:
1. Busca otros temas de Catppuccin (Latte, Frappe, Macchiato)
2. O usa otros esquemas de color y edita los archivos en `themes/`

### ¿Cómo cambio los atajos de teclado?
- **Hyprland**: Edita `~/.config/hypr/hyprland.conf.d/bind.conf`
- **Sway**: Edita `~/.config/sway/sway.config.d/keybinding.conf`

### ¿Cómo añado más módulos a Waybar?
1. Crea un archivo en `waybar/modules/`
2. Añádelo en `waybar/config.jsonc` en la sección `include`
3. Reinicia Waybar: `killall waybar && waybar &`

### ¿Cómo cambio la fuente?
Edita estos archivos:
- Terminal: `kitty/kitty.conf.d/general.conf`
- Notificaciones: `dunst/dunstrc`
- Todo el sistema: Instala la fuente deseada y actualiza los configs

## Desarrollo

### ¿Cómo instalo Node.js/Python/PHP?
Usa Mise:
```bash
mise use --global node@lts
mise use --global python@3.12
mise use --global php@8.4
```

### ¿Cómo actualizo las versiones de Mise?
```bash
mise upgrade
mise ls-remote node  # Ver versiones disponibles
mise use --global node@20
```

### ¿Puedo usar nvm/pyenv en lugar de Mise?
Sí, pero necesitarás modificar `fish/config.fish` y remover la línea de Mise.

### Docker no funciona (permission denied)
```bash
sudo usermod -aG docker $USER
# Cierra sesión y vuelve a entrar
```

## Paquetes

### ¿Cómo añado un nuevo paquete?
1. Edita el archivo correspondiente en `packages/`
2. Instálalo: `sudo pacman -S nombre-paquete`
3. O reinstala todo: `cat packages/ARCHIVO.txt | grep -v '^#' | xargs sudo pacman -S --needed`

### ¿Cómo actualizo todos los paquetes?
```bash
sudo pacman -Syu        # Paquetes oficiales
paru -Syu               # Incluye AUR
```

### ¿Qué es Paru?
Un AUR helper que facilita la instalación de paquetes del Arch User Repository.

### ¿Puedo usar yay en lugar de paru?
Sí, son intercambiables. Solo reemplaza `paru` por `yay` en los comandos.

## Problemas Comunes

### "Command not found" después de instalar
Si instalaste herramientas nuevas, cierra y vuelve a abrir la terminal, o ejecuta:
```bash
hash -r  # en bash
fish_update_completions  # en fish
```

### Las fuentes Nerd no se ven bien
1. Verifica que estén instaladas: `fc-list | grep -i nerd`
2. Actualiza la caché de fuentes: `fc-cache -fv`
3. Reinicia las aplicaciones

### Hyprland: ventanas transparentes no se ven bien
Revisa la configuración de blur en `hypr/hyprland.conf.d/decoration.conf`

### Sway: las animaciones son lentas
Sway no tiene animaciones nativas. Si quieres animaciones, usa Hyprland.

### El sistema se siente lento
1. Verifica uso de CPU/RAM: `btop` o `htop`
2. Reduce efectos en Hyprland (desactiva blur/shadows)
3. Considera usar Sway (más ligero)

## Desinstalación

### ¿Cómo desinstalo todo?
```bash
./uninstall.sh
```

Esto restaura tus configuraciones previas (si hay backup).

### ¿Los paquetes se desinstalansolol también?
No, debes removerlos manualmente si lo deseas:
```bash
sudo pacman -R nombre-paquete
```

### ¿Cómo restauro GNOME/KDE/etc?
Si hiciste backup:
1. Ejecuta `./uninstall.sh` para restaurar configs
2. Cambia el display manager si es necesario
3. Selecciona tu sesión anterior en el login

## Seguridad

### ¿Hay un token de GitHub en los archivos?
Sí, en `fish/config.fish` hay un token de ejemplo. **DEBES CAMBIARLO O ELIMINARLO** antes de hacer tu repositorio público.

### ¿Es seguro ejecutar el script de instalación?
El script está diseñado para ser seguro, pero siempre debes:
1. Leer el script antes de ejecutarlo
2. Entender qué hace cada comando
3. Hacer backup de tus datos importantes

## Contribuir

### ¿Cómo contribuyo?
1. Haz fork del repositorio
2. Crea una branch: `git checkout -b feature/mi-feature`
3. Commit tus cambios: `git commit -am 'Añade mi feature'`
4. Push: `git push origin feature/mi-feature`
5. Abre un Pull Request

### ¿Qué tipo de contribuciones se aceptan?
- Correcciones de bugs
- Nuevas características
- Mejoras en documentación
- Optimizaciones
- Nuevos temas

## Recursos

### ¿Dónde aprendo más sobre Hyprland?
- [Documentación oficial](https://wiki.hyprland.org/)
- [GitHub](https://github.com/hyprwm/Hyprland)

### ¿Y sobre Sway?
- [Documentación oficial](https://swaywm.org/)
- [GitHub](https://github.com/swaywm/sway)

### ¿Dónde encuentro más temas?
- [r/unixporn](https://www.reddit.com/r/unixporn/)
- [Catppuccin](https://github.com/catppuccin/catppuccin)
- [Dracula](https://draculatheme.com/)
- [Nord](https://www.nordtheme.com/)
