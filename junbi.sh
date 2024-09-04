#!/bin/bash
set -e

# Function to download a file
download_file() {
    local file=$1
    local url="https://raw.githubusercontent.com/mr-karan/junbi/main/$file"
    echo "Downloading $file from $url"
    mkdir -p "$(dirname "$file")"
    if ! curl -SL "$url" -o "$file"; then
        echo "Failed to download $file"
        return 1
    fi
    echo "Successfully downloaded $file"
}

# Create a temporary directory
temp_dir=$(mktemp -d) || { echo "Failed to create temp directory"; exit 1; }
echo "Created temporary directory: $temp_dir"
cd "$temp_dir" || { echo "Failed to change to temp directory"; exit 1; }

echo "Downloading required scripts..."

# Download all required scripts
download_file "scripts/base.sh"
download_file "scripts/user.sh"
download_file "scripts/ssh.sh"
download_file "scripts/packages.sh"
download_file "scripts/docker.sh"
download_file "scripts/sysctl.sh"
download_file "scripts/cleanup.sh"

echo "All scripts downloaded. Contents of temp directory:"
ls -lR

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
scp -r scripts root@$SERVER_IP:/root/

# Execute the hardening script on the server
ssh -t root@$SERVER_IP "bash /root/scripts/main.sh '$TIMEZONE' '$GITHUB_URL' '$NEW_USER' '$SSH_PORT' '$SSH_PUBLIC_KEY'"

print_header "Setup Complete"
log "$GREEN" "Server setup complete and rebooting."
log "$YELLOW" "Once the server is back online, connect using:"
log "$YELLOW" "ssh -p $SSH_PORT $NEW_USER@$SERVER_IP"

echo -e "${GREEN}Junbi server setup complete. Have a great day!${NC}"

# Clean up
cd .. || true
rm -rf "$temp_dir"

echo "Setup complete!"