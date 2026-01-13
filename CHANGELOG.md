# Changelog

## [1.0.0] - 2026-01-12

### Añadido
- Sistema completo de instalación automatizada
- Script `install.sh` con instalación interactiva
- Organización de paquetes en archivos separados:
  - `essential.txt` - Paquetes del sistema base
  - `desktop.txt` - Entorno de escritorio
  - `fonts.txt` - Fuentes del sistema
  - `shell.txt` - Shell y herramientas CLI
  - `development.txt` - Herramientas de desarrollo
  - `applications.txt` - Aplicaciones de usuario
  - `aur.txt` - Paquetes del AUR
- README completo con documentación detallada
- Script de desinstalación (`uninstall.sh`)
- Sistema de backup automático de configuraciones
- Soporte para Hyprland y Sway
- Tema Catppuccin Mocha en todos los componentes
- SDDM Pixel Theme personalizado

### Configuraciones Incluidas
- Fish shell con plugins (fisher, catppuccin)
- Starship prompt personalizado
- Kitty terminal con tema Catppuccin
- Waybar con módulos personalizados
- Dunst/Mako para notificaciones
- Hyprland con animaciones y efectos
- Sway como alternativa a Hyprland
- Scripts de screenshot con satty
- Mise para gestión de versiones de desarrollo

### Herramientas CLI
- eza (reemplazo de ls)
- bat (reemplazo de cat)
- zoxide (cd inteligente)
- fzf (fuzzy finder)
- ripgrep (búsqueda rápida)

### Desarrollo
- Soporte para Docker
- Mise con múltiples lenguajes configurados
- PostgreSQL
- Dependencias para PHP, Node, Python, etc.
