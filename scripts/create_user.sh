#!/bin/bash

log "$GREEN" "Creating new user $NEW_USER..."
adduser --gecos '' --disabled-password "$NEW_USER"
usermod -aG sudo "$NEW_USER"

# Allow sudo without password
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$NEW_USER"
chmod 0440 "/etc/sudoers.d/$NEW_USER"

setup_ssh_key() {
    local key_content=$1
    
    mkdir -p "/home/$NEW_USER/.ssh"
    echo "$key_content" > "/home/$NEW_USER/.ssh/authorized_keys"
    chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
    chmod 700 "/home/$NEW_USER/.ssh"
    chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"
    
    log "$GREEN" "SSH key set up for $NEW_USER."
}

if [ -n "$GITHUB_URL" ]; then
    setup_ssh_key "$(curl -sL "$GITHUB_URL")"
elif [ -n "$SSH_PUBLIC_KEY" ]; then
    setup_ssh_key "$SSH_PUBLIC_KEY"
else
    log "$RED" "No SSH key provided. This should not happen. Exiting."
    exit 1
fi

log "$GREEN" "User $NEW_USER created and configured for passwordless sudo access."
