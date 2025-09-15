#!/bin/bash

# Limpeza SEGURA do APT
echo "Fazendo limpeza segura do sistema APT..."
apt clean
apt autoclean
apt autoremove --purge -y

# Configurar otimizacoes de kernel para PostgreSQL
echo "Configurando otimizacoes de kernel para PostgreSQL..."

cat > /etc/sysctl.d/99-optimizations.conf << 'EOL'
# ============================================================================
# OTIMIZAÇÕES PARA POSTGRESQL
# ============================================================================

# Shared Memory - CRÍTICO para PostgreSQL
kernel.shmmax = 17179869184           # 16GB - Máximo tamanho de segmento de memória compartilhada
kernel.shmall = 4194304               # 16GB em páginas de 4KB - Total de memória compartilhada
kernel.shmmni = 4096                  # Número máximo de segmentos de memória compartilhada

# Semáforos - Importante para conexões
kernel.sem = 50100 64128000 50100 1280

# Memória Virtual
vm.swappiness = 1                     # Minimiza swap - importante para DB
vm.overcommit_memory = 2              # Previne overcommit de memória (seguro para PostgreSQL)
vm.overcommit_ratio = 95              # Percentual de overcommit permitido

# Configurações de Dirty Pages - Otimizado para escrita em disco
vm.dirty_background_ratio = 2         # 2% da memória para dirty pages background
vm.dirty_ratio = 3                    # 3% da memória para dirty pages máximo
vm.dirty_background_bytes = 16777216  # 16MB
vm.dirty_bytes = 50331648             # 48MB
vm.dirty_expire_centisecs = 3000      # 30 segundos para pages sujas expirarem
vm.dirty_writeback_centisecs = 1500   # 15 segundos para writeback

# ============================================================================
# OTIMIZAÇÕES DE REDE
# ============================================================================
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.ip_local_port_range = 1024 65000

# ============================================================================
# LIMITES DE SISTEMA
# ============================================================================
fs.file-max = 2097152                 # Máximo de arquivos abertos
fs.aio-max-nr = 1048576               # Máximo de operações AIO simultâneas
fs.inotify.max_user_watches = 524288  # Para monitoramento de muitos arquivos

# ============================================================================
# OTIMIZAÇÕES DE I/O
# ============================================================================
vm.vfs_cache_pressure = 50            # Balanceado para caching de arquivos
EOL

# Aplicar configuracoes do sysctl
echo "Aplicando configurações de kernel..."
sysctl -p /etc/sysctl.d/99-optimizations.conf

# Configurações específicas por dispositivo para I/O
echo "Otimizando configurações de I/O por dispositivo..."
for device in /sys/block/sd* /sys/block/nvme* /sys/block/vd*; do
    if [ -d "$device" ]; then
        echo "Otimizando dispositivo: $(basename "$device")"
        
        # Configurações gerais de I/O
        echo 128 > "$device/queue/nr_requests" 2>/dev/null || true
        echo 4096 > "$device/queue/read_ahead_kb" 2>/dev/null || true
        
        # Otimizações específicas para carga de trabalho de database
        echo deadline > "$device/queue/scheduler" 2>/dev/null || true
        echo 256 > "$device/queue/max_sectors_kb" 2>/dev/null || true
        echo 0 > "$device/queue/add_random" 2>/dev/null || true
        echo 1 > "$device/queue/rq_affinity" 2>/dev/null || true
    fi
done

# Configurar limites de memória para o PostgreSQL
echo "Configurando limites de memória para processos..."
cat > /etc/security/limits.d/99-postgresql.conf << 'EOL'
# Limites para usuário postgres
postgres soft nofile 65536
postgres hard nofile 65536
postgres soft nproc 16384
postgres hard nproc 16384
postgres soft memlock unlimited
postgres hard memlock unlimited

# Limites para outros usuários (opcional)
* soft nofile 65536
* hard nofile 65536
* soft nproc 16384
* hard nproc 16384
EOL

# Verificar e aplicar configurações
echo "Verificando configurações aplicadas..."
sysctl -a | grep -E "shm|dirty|file-max" | head -10

echo "Otimizações para PostgreSQL aplicadas com sucesso!"
echo "Recomendado: Reinicie o sistema para aplicar todas as configurações."



#1. Memória Compartilhada (Shared Memory):
#kernel.shmmax = 17179869184   # 16GB - Para shared_buffers do PostgreSQL
#kernel.shmall = 4194304       # Calculado baseado no shmmax
#kernel.shmmni = 4096          # Número de segmentos de memória

#2. Semáforos:
#kernel.sem = 50100 64128000 50100 1280  # Otimizado para muitas conexões

#3. Configurações de Memória:
#vm.swappiness = 1             # Minimiza swap - CRÍTICO para databases
#vm.overcommit_memory = 2      # Mais seguro para PostgreSQL

#4. Limites de Processos:
# Arquivo /etc/security/limits.d/99-postgresql.conf
#postgres soft nofile 65536    # Mais arquivos abertos para usuário postgres
#postgres hard memlock unlimited  # Permite locking de memória ilimitado

#Benefícios para PostgreSQL:

#Melhor performance de shared_buffers
#Mais conexões simultâneas
#I/O otimizado para carga de trabalho de database
#Menor uso de swap
#Mais arquivos abertos permitidos

#Ajustes Importantes:
#Ajuste estes valores baseado na sua RAM real:

# Para 8GB RAM:
#kernel.shmmax = 8589934592    # 8GB
#kernel.shmall = 2097152       # 8GB em páginas de 4KB

# Para 32GB RAM:
#kernel.shmmax = 34359738368   # 32GB  
#kernel.shmall = 8388608       # 32GB em páginas de 4KB


#Como verificar após aplicar:
# Verificar configurações de memória compartilhada
#ipcs -l

# Verificar limites do usuário postgres
#su - postgres -c 'ulimit -a'

# Verificar configurações aplicadas
#sysctl -a | grep -E "shm|dirty|file-max"

















