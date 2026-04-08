#!/bin/bash

# --- CONFIGURACIÓN Y COLORES ---
ROJO='\033[0;31m'
VERDE='\033[0;32m'
CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

# Variables globales
ESTADO="INICIANDO"
MINUTOS="00:00"
PROGRESO_PORCENTAJE=0
COLOR_ACTUAL=$VERDE

# --- FUNCIONES DE INTERFAZ ---

# centrar texto
print_center() {
    local texto="$1"
    local color="$2"
    local fila="$3"
    local columnas=$(tput cols)
    local col=$(( (columnas - ${#texto}) / 2 ))
    [ $col -lt 0 ] && col=0 # Evitar errores en ventanas mini
    tput cup $fila $col
    echo -e "${color}${texto}${NC}"
}

# --- Pantalla de Inicio Responsiva ---
mostrar_inicio() {
    clear
    local lineas=$(tput lines)
    local columnas=$(tput cols)
    local centro_v=$(( lineas / 2 ))
    local centro_h=$(( columnas / 2 ))

    # 1. Bordes Responsivos
    tput cup 0 0
    printf "${CYAN}┏%0.s" $(seq 1 $((columnas - 2)))
    printf "┓${NC}"
    tput cup $((lineas - 1)) 0
    printf "${CYAN}┗%0.s" $(seq 1 $((columnas - 2)))
    printf "┛${NC}"

    # 2. Arte ASCII Minimalista (Responsivo a ventanas estrechas)
    if [ $columnas -gt 60 ]; then
        print_center "  __  __   ____   __  __   ___  _____  _____  ____   __  __  " "$ROJO" $((centro_v - 7))
        print_center " |  \/  | |  _ \ |  \/  | / _ \|_   _|| ____||  _ \ |  \/  | " "$ROJO" $((centro_v - 6))
        print_center " | |\/| | | |_) || |\/| || | | | | |  |  _|  | |_) || |\/| | " "$ROJO" $((centro_v - 5))
        print_center " | |  | | |  __/ | |  | || |_| | | |  | |___ |  _ < | |  | | " "$ROJO" $((centro_v - 4))
        print_center " |_|  |_| |_|    |_|  |_| \___/  |_|  |_____||_| \_\|_|  |_| " "$ROJO" $((centro_v - 3))
    else
        print_center "☉ POMOTERM ☉" "$BOLD$ROJO" $((centro_v - 5))
    fi

    # 3. Marco de Configuración y Título
    print_center "─────────────────────────────────" "$CYAN" $((centro_v - 1))
    print_center "CONFIGURATION" "$AMARILLO" $((centro_v))
    print_center "─────────────────────────────────" "$CYAN" $((centro_v + 1))

    # 4. Inputs Interactivos (Posicionados responsivamente)
    tput cnorm # Mostrar cursor
    tput cup $((centro_v + 3)) $((centro_h - 15))
    echo -ne "${CYAN}┌${NC}"
    echo -ne " ${NC}Minutes of WORK (def. 25): "
    read WORK_MIN
    
    tput cup $((centro_v + 5)) $((centro_h - 15))
    echo -ne "${CYAN}┌${NC}"
    echo -ne " ${NC}Minutes of BREAK (def. 5): "
    read BREAK_MIN

    WORK_TIME=${WORK_MIN:-25}
    BREAK_TIME=${BREAK_MIN:-5}
    tput civis # Ocultar cursor para el temporizador
}

# --- Pantalla del Temporizador Responsiva (idéntica a la V3 pero con mejoras visuales) ---
redibujar_timer() {
    tput cup 0 0
    local lineas=$(tput lines)
    local columnas=$(tput cols)
    local centro_v=$(( lineas / 2 ))

    # 1. Bordes Responsivos
    tput cup 0 0
    printf "${CYAN}┏%0.s" $(seq 1 $((columnas - 2)))
    printf "┓${NC}"
    tput cup $((lineas - 1)) 0
    printf "${CYAN}┗%0.s" $(seq 1 $((columnas - 2)))
    printf "┛${NC}"

    # 2. Renderizar elementos
    print_center "☉ POMOTERM ☉" "$BOLD$CYAN" $((centro_v - 5))
    print_center "⏱︎  MOOD: $ESTADO" "$COLOR_ACTUAL" $((centro_v - 3))
    print_center "┌────────────────────────┐" "$AMARILLO" $((centro_v - 2))
    print_center "│      $MINUTOS       │" "$BOLD$AMARILLO" $((centro_v - 1))
    print_center "└────────────────────────┘" "$AMARILLO" $((centro_v))

    # --- Barra de progreso responsiva y centrada ---
    local ancho_barra=$(( columnas / 2 )) # La barra ocupará el 50% del ancho
    
    # Si la terminal es muy pequeña, fijamos un mínimo
    [ $ancho_barra -lt 20 ] && ancho_barra=$((columnas - 10))

    local relleno=$(( (ancho_barra * PROGRESO_PORCENTAJE) / 100 ))
    local barra=$(printf "%${relleno}s" | tr ' ' '|')
    local fondo=$(printf "%$((ancho_barra - relleno))s" | tr ' ' '.')
    
    # Creamos la cadena completa de la barra (sin colores para calcular el centro)
    local barra_completa="[$barra$fondo]"
    
    # Usamos print_center para que se encargue de posicionarla
    print_center "$barra_completa" "$CYAN" $((centro_v + 3))


    # Pie de página
    print_center "Press [Ctrl+C] to EXIT" "$NC" $((lineas - 2))
}

# --- LÓGICA DE CONTROL ---

# Capturar salida limpia y redibujado de la TUI
trap 'if [ "$ESTADO" = "CONFIGURANDO" ]; then mostrar_inicio; else redibujar_timer; fi' SIGWINCH
trap 'tput cnorm; clear; exit' SIGINT

# --- EJECUCIÓN ---

# 1. Pantalla de Inicio
ESTADO="CONFIGURANDO"
mostrar_inicio

clear

# 2. Bucle Principal del Temporizador
while true; do
    # Ciclo de Trabajo
    ESTADO="CONCENTRATION"
    COLOR_ACTUAL=$VERDE
    total=$((WORK_TIME * 60))
    for ((i=total; i>=0; i--)); do
        MINUTOS=$(printf "%02d:%02d" $((i/60)) $((i%60)))
        PROGRESO_PORCENTAJE=$(( 100 - (i * 100 / total) ))
        redibujar_timer
        sleep 1
    done
    notify-send "PomoTerm" "Time to REST ⛾"

    # Ciclo de Descanso
    ESTADO="BREAK"
    COLOR_ACTUAL=$ROJO
    total=$((BREAK_TIME * 60))
    for ((i=total; i>=0; i--)); do
        MINUTOS=$(printf "%02d:%02d" $((i/60)) $((i%60)))
        PROGRESO_PORCENTAJE=$(( 100 - (i * 100 / total) ))
        redibujar_timer
        sleep 1
    done
    notify-send "PomoTerm" "Get back to WORK ꚰ"
done
