#!/bin/bash

log "$GREEN" "Configuring sysctl parameters for optimal performance and security..."
cat << EOF > /etc/sysctl.d/99-sysctl-performance-security.conf
# Increase system file descriptor limit
fs.file-max = 2097152

# Increase max number of open files
fs.nr_open = 1048576

# Increase network performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 262144

# Increase the maximum amount of memory allocated to shm
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Increase the maximum number of process identifiers
kernel.pid_max = 4194304

# Increase the ephemeral IP ports range
net.ipv4.ip_local_port_range = 1024 65535

# Enable IP spoofing protection, turn on source route verification
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ICMP Redirect Acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Enable IP routing if needed (useful for Docker)
net.ipv4.ip_forward = 1

# Enable TCP Fast Open
net.ipv4.tcp_fastopen = 3

# Increase kernel memory allocation for network operations
net.core.optmem_max = 65535
net.core.rmem_default = 31457280
net.core.rmem_max = 16777216
net.core.wmem_default = 31457280
net.core.wmem_max = 16777216

# Increase the maximum number of pending connections
net.ipv4.tcp_max_syn_backlog = 65536

# Increase the maximum number of remembered connection requests
net.ipv4.tcp_max_tw_buckets = 1440000

# Increase the maximum receive buffer for all types of connections
net.core.rmem_max = 16777216

# Increase the maximum send buffer for all types of connections
net.core.wmem_max = 16777216

# Increase Linux autotuning TCP buffer limits
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Enable TCP timestamps
net.ipv4.tcp_timestamps = 1

# Enable TCP selective acknowledgments
net.ipv4.tcp_sack = 1

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000

# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 15

# Decrease the time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Virtual Memory settings
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# Increase Inotify watches
fs.inotify.max_user_watches = 524288
EOF

sysctl -p /etc/sysctl.d/99-sysctl-performance-security.conf