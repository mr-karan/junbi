#!/bin/bash

log "$GREEN" "Configuring SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

configure_ssh() {
    local setting=$1
    local value=$2
    sed -i "s/^#?${setting} .*/${setting} ${value}/" /etc/ssh/sshd_config
}

configure_ssh "Port" "$SSH_PORT"
configure_ssh "PermitRootLogin" "no"
configure_ssh "StrictModes" "yes"
configure_ssh "X11Forwarding" "no"
configure_ssh "PasswordAuthentication" "no"
configure_ssh "ChallengeResponseAuthentication" "no"
configure_ssh "PermitEmptyPasswords" "no"
configure_ssh "AllowUsers" "$NEW_USER"

if systemctl is-active --quiet ssh; then
    systemctl restart ssh
elif systemctl is-active --quiet sshd; then
    systemctl restart sshd
else
    log "$RED" "Unable to determine SSH service name. Please restart SSH service manually."
fi