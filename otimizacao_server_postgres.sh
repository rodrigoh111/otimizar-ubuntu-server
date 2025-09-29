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

# Shared Memory - ajustar manualmente conforme RAM (veja instruções no final)

# Semáforos - Importante para conexões
kernel.sem = 50100 64128000 50100 1280

# Memória Virtual
vm.swappiness = 1                     # Minimiza swap
vm.overcommit_memory = 0              # Mais seguro (2 pode ser usado só p/ Postgres dedicado)

# Configurações de Dirty Pages - Otimizado para escrita em disco
vm.dirty_background_ratio = 2
vm.dirty_ratio = 3
vm.dirty_background_bytes = 16777216  # 16MB
vm.dirty_bytes = 50331648             # 48MB
vm.dirty_expire_centisecs = 3000      # 30 segundos
vm.dirty_writeback_centisecs = 1500   # 15 segundos

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
fs.file-max = 2097152
fs.aio-max-nr = 1048576
fs.inotify.max_user_watches = 524288

# ============================================================================
# OTIMIZAÇÕES DE I/O
# ============================================================================
vm.vfs_cache_pressure = 50
EOL

# Aplicar configuracoes do sysctl
echo "Aplicando configurações de kernel..."
sysctl -p /etc/sysctl.d/99-optimizations.conf

# Configurações específicas por dispositivo para I/O
echo "Otimizando configurações de I/O por dispositivo..."
for device in /sys/block/sd* /sys/block/nvme* /sys/block/vd*; do
    if [ -d "$device" ]; then
        echo "Otimizando dispositivo: $(basename "$device")"
        echo 128 > "$device/queue/nr_requests" 2>/dev/null || true
        echo 4096 > "$device/queue/read_ahead_kb" 2>/dev/null || true
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
EOL

# Verificar e aplicar configurações
echo "Verificando configurações aplicadas..."
sysctl -a | grep -E "shm|dirty|file-max" | head -10

echo "Otimizações para PostgreSQL aplicadas com sucesso!"
echo "Recomendado: Reinicie o sistema para aplicar todas as configurações."


# ============================================================================
# NOTAS IMPORTANTES (ajuste manual se necessário)
# ============================================================================

# 1. Memória Compartilhada (ajuste conforme RAM real)
# Exemplo para 8GB RAM:
# kernel.shmmax = 8589934592
# kernel.shmall = 2097152
#
# Exemplo para 16GB RAM:
# kernel.shmmax = 17179869184
# kernel.shmall = 4194304
#
# Exemplo para 32GB RAM:
# kernel.shmmax = 34359738368
# kernel.shmall = 8388608
#
# Para aplicar: edite /etc/sysctl.d/99-optimizations.conf e rode `sysctl -p`

# 2. Overcommit
# vm.overcommit_memory = 0   # Padrão seguro (recomendado p/ servidores gerais)
# vm.overcommit_memory = 2   # Melhor p/ servidor dedicado ao PostgreSQL

# 3. Limits para todos usuários (se quiser aplicar globalmente, descomente):
# * soft nofile 65536
# * hard nofile 65536
# * soft nproc 16384
# * hard nproc 16384
EOL
