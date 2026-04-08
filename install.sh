#!/bin/bash

# Colores para el instalador
VERDE='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Installing PomoTerm...${NC}"

# 1. Comprobar dependencias (Basado en comandos comunes)
if ! command -v notify-send &> /dev/null; then
    echo "WARNING: 'libnotify' is not installed. You will not see desktop notifications"
fi

# 2. Dar permisos de ejecución
chmod +x pomoterm.sh

# 3. Mover al PATH del sistema
echo "SUDO is required for  /usr/local/bin"
sudo cp pomoterm.sh /usr/local/bin/pomoterm

echo -e "${VERDE}------------------------------------------------${NC}"
echo -e "${VERDE}¡COMPLETE!${NC}"
echo -e "Execute typing: ${CYAN}pomoterm${NC}"
echo -e "${VERDE}------------------------------------------------${NC}"
