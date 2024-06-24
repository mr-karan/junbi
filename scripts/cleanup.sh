#!/bin/bash

log "$GREEN" "Cleaning up..."
apt-get autoclean -y
apt-get autoremove -y

log "$GREEN" "Junbi setup complete. Remember to update your SSH connection details."