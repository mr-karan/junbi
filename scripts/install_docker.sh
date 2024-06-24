#!/bin/bash

log "$GREEN" "Checking Docker installation..."
if command -v docker &> /dev/null; then
    log "$YELLOW" "Docker is already installed. Current version: $(docker --version)"
    gum confirm "Do you want to reinstall Docker?" && {
        apt-get remove -y docker docker-engine docker.io containerd runc
        curl -fsSL https://get.docker.com | sh
    }
else
    log "$GREEN" "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
fi

log "$GREEN" "Adding $NEW_USER to the docker group..."
usermod -aG docker "$NEW_USER"

log "$GREEN" "Installing Docker Compose..."
if command -v docker-compose &> /dev/null; then
    log "$YELLOW" "Docker Compose is already installed. Current version: $(docker-compose --version)"
else
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi