#!/bin/bash

set -eo pipefail

source /root/scripts/base.sh

check_root

# Check if all arguments are provided
if [ $# -lt 4 ]; then
    log "$RED" "Usage: $0 <timezone> <github_url> <new_user> <ssh_port> [ssh_public_key]"
    exit 1
fi

TIMEZONE=$1
GITHUB_URL=$2
NEW_USER=$3
SSH_PORT=$4
SSH_PUBLIC_KEY=${5:-}

log "$GREEN" "Starting Junbi server hardening process..."

source /root/scripts/create_user.sh
source /root/scripts/configure_ssh.sh
source /root/scripts/install_packages.sh
source /root/scripts/install_docker.sh
source /root/scripts/configure_sysctl.sh
source /root/scripts/setup_security.sh
source /root/scripts/cleanup.sh

log "$GREEN" "Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

log "$GREEN" "Junbi server hardening complete. The server will now reboot."
reboot