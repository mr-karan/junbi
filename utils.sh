#!/bin/bash

# Junbi Utils - Centralized functions for server setup
# All common functions used across the setup process

# ============================================================================
# STYLING & OUTPUT FUNCTIONS
# ============================================================================

# Elegant banner - clean and modern
show_banner() {
    clear
    gum style --border double --align center --padding "2 4" \
        '🔧  J U N B I  🛡️' \
        '' \
        'Interactive Server Setup' \
        '' \
        '準備 - Ready to secure your server'
    
    echo
}

# Smart message wrapper
msg() {
    local type=$1
    local text=$2
    
    case $type in
        "success")
            gum style --foreground 2 "✅ $text"
            ;;
        "error") 
            gum style --foreground 1 "❌ $text"
            ;;
        "warning")
            gum style --foreground 3 "⚠️  $text"
            ;;
        "info")
            gum style --foreground 4 "ℹ️  $text"
            ;;
        "progress")
            gum style --foreground 5 "⏳ $text"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

# Legacy log function for compatibility
log() {
    local style=$1
    local text=$2
    local timestamp=$(date +"%H:%M:%S")
    msg "$style" "[$timestamp] $text"
}

# Section headers
print_header() {
    local msg=$1
    echo
    gum style --border normal --padding "0 2" "$msg"
    echo
}

# Brief step confirmation
step_done() {
    local message=$1
    msg "success" "$message"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_ip() {
    local ip=$1
    [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

validate_port() {
    local port=$1
    [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]
}

validate_username() {
    local username=$1
    [[ "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

validate_ssh_key() {
    local key=$1
    [[ "$key" =~ ^ssh-(rsa|ed25519|ecdsa) ]]
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "error" "This script must be run as root"
        exit 1
    fi
}

# ============================================================================
# INPUT FUNCTIONS
# ============================================================================

get_input() {
    local prompt=$1
    local default=$2
    local validation_func=$3
    local error_msg=$4
    local result
    
    while true; do
        if [ -n "$default" ]; then
            result=$(gum input --placeholder "$prompt" --value "$default") || exit 130
        else
            result=$(gum input --placeholder "$prompt") || exit 130
        fi
        
        # Empty check
        if [ -z "$result" ] && [ -z "$default" ]; then
            log "error" "This field cannot be empty"
            continue
        fi
        
        # Validation check if function provided
        if [ -n "$validation_func" ]; then
            if ! $validation_func "$result"; then
                log "error" "${error_msg:-Invalid input}"
                continue
            fi
        fi
        
        echo "$result"
        break
    done
}

confirm() {
    local prompt=$1
    gum confirm "$prompt"
}

# ============================================================================
# SYSTEM FUNCTIONS
# ============================================================================

run_with_spinner() {
    local title=$1
    shift
    gum spin --title "$title" -- "$@"
}

install_gum() {
    if ! command -v gum &> /dev/null; then
        echo "📦 Installing gum for better interactivity..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gum
        else
            export DEBIAN_FRONTEND=noninteractive
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt-get update -qq && sudo apt-get install -y -qq gum
        fi
    fi
}

# ============================================================================
# SSH FUNCTIONS
# ============================================================================

test_ssh_connectivity() {
    local server_ip=$1
    local server_port=${2:-22}
    
    nc -vz -w 3 "$server_ip" "$server_port" &>/dev/null
}

setup_ssh_key() {
    local user=$1
    local key_content=$2
    
    local ssh_dir="/home/$user/.ssh"
    mkdir -p "$ssh_dir"
    echo "$key_content" > "$ssh_dir/authorized_keys"
    chown -R "$user:$user" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "$ssh_dir/authorized_keys"
}

configure_sshd() {
    local port=$1
    local user=$2
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
    
    # Apply secure SSH configuration
    cat > /etc/ssh/sshd_config.d/99-junbi.conf << EOF
# Junbi SSH Configuration
Port $port
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
AllowUsers $user
ClientAliveInterval 120
ClientAliveCountMax 3
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 60
StrictModes yes
PubkeyAuthentication yes
IgnoreRhosts yes
HostbasedAuthentication no
PermitEmptyPasswords no
EOF
    
    # Restart SSH service
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
    elif systemctl is-active --quiet sshd; then
        systemctl restart sshd
    fi
}

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================

update_system() {
    export DEBIAN_FRONTEND=noninteractive
    run_with_spinner "Updating package lists..." apt-get update -qq
    run_with_spinner "Upgrading existing packages..." \
        apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

install_packages() {
    local packages=("$@")
    export DEBIAN_FRONTEND=noninteractive
    run_with_spinner "Installing packages..." apt-get install -y -qq "${packages[@]}"
}

# ============================================================================
# USER MANAGEMENT
# ============================================================================

create_user() {
    local username=$1
    
    # Create user
    adduser --gecos '' --disabled-password "$username"
    
    # Add to sudo group
    usermod -aG sudo "$username"
    
    # Configure passwordless sudo
    echo "$username ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/$username" > /dev/null
    chmod 0440 "/etc/sudoers.d/$username"
}

# ============================================================================
# FIREWALL FUNCTIONS
# ============================================================================

setup_firewall() {
    local ssh_port=$1
    
    export DEBIAN_FRONTEND=noninteractive
    run_with_spinner "Installing UFW..." apt-get install -y -qq ufw
    
    # Configure UFW
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow "$ssh_port/tcp" comment 'SSH'
    
    # Enable UFW (non-interactive)
    echo "y" | ufw enable
}

# ============================================================================
# DOCKER FUNCTIONS
# ============================================================================

install_docker() {
    export DEBIAN_FRONTEND=noninteractive
    # Add Docker's official GPG key
    run_with_spinner "Setting up Docker repository..." bash -c '
        apt-get update -qq
        apt-get install -y -qq ca-certificates curl gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    '
    
    # Install Docker packages
    run_with_spinner "Installing Docker..." bash -c '
        apt-get update -qq
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    '
}

# ============================================================================
# SYSTEM OPTIMIZATION
# ============================================================================

optimize_sysctl() {
    cat > /etc/sysctl.d/99-junbi.conf << 'EOF'
# Junbi System Optimization

# Network Performance
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Security
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# File System
fs.file-max = 2097152
fs.suid_dumpable = 0

# Process
kernel.pid_max = 4194304
EOF
    
    sysctl -p /etc/sysctl.d/99-junbi.conf
}

# ============================================================================
# COMPLETION FUNCTIONS
# ============================================================================

show_completion() {
    local server_ip=$1
    local ssh_port=$2
    local username=$3
    
    echo
    gum style --border double --padding "1 2" \
        "✨ Setup Complete!" \
        "" \
        "Connect to your server:" \
        "ssh -p $ssh_port $username@$server_ip" \
        "" \
        "Your server has been secured with:" \
        "• SSH key-only authentication" \
        "• Firewall configured" \
        "• Automatic security updates" \
        "• System optimizations applied"
    
    # Celebration animation
    for emoji in "🎉" "🎊" "✨" "🌟" "⭐" "🎈"; do
        echo -n "$emoji "
        sleep 0.1
    done
    echo
}

# Export all functions
export -f show_banner msg log print_header step_done validate_ip validate_port validate_username
export -f validate_ssh_key check_root get_input confirm run_with_spinner install_gum
export -f test_ssh_connectivity setup_ssh_key configure_sshd update_system install_packages create_user
export -f setup_firewall install_docker optimize_sysctl show_completion