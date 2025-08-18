#!/bin/bash

# Verificar se e root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script deve ser executado como root" >&2
  exit 1
fi

# Atualizar sistema
echo "Atualizando sistema..."
apt update && apt upgrade -y

# Remover pacotes desnecessarios
echo "Removendo pacotes desnecessarios..."
sudo apt purge --auto-remove snapd cloud-init lxd lxcfs open-iscsi rsyslog -y
sudo apt purge --auto-remove unattended-upgrades -y
sudo apt autoremove --purge -y
sudo apt clean

# Instalar pacotes essenciais
echo "Instalando pacotes essenciais..."
sudo apt install --no-install-recommends linux-image-generic linux-headers-generic -y
apt install iftop ncdu tmux iotop fail2ban sysstat fio sysbench -y

# Configurar otimizacoes de kernel
echo "Configurando otimizacoes de kernel..."
cat > /etc/sysctl.d/99-optimizations.conf << 'EOL'
# Otimizacoes para PostgreSQL/Firebird
kernel.shmmax = 17179869184
kernel.shmall = 4194304
vm.swappiness = 1
vm.dirty_ratio = 3
vm.dirty_background_ratio = 2
fs.file-max = 65536

# Rede
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.core.somaxconn = 4096

# Otimizacoes avancadas de I/O
vm.dirty_background_bytes = 16777216
vm.dirty_bytes = 50331648
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 1500

# Elevadores de I/O
block/nr_requests = 128
block/read_ahead_kb = 4096

# Limites de I/O
fs.aio-max-nr = 1048576
fs.file-max = 2097152
EOL

# Aplicar configuracoes do sysctl
sysctl -p /etc/sysctl.d/99-optimizations.conf

# Desabilitar servicos desnecessarios
echo "Desabilitando servicos desnecessarios..."
sudo systemctl disable --now avahi-daemon cups-browsed ModemManager

# Configurar I/O Scheduler para SSDs/HDDs
#echo "Otimizando I/O Scheduler..."

# Detecta se e SSD ou HDD
#if [ $(cat /sys/block/$(lsblk -no KNAME | head -1)/queue/rotational) -eq 0 ]; then
#  echo "Configurando noop para SSD/NVMe..."
#  echo 'ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-iosched-optimized.rules
#else
#  echo "Configurando deadline para HDD..."
#  echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="deadline"' > /etc/udev/rules.d/60-iosched-optimized.rules
#fi

# Aplicar regras do udev
#udevadm control --reload-rules
#udevadm trigger

# Configurar limites do sistema
#echo "Ajustando limites do sistema..."
#cat > /etc/security/limits.d/99-postgresql.conf << 'EOL'
#postgres soft nofile 65536
#postgres hard nofile 65536
#postgres soft nproc 16384
#postgres hard nproc 16384
#postgres soft stack 8192
#postgres hard stack 8192
#* soft nofile 65536
#* hard nofile 65536
#EOL

# Habilitar e configurar sysstat para monitoramento
#echo "Configurando monitoramento..."
#sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
#systemctl enable --now sysstat

echo "Otimizacao concluida!"
echo "Recomendacoes finais:"
echo "1. Reinicie o servidor para aplicar todas as configuracoes"
#echo "2. Configure seu banco de dados (PostgreSQL/Firebird) apos a reinicializacao"
echo "3. Considere usar XFS para particoes de dados com as opcoes: noatime,nodiratime,nobarrier"
