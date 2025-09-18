#!/bin/bash

# Script de Otimização do Ubuntu e instalar ferramentas
# Descrição: Remove pacotes desnecessários e instala utilitários essenciais
# Autor: Rodrigoh
# Versão: 2.0
# Aviso: Use por sua conta e risco. Sempre teste em ambiente não produtivo primeiro.

# Cores para output
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # No Color

set -euo pipefail

# Verificar root
[ "$EUID" -ne 0 ] && echo "Execute como root!" && exit 1

echo -e "${AZUL}=== Limpeza Segura do Ubuntu ===${NC}"

# Atualizar primeiro
apt update

# Pacotes seguros para remover
PACOTES_SEGUROS=(
    "gnome-mahjongg"
    "gnome-mines"
    "gnome-sudoku"
    "aisleriot"
    "thunderbird"
    "rhythmbox"
    "simple-scan"
    "cheese"
    "example-content"
    "popularity-contest"
    "apport"
    "whoopsie"
    "ubuntu-report"
    "deja-dup"
    "gnome-orca"
    "gnome-chess"
    "snapd"
    "snap-confine"
    "gnome-software-plugin-snap"
    "transmission-common"
    "gnome-user-docs"
    "yelp"
    "totem"
    "gnome-software"
    "update-notifier"
    "zeitgeist"
    "speech-dispatcher"
    "brltty"
)

# Remover apenas estes
for pkg in "${PACOTES_SEGUROS[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        echo -e "${AMARELO}Removendo: $pkg${NC}"
        apt purge --auto-remove -y "$pkg" 2>/dev/null || true
    fi
done

# Limpeza
apt autoremove --purge -y
apt clean
apt autoclean

echo -e "${VERDE}Limpeza concluída com segurança!${NC}"
