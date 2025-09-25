#!/bin/bash
set -e

# Junbi - Interactive Server Setup & Hardening Tool
# A single script to configure Ubuntu servers with common sense defaults

# Download utils if not available locally
get_utils() {
    if [ ! -f "utils.sh" ]; then
        echo "📥 Downloading utils..."
        curl -sSL "https://raw.githubusercontent.com/mr-karan/junbi/main/utils.sh" -o utils.sh
        chmod +x utils.sh
    fi
    source ./utils.sh
}

# Main configuration wizard
run_wizard() {
    show_banner
    
    echo "🌐 Server IP:"
    SERVER_IP=$(get_input "Enter server IP" "" validate_ip "Invalid IP format")
    
    # Test connectivity with proper choice
    if ! test_ssh_connectivity "$SERVER_IP" 22; then
        echo "⚠️  Cannot connect to $SERVER_IP on port 22"
        if ! confirm "Continue anyway?"; then
            exit 1
        fi
    fi
    
    echo
    echo "⚙️ Configuration"
    
    # Timezone selection with filtering
    TIMEZONE=$(gum filter --placeholder "Select timezone (type to filter)..." \
        "UTC" \
        "America/New_York" \
        "America/Chicago" \
        "America/Los_Angeles" \
        "Europe/London" \
        "Europe/Paris" \
        "Europe/Berlin" \
        "Asia/Tokyo" \
        "Asia/Kolkata" \
        "Asia/Shanghai" \
        "Australia/Sydney" \
        "Custom...")
    
    if [ "$TIMEZONE" = "Custom..." ]; then
        TIMEZONE=$(get_input "Enter timezone (e.g., Asia/Kolkata)" "UTC")
    fi
    
    NEW_USER=$(get_input "Username for sudo user" "" validate_username "Invalid username")
    
    echo
    echo "🔐 Security"
    
    # SSH Port with choices
    SSH_PORT=$(gum choose "2222 (recommended)" "22 (standard)" "8022 (high port)" "Custom...")
    case "$SSH_PORT" in
        "2222"*) SSH_PORT=2222 ;;
        "22"*) SSH_PORT=22; msg "warning" "Port 22 is less secure" ;;
        "8022"*) SSH_PORT=8022 ;;
        *) SSH_PORT=$(get_input "Enter SSH port (1-65535)" "2222" validate_port "Invalid port") ;;
    esac
    
    # SSH Key setup
    SSH_KEY_METHOD=$(gum choose "GitHub username" "Local SSH key" "Paste key manually")
    
    # SSH Key setup with retry logic
    while true; do
        case "$SSH_KEY_METHOD" in
            "GitHub"*)
                GITHUB_USER=$(get_input "GitHub username" "")
                GITHUB_URL="https://github.com/${GITHUB_USER}.keys"
                
                if curl -fsSL "$GITHUB_URL" | head -1 | grep -q "ssh-"; then
                    msg "success" "Found SSH keys for $GITHUB_USER"
                    break
                else
                    msg "error" "No SSH keys found for GitHub user: $GITHUB_USER"
                    echo
                    retry_action=$(gum choose "Try different GitHub username" "Switch to local key" "Paste key manually" "Exit")
                    case "$retry_action" in
                        "Try"*) continue ;;
                        "Switch"*) SSH_KEY_METHOD="Local SSH key" ;;
                        "Paste"*) SSH_KEY_METHOD="Paste key manually" ;;
                        "Exit") exit 1 ;;
                    esac
                fi
                ;;
            "Local"*)
                if [ -f ~/.ssh/id_ed25519.pub ]; then
                    SSH_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)
                    msg "success" "Using ~/.ssh/id_ed25519.pub"
                    break
                elif [ -f ~/.ssh/id_rsa.pub ]; then
                    SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
                    msg "success" "Using ~/.ssh/id_rsa.pub"
                    break
                else
                    echo "No SSH keys found in ~/.ssh/"
                    retry_action=$(gum choose "Browse for key file" "Try GitHub username" "Paste key manually" "Exit")
                    case "$retry_action" in
                        "Browse"*)
                            SSH_KEY_FILE=$(gum file ~/.ssh/ --file)
                            if [ -f "$SSH_KEY_FILE" ] && [ -r "$SSH_KEY_FILE" ]; then
                                SSH_PUBLIC_KEY=$(cat "$SSH_KEY_FILE")
                                msg "success" "Loaded key from $SSH_KEY_FILE"
                                break
                            else
                                msg "error" "Cannot read selected file"
                                continue
                            fi
                            ;;
                        "Try"*) SSH_KEY_METHOD="GitHub username" ;;
                        "Paste"*) SSH_KEY_METHOD="Paste key manually" ;;
                        "Exit") exit 1 ;;
                    esac
                fi
                ;;
            "Paste"*)
                SSH_PUBLIC_KEY=$(gum input --placeholder "Paste your SSH public key here...")
                if validate_ssh_key "$SSH_PUBLIC_KEY"; then
                    msg "success" "SSH key validated"
                    break
                else
                    msg "error" "Invalid SSH key format"
                    retry_action=$(gum choose "Try again" "Try GitHub username" "Try local key" "Exit")
                    case "$retry_action" in
                        "Try again") continue ;;
                        "Try GitHub"*) SSH_KEY_METHOD="GitHub username" ;;
                        "Try local"*) SSH_KEY_METHOD="Local SSH key" ;;
                        "Exit") exit 1 ;;
                    esac
                fi
                ;;
        esac
    done
    
    echo
    echo "📦 Components"
    echo "Use SPACE to select/deselect, ENTER to confirm"
    echo "Pre-selected: Docker, Firewall, Auto-updates, System optimization"
    echo
    
    FEATURES=$(gum choose --no-limit \
        --selected="Docker & Docker Compose" \
        --selected="Firewall (UFW)" \
        --selected="Auto-updates" \
        --selected="System optimization" \
        "Docker & Docker Compose" \
        "Firewall (UFW)" \
        "Fail2ban protection" \
        "Monitoring tools (htop, btop, ncdu, glances)" \
        "Zsh + Oh My Zsh" \
        "Development tools (git, build-essential, vim)" \
        "Auto-updates" \
        "System optimization")
    
    # Show selected components for confirmation
    echo
    if [ -n "$FEATURES" ]; then
        echo "Selected components:"
        echo "$FEATURES" | sed 's/^/  ✓ /'
        echo
        component_confirm=$(gum choose "✅ Confirm selection" "🔄 Change components")
        if [ "$component_confirm" = "🔄 Change components" ]; then
            # Go back to component selection
            # Build the selected args properly
            selected_args=""
            while IFS= read -r line; do
                [ -n "$line" ] && selected_args="$selected_args --selected=\"$line\""
            done <<< "$FEATURES"
            
            eval "FEATURES=\$(gum choose --no-limit $selected_args \
                \"Docker & Docker Compose\" \
                \"Firewall (UFW)\" \
                \"Fail2ban protection\" \
                \"Monitoring tools (htop, btop, ncdu, glances)\" \
                \"Zsh + Oh My Zsh\" \
                \"Development tools (git, build-essential, vim)\" \
                \"Auto-updates\" \
                \"System optimization\")"
            echo
            echo "Updated selection:"
            echo "$FEATURES" | sed 's/^/  ✓ /'
        fi
    else
        echo "⚠️  No components selected - server will only have basic setup"
        if ! confirm "Continue with minimal setup?"; then
            exit 0
        fi
    fi
    
    echo
    echo "📋 Summary"
    echo "Server: $SERVER_IP"
    echo "User: $NEW_USER"
    echo "Timezone: $TIMEZONE"
    echo "SSH Port: $SSH_PORT"
    # Determine SSH key source for display
    if [ -n "$GITHUB_USER" ]; then
        echo "SSH Key: GitHub/$GITHUB_USER"
    elif [ -n "$SSH_KEY_FILE" ]; then
        echo "SSH Key: $SSH_KEY_FILE"
    elif [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "SSH Key: Manual/Pasted"
    else
        echo "SSH Key: None configured"
    fi
    echo "Components: $(echo "$FEATURES" | wc -l) selected"
    
    final_action=$(gum choose "✅ Proceed with setup" "🔄 Start over" "❌ Cancel")
    case "$final_action" in
        "✅"*) 
            # Continue with setup
            ;;
        "🔄"*)
            echo "Restarting wizard..."
            exec "$0" "$@"
            ;;
        "❌"*)
            echo "Setup cancelled"
            exit 0
            ;;
    esac
}

# Execute setup on remote server
run_setup() {
    local temp_dir=$(mktemp -d)
    
    # Copy utils to temp directory
    cp utils.sh "$temp_dir/"
    
    # Create setup script for remote execution
    cat > "$temp_dir/remote_setup.sh" << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

# Change to the temporary directory where scripts are uploaded
cd /tmp/junbi_setup

# Source utils from current directory
source ./utils.sh

# Install gum on remote server
install_gum

log "progress" "Starting Junbi setup..."
show_banner

# Set timezone
log "progress" "Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

# Update system
log "progress" "Updating system packages..."
update_system

# Create user
log "progress" "Creating user: $NEW_USER"
create_user "$NEW_USER"

# Setup SSH key
log "progress" "Configuring SSH access..."
if [ -n "$GITHUB_URL" ]; then
    SSH_KEYS=$(curl -fsSL "$GITHUB_URL")
    setup_ssh_key "$NEW_USER" "$SSH_KEYS"
elif [ -n "$SSH_PUBLIC_KEY" ]; then
    setup_ssh_key "$NEW_USER" "$SSH_PUBLIC_KEY"
fi

# Configure SSH daemon
configure_sshd "$SSH_PORT" "$NEW_USER"

# Install selected components
if echo "$FEATURES" | grep -q "Docker"; then
    log "progress" "Installing Docker..."
    install_docker
    usermod -aG docker "$NEW_USER"
fi

if echo "$FEATURES" | grep -q "Firewall"; then
    log "progress" "Configuring firewall..."
    setup_firewall "$SSH_PORT"
fi

if echo "$FEATURES" | grep -q "Fail2ban"; then
    log "progress" "Installing fail2ban..."
    install_packages fail2ban
    systemctl enable --now fail2ban
fi

if echo "$FEATURES" | grep -q "Monitoring"; then
    log "progress" "Installing monitoring tools..."
    install_packages htop btop iotop ncdu duf glances
fi

if echo "$FEATURES" | grep -q "Development"; then
    log "progress" "Installing development tools..."
    install_packages git build-essential vim curl wget
fi

if echo "$FEATURES" | grep -q "Zsh"; then
    log "progress" "Setting up Zsh..."
    install_packages zsh
    su - "$NEW_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    chsh -s $(which zsh) "$NEW_USER"
fi

if echo "$FEATURES" | grep -q "Auto-updates"; then
    log "progress" "Configuring automatic updates..."
    install_packages unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades
fi

if echo "$FEATURES" | grep -q "optimization"; then
    log "progress" "Applying system optimizations..."
    optimize_sysctl
fi

# Final cleanup and completion
log "success" "Server setup completed successfully!"
show_completion "$SERVER_IP" "$SSH_PORT" "$NEW_USER"

# Cleanup temporary files
log "progress" "Cleaning up temporary files..."
cd /
rm -rf /tmp/junbi_setup

# Schedule reboot
log "warning" "Server will reboot in 10 seconds..."
sleep 10
reboot
REMOTE_SCRIPT

    # Transfer and execute with proper error handling
    log "progress" "Uploading setup scripts to server..."
    
    # Test connection first with timeout
    if ! test_ssh_connectivity "$SERVER_IP" 22; then
        echo
        msg "error" "Cannot connect to $SERVER_IP on port 22"
        echo "Possible reasons:"
        echo "  • Server is not reachable"
        echo "  • SSH is not running on the server"
        echo "  • Root access is not configured"
        echo "  • Firewall is blocking connection"
        echo
        
        connection_action=$(gum choose "🔄 Retry connection" "📝 Change server IP" "🔄 Start over" "❌ Exit")
        case "$connection_action" in
            "🔄 Retry"*)
                log "progress" "Retrying connection..."
                run_setup
                return
                ;;
            "📝 Change"*)
                echo "New server IP:"
                SERVER_IP=$(get_input "Enter server IP" "" validate_ip "Invalid IP format")
                run_setup
                return
                ;;
            "🔄 Start"*)
                echo "Restarting wizard..."
                exec "$0" "$@"
                ;;
            "❌"*)
                echo "Setup aborted"
                exit 1
                ;;
        esac
    fi
    
    # Create remote temporary directory
    if ! ssh -o ConnectTimeout=5 root@"$SERVER_IP" "mkdir -p /tmp/junbi_setup" 2>/dev/null; then
        msg "error" "Failed to create remote directories"
        if confirm "Retry?"; then
            run_setup
            return
        else
            exit 1
        fi
    fi
    
    # Transfer files to temporary directory
    if ! scp -o ConnectTimeout=5 "$temp_dir"/* root@"$SERVER_IP":/tmp/junbi_setup/ 2>/dev/null; then
        msg "error" "Failed to transfer setup files"
        if confirm "Retry?"; then
            run_setup
            return
        else
            exit 1
        fi
    fi
    
    # Make scripts executable and run setup
    ssh root@"$SERVER_IP" "cd /tmp/junbi_setup && chmod +x *.sh"
    
    # Export variables for remote script and execute
    ssh -t root@"$SERVER_IP" \
        "export TERM='xterm-256color' && \
         export DEBIAN_FRONTEND='noninteractive' && \
         export SERVER_IP='$SERVER_IP' && \
         export TIMEZONE='$TIMEZONE' && \
         export NEW_USER='$NEW_USER' && \
         export SSH_PORT='$SSH_PORT' && \
         export GITHUB_URL='$GITHUB_URL' && \
         export SSH_PUBLIC_KEY='$SSH_PUBLIC_KEY' && \
         export FEATURES='$FEATURES' && \
         cd /tmp/junbi_setup && ./remote_setup.sh"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main execution
main() {
    # Check for gum locally
    install_gum
    
    # Run the configuration wizard
    run_wizard
    
    # Execute setup
    echo
    log "progress" "Starting server configuration..."
    run_setup
    
    # Final message
    echo
    echo "🎉 Junbi setup complete!"
    echo
    echo "Your server is now secure and ready to use."
    log "info" "Connect with: ssh -p $SSH_PORT $NEW_USER@$SERVER_IP"
    
    # Celebration
    for emoji in "🎉" "✨" "🚀" "🎯" "⭐"; do
        echo -n "$emoji "
        sleep 0.1
    done
    echo
}

# Initialize
get_utils
main "$@"