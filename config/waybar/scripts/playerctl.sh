#!/usr/bin/env bash

# ================================================
# PLAYERCTL SCRIPT
# ================================================

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

readonly MAX_LENGTH=32
readonly SCROLL_DELAY=3  # Frames de espera antes de iniciar el scroll

scroll_offset=0
scroll_delay_counter=0
SCROLL_RESULT=""
previous_track=""
previous_time_info=""

# ================================
# Help Menu
# ================================

help() {
    echo "Uso: $0 [opciones]"
}

# ================================
# Funciones Auxiliares
# ================================

get_first_artist() {
    local artist="$1"
    echo "${artist%%,*}"
}

scroll_text() {
    local text="$1"
    local length=${#text}
    
    if [[ $length -le $MAX_LENGTH ]]; then
        SCROLL_RESULT="$text"
        scroll_offset=0
        scroll_delay_counter=0
        return
    fi

    # Si estamos en el periodo de espera, mostrar desde el inicio
    if [[ $scroll_delay_counter -lt $SCROLL_DELAY ]]; then
        SCROLL_RESULT="${text:0:$MAX_LENGTH}"
        ((scroll_delay_counter++))
        return
    fi
    
    local full_scroll="${text:$scroll_offset}${text:0:$scroll_offset}"
    SCROLL_RESULT="${full_scroll:0:$MAX_LENGTH}"

    scroll_offset=$(((scroll_offset + 1) % length))
}

cleanup() {
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.pid"
    [[ -f "$pid_file" ]] || return
    read -r pid <"$pid_file"
    [[ -d "/proc/$pid" ]] || return
    read -rd '' cmd < "/proc/$pid/cmdline"
    : "$cmd"
    case $cmd in
        -playerctl|playerctl|*/playerctl)
            echo >&2 "Killing playerctl [$pid]"
            kill "$pid" 2>/dev/null
    esac
    rm -f "$pid_file"
}

# ================================
# Función Principal
# ================================

main() {
    # Verificar que playerctl existe
    if ! command -v playerctl &>/dev/null; then
        printf '{"text":"⚠️","tooltip":"playerctl no está instalado","class":"error"}\n'
        exit 1
    fi
    
    cleanup
    trap cleanup EXIT INT

    while true; do
    # Verificar si hay players activos antes de iniciar
    if ! playerctl -l 2>/dev/null | grep -q .; then
        printf '{"text":"","tooltip":"No hay reproducción activa","class":"inactive"}\n'
        sleep 2
        continue
    fi
    
    while IFS='|' read -r status position length name artist title hpos hlen || [[ -n "$status" ]]; do
        # Verificar si aún hay players activos
        if ! playerctl -l 2>/dev/null | grep -q .; then
            printf '{"text":"","tooltip":"No hay reproducción activa","class":"inactive"}\n'
            break
        fi
        
        # Remover el prefijo ":"
        status=${status:1}
        position=${position:1}
        length=${length:1}
        name=${name:1}
        artist=${artist:1}
        title=${title:1}
        hpos=${hpos:1}
        hlen=${hlen:1}
        
        # Si no hay datos válidos, continuar
        [[ -z "$status" && -z "$title" ]] && continue
        
        # Obtener solo el primer artista
        if [[ -n "$artist" ]]; then
            artist=$(get_first_artist "$artist")
        fi
        
        # Crear identificador único de la canción
        current_track="$artist|$title"
        
        # Variable para detectar si es un cambio de canción
        track_changed=false
        
        # Resetear scroll si cambió la canción
        if [[ "$current_track" != "$previous_track" ]]; then
            scroll_offset=0
            scroll_delay_counter=0
            previous_track="$current_track"
            previous_time_info=""
            track_changed=true
        fi
        
        # Construir información de tiempo
        time_info=""
        if [[ -n "$hpos" && -n "$hlen" ]]; then
            time_info="$hpos/$hlen"
        fi
        
        # Si el tiempo no ha cambiado y no es un cambio de canción, no procesar
        if [[ "$time_info" == "$previous_time_info" && -n "$previous_time_info" && "$track_changed" == false ]]; then
            continue
        fi
        previous_time_info="$time_info"
        
        # Construir línea de información
        if [[ -n "$artist" && -n "$title" ]]; then
            info_line="$title - $artist"
        elif [[ -n "$title" ]]; then
            info_line="$title"
        else
            info_line="Sin información"
        fi
        
        # Añadir espacios en blanco solo si el texto necesita scroll
        if [[ ${#info_line} -gt $MAX_LENGTH ]]; then
            info_line="${info_line}          "
        fi
        
        # Aplicar scroll al texto
        scroll_text "$info_line"
        scrolled_text="$SCROLL_RESULT"
        
        scrolled_text="${scrolled_text//\"/\\\"}"

        ((percentage = length ? (100 * position) / length : 0))
        
        case $status in
            Paused)
                text="$time_info ${time_info:+| }$scrolled_text"
                css_class="paused"
                ;;
            Playing)
                text="$time_info ${time_info:+| }$scrolled_text"
                css_class="playing"
                ;;
            *)
                # Estados transitorios (Stopped) durante cambios de canción
                # Si es el primer estado después de cambiar de canción, mostrarlo
                if [[ "$track_changed" == true ]]; then
                    text="$time_info ${time_info:+| }$scrolled_text"
                    css_class="stopped"
                else
                    # Estados Stopped que no son el inicio se envían a stderr
                    tooltip="$status: $name"
                    if [[ -n "$artist" && -n "$title" ]]; then
                        tooltip="$tooltip\n$title - $artist"
                    elif [[ -n "$title" ]]; then
                        tooltip="$tooltip\n$title"
                    fi
                    if [[ -n "$hpos" && -n "$hlen" ]]; then
                        tooltip="$tooltip\n[$hpos / $hlen]"
                    fi
                    printf '{"text":"Detenido","tooltip":"%s","class":"stopped","percentage":0}\n' \
                        "$tooltip" >&2
                    continue
                fi
                ;;
        esac
        
        # Construir tooltip con información completa
        tooltip="$status: $name"
        if [[ -n "$artist" && -n "$title" ]]; then
            tooltip="$tooltip\n$title - $artist"
        elif [[ -n "$title" ]]; then
            tooltip="$tooltip\n$title"
        fi
        if [[ -n "$hpos" && -n "$hlen" ]]; then
            tooltip="$tooltip\n[$hpos / $hlen]"
        fi
        
        # Salida JSON para Waybar
        printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
            "$text" "$tooltip" "$css_class" "$percentage" || break 2
            
    done < <(
        # Usar playerctl con --follow para actualizaciones en tiempo real
        playerctl --follow metadata --format \
            $':{{status}}|:{{position}}|:{{mpris:length}}|:{{playerName}}|:{{artist}}|:{{title}}|:{{duration(position)}}|:{{duration(mpris:length)}}' &
        echo $! >"${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.pid"
    )
    
    cleanup
    sleep 2
    done
}

main "$@"