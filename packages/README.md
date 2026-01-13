# Paquetes - Dotfiles

Este directorio contiene listas de paquetes organizadas por categoría.

## 📦 Archivos

- **essential.txt** - Paquetes del sistema base (requeridos)
- **desktop.txt** - Componentes del entorno de escritorio
- **fonts.txt** - Fuentes del sistema
- **shell.txt** - Shell y herramientas CLI
- **development.txt** - Herramientas de desarrollo
- **applications.txt** - Aplicaciones de usuario
- **aur.txt** - Paquetes del AUR

## ⚠️ Notas Importantes

### Essential Packages
No elimines paquetes de `essential.txt` a menos que sepas exactamente lo que estás haciendo.
Estos paquetes son necesarios para el funcionamiento básico del sistema.

### Graphics Drivers
Los drivers incluidos son para Intel. Si tienes AMD/NVIDIA, reemplázalos:

**AMD:**
```
mesa
xf86-video-amdgpu
vulkan-radeon
lib32-vulkan-radeon
```

**NVIDIA:**
```
nvidia
nvidia-utils
lib32-nvidia-utils
```

### Display Manager
SDDM es el gestor de inicio de sesión por defecto. Alternativas:
- GDM (GNOME Display Manager)
- LightDM
- ly (CLI Display Manager)

## 📝 Formato de Archivos

- Líneas que comienzan con `#` son comentarios
- Líneas vacías son ignoradas
- Un paquete por línea
- No uses comillas

**Ejemplo:**
```
# Esta es una categoría
paquete1
paquete2

# Otra categoría
paquete3
```

## 🔧 Uso

### Instalar una categoría completa

```bash
# Paquetes oficiales
cat packages/ARCHIVO.txt | grep -v '^#' | grep -v '^$' | xargs sudo pacman -S --needed

# Paquetes AUR
cat packages/aur.txt | grep -v '^#' | grep -v '^$' | xargs paru -S --needed
```

### Añadir un nuevo paquete

1. Identifica la categoría apropiada
2. Edita el archivo correspondiente
3. Añade el paquete al final o en la sección apropiada
4. Instala: `sudo pacman -S nombre-paquete`

### Remover un paquete

1. Desinstala el paquete: `sudo pacman -Rns nombre-paquete`
2. Elimina la línea del archivo de paquetes

## 🔍 Verificar Paquetes

### Ver qué paquetes están instalados

```bash
# De una lista
comm -12 <(cat packages/desktop.txt | grep -v '^#' | sort) <(pacman -Qq | sort)

# Todos los paquetes explícitamente instalados
pacman -Qe
```

### Ver paquetes huérfanos

```bash
pacman -Qdt
```

### Limpiar paquetes huérfanos

```bash
sudo pacman -Rns $(pacman -Qdtq)
```

## 📊 Estadísticas

Para ver cuántos paquetes hay en cada categoría:

```bash
for file in packages/*.txt; do
    count=$(grep -v '^#' "$file" | grep -v '^$' | wc -l)
    echo "$(basename $file): $count paquetes"
done
```

## 🔄 Actualizar Todo

```bash
# Paquetes oficiales
sudo pacman -Syu

# Incluir AUR
paru -Syu
```

## 🆘 Ayuda

Si un paquete no se encuentra:
1. Verifica el nombre: `pacman -Ss nombre-parcial`
2. Puede estar en AUR: `paru -Ss nombre-parcial`
3. Puede haber sido renombrado o removido

Para más información sobre un paquete:
```bash
pacman -Si nombre-paquete      # Información del repositorio
pacman -Qi nombre-paquete      # Información de paquete instalado
```
