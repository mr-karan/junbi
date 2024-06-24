#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print logs with timestamp and color
log() {
    local color=$1
    local msg=$2
    printf "%b[%s]%b %s\n" "$color" "$(date -u +"%Y-%m-%d %H:%M:%S UTC")" "$NC" "$msg"
}

# Function to print section headers
print_header() {
    local msg=$1
    echo
    echo -e "${BLUE}==== $msg ====${NC}"
    echo
}

# Function to get user input
get_input() {
    local prompt=$1
    local default=$2
    local result

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        result=${result:-$default}
    else
        read -p "$prompt: " result
    fi

    while [ -z "$result" ]; do
        read -p "This field cannot be empty. $prompt: " result
    done

    echo "$result"
}

# Function to get confirmation
confirm() {
    local prompt=$1
    local response

    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
       log "$RED" "This script must be run as root"
       exit 1
    fi
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Set environment variable for non-interactive frontend
export DEBIAN_FRONTEND=noninteractive
