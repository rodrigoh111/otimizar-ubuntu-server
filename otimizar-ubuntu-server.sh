#!/bin/bash

# Script de Otimização do Ubuntu
# Descrição: Remove pacotes desnecessários e instala utilitários essenciais
# Autor: Rodrigoh
# Versão: 2.0
# Aviso: Use por sua conta e risco. Sempre teste em ambiente não produtivo primeiro.

set -euo pipefail

# Cores para output
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # No Color

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELHO}Por favor, execute como root usando sudo!${NC}"
    exit 1
fi

# Informações do sistema
echo -e "${AZUL}=== Otimizador do Sistema Ubuntu ===${NC}"
echo -e "Hostname: $(hostname)"
echo -e "Versão do Ubuntu: $(lsb_release -d | cut -f2)"
echo -e "Kernel: $(uname -r)"
echo -e "Memória: $(free -h | awk '/^Mem:/ {print $2}')"
echo

# Confirmar execução
read -p "Deseja continuar com a otimização do sistema? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${AMARELO}Operação cancelada.${NC}"
    exit 0
fi

# Backup da lista de fontes
echo -e "${AZUL}Fazendo backup das fontes de pacotes...${NC}"
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
echo -e "${VERDE}Backup criado: /etc/apt/sources.list.backup.$(date +%Y%m%d)${NC}"

# Atualizar lista de pacotes
echo -e "${AZUL}Atualizando lista de pacotes...${NC}"
apt update

# Função para remover pacotes com segurança
remover_seguro() {
    local pacotes=("$@")
    for pkg in "${pacotes[@]}"; do
        if apt list --installed 2>/dev/null | grep -q "^$pkg"; then
            echo -e "${AMARELO}Removendo: $pkg${NC}"
            apt purge --auto-remove -y "$pkg" 2>/dev/null || true
        fi
    done
}

# Lista de pacotes que geralmente podem ser removidos com segurança
PACOTES_REMOVIVEIS=(
    "snapd" "snap-confine" "gnome-software-plugin-snap"
    "gnome-mahjongg" "gnome-mines" "gnome-sudoku" "aisleriot" "gnome-chess"
    "thunderbird" "transmission-common" "rhythmbox" "simple-scan" "cheese"
    "gnome-user-docs" "yelp" "example-content" "totem"
    "deja-dup" "gnome-software" "update-notifier" "zeitgeist"
    "popularity-contest" "apport" "whoopsie" "ubuntu-report"
    "gnome-orca" "speech-dispatcher" "brltty"
)

# Remover pacotes desnecessários
echo -e "${AZUL}Removendo pacotes desnecessários...${NC}"
remover_seguro "${PACOTES_REMOVIVEIS[@]}"

# Remover pacotes órfãos e limpar cache
echo -e "${AZUL}Limpando pacotes órfãos e cache...${NC}"
apt autoremove --purge -y
apt clean
apt autoclean

# Instalar utilitários essenciais
echo -e "${AZUL}Instalando utilitários essenciais...${NC}"

PACOTES_ESSENCIAIS=(
    "htop" "iotop" "nethogs" "iftop" "dstat" "ncdu"
    "net-tools" "iputils-ping" "dnsutils" "traceroute"
    "curl" "wget" "aria2" "ssh" "openssh-client" "openssh-server"
    "software-properties-common" "apt-transport-https"
    "ca-certificates" "gnupg" "lsb-release" "ubuntu-restricted-extras"
    "build-essential"
    "lshw" "inxi" "lsof" "strace" "hdparm"
    "python3" "python3-pip" "python3-venv" "python3-dev"
    "pipx" "jq" "yq" "tmux" "screen" "zip" "unrar" "testdisk" "fdupes"
)

for pkg in "${PACOTES_ESSENCIAIS[@]}"; do
    if ! dpkg -l | grep -q "^ii.*$pkg"; then
        echo -e "${VERDE}Instalando: $pkg${NC}"
        apt install -y "$pkg"
    else
        echo -e "${AMARELO}Já instalado: $pkg${NC}"
    fi
done

# Configurar atualizações de segurança automáticas
echo -e "${AZUL}Configurando atualizações de segurança automáticas...${NC}"
apt install -y unattended-upgrades
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades

# Limpeza final agressiva
echo -e "${AZUL}Executando limpeza final...${NC}"
apt autoremove --purge -y
apt clean

# Atualização final do sistema
echo -e "${AZUL}Atualizando sistema...${NC}"
apt update
apt upgrade -y

# Criar relatório de pacotes instalados
echo -e "${AZUL}Criando relatório de pacotes instalados...${NC}"
dpkg -l | grep '^ii' > /tmp/pacotes_instalados_depois.txt
echo "Otimização concluída em: $(date)" > /var/log/otimizacao-sistema.log

# Verificação do sistema
echo -e "${VERDE}
=== Otimização Concluída ===
Uso de Disco:
$(df -h / | grep -v Filesystem)

Uso de Memória:
$(free -h)

Serviços Ativos:
$(systemctl list-units --type=service --state=running | head -8)
${NC}"

echo -e "${VERDE}Otimização do sistema concluída com sucesso!${NC}"
echo -e "${AMARELO}Recomendação: Reinicie o sistema para aplicar todas as mudanças.${NC}"

# Perguntar sobre reinicialização
read -p "Deseja reiniciar o sistema agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${AZUL}Reiniciando o sistema...${NC}"
    reboot
else
    echo -e "${AMARELO}Lembre-se de reiniciar mais tarde para aplicar todas as mudanças.${NC}"
fi
