#!/bin/bash

log "$GREEN" "Installing common packages..."

# Define the list of packages to install
PACKAGES=(
    apt-transport-https
    vim
    curl
    jq
    fzf
    python3-pip
    python3-apt
    gnupg2
    gnupg-agent
    ncdu
    unattended-upgrades
    zsh
)

apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y "${PACKAGES[@]}"

log "$GREEN" "Installing Zsh and Oh My Zsh..."
su - "$NEW_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
chsh -s $(which zsh) "$NEW_USER"