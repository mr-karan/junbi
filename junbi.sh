#!/bin/bash
set -e

# Function to get a file (local or remote)
get_file() {
    local file=$1
    local remote_url="https://raw.githubusercontent.com/mr-karan/junbi/main/$file"
    
    # Create the directory structure in the temp directory
    mkdir -p "$(dirname "$temp_dir/$file")"
    
    # Check if the file exists in the current directory or its subdirectories
    if [ -f "$file" ] || [ -f "$(basename "$file")" ]; then
        echo "Using local file: $file"
        if [ -f "$file" ]; then
            cp "$file" "$temp_dir/$file"
        else
            cp "$(basename "$file")" "$temp_dir/$file"
        fi
    else
        echo "Downloading: $file"
        if ! curl -sSL "$remote_url" -o "$temp_dir/$file"; then
            echo "Failed to get $file"
            return 1
        fi
    fi
}

# Create a temporary directory
temp_dir=$(mktemp -d)
echo "Created temporary directory: $temp_dir"

# List of required scripts
SCRIPTS=(
    "scripts/main.sh"
    "scripts/base.sh"
    "scripts/create_user.sh"
    "scripts/configure_ssh.sh"
    "scripts/install_packages.sh"
    "scripts/install_docker.sh"
    "scripts/configure_sysctl.sh"
    "scripts/setup_security.sh"
    "scripts/cleanup.sh"
)

# Get all required scripts
for script in "${SCRIPTS[@]}"; do
    get_file "$script"
done

# Change to the temporary directory
cd "$temp_dir"

# echo "All scripts downloaded. Contents of temp directory:"
# ls -lR

echo "Running setup..."

# Now source and run the scripts
source scripts/base.sh

print_header "Junbi Server Setup"

SERVER_IP=$(get_input "Enter server IP address")
while ! validate_ip "$SERVER_IP"; do
    log "$RED" "Invalid IP address. Please try again."
    SERVER_IP=$(get_input "Enter server IP address")
done

TIMEZONE=$(get_input "Enter timezone (e.g., Asia/Kolkata)" "UTC")
NEW_USER=$(get_input "Enter username for new user")

SSH_PORT=$(get_input "Enter SSH port" "22")
while ! validate_port "$SSH_PORT"; do
    log "$RED" "Invalid port number. Please enter a number between 1 and 65535."
    SSH_PORT=$(get_input "Enter SSH port" "22")
done

# SSH Key Setup
print_header "SSH Key Setup"
echo "Choose SSH key setup method:"
echo "1) Provide GitHub URL"
echo "2) Enter public key manually"
SSH_KEY_CHOICE=$(get_input "Enter your choice (1-2)")

case $SSH_KEY_CHOICE in
    1)
        GITHUB_URL=$(get_input "Enter GitHub URL for SSH keys")
        ;;
    2)
        echo "Enter your SSH public key (paste and press Enter, then Ctrl+D):"
        SSH_PUBLIC_KEY=$(cat)
        if [ -z "$SSH_PUBLIC_KEY" ]; then
            log "$RED" "No SSH key provided. Exiting."
            exit 1
        fi
        ;;
    *)
        log "$RED" "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Display summary and ask for confirmation
print_header "Summary of Inputs"
echo "Server IP: $SERVER_IP"
echo "Timezone: $TIMEZONE"
echo "New user: $NEW_USER"
echo "SSH port: $SSH_PORT"
echo "SSH Key: ${GITHUB_URL:-"Manually provided"}"
echo

if ! confirm "Does this look correct? Proceed with server setup?"; then
    exit 0
fi

# Copy scripts to the server
scp -r scripts/* root@$SERVER_IP:/root/scripts/

# Execute the main script on the server
ssh -t root@$SERVER_IP "bash /root/scripts/main.sh '$TIMEZONE' '$GITHUB_URL' '$NEW_USER' '$SSH_PORT' '$SSH_PUBLIC_KEY'"

print_header "Setup Complete"
log "$GREEN" "Server setup complete and rebooting."
log "$YELLOW" "Once the server is back online, connect using:"
log "$YELLOW" "ssh -p $SSH_PORT $NEW_USER@$SERVER_IP"

echo -e "${GREEN}Junbi server setup complete. Have a great day!${NC}"

# Clean up
cd ..
rm -rf "$temp_dir"

echo "Setup complete!"