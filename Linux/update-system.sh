#!/bin/bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

assert_root

write_log "Starting System Update..." "INFO"

# Detect OS using /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_LIKE=$ID_LIKE
else
    write_log "Cannot detect OS (/etc/os-release not found)." "ERROR"
    exit 1
fi

write_log "Detected OS: $PRETTY_NAME" "INFO"

# Define update logic based on detected OS
if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" || "$OS_LIKE" == *"debian"* || "$OS_LIKE" == *"ubuntu"* ]]; then
    write_log "Debian/Ubuntu system detected. Running apt update & upgrade." "INFO"
    apt-get update -y && apt-get upgrade -y
    if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi

elif [[ "$OS_ID" == "fedora" || "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_LIKE" == *"fedora"* || "$OS_LIKE" == *"rhel"* ]]; then
    if [ -x "$(command -v dnf)" ]; then
        write_log "Fedora/RHEL system detected. Running dnf upgrade." "INFO"
        dnf upgrade -y
        if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi
    elif [ -x "$(command -v yum)" ]; then
        write_log "CentOS/RHEL system detected. Running yum update." "INFO"
        yum update -y
        if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi
    fi

elif [[ "$OS_ID" == "arch" || "$OS_LIKE" == *"arch"* ]]; then
    write_log "Arch system detected. Running pacman update." "INFO"
    pacman -Syu --noconfirm
    if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi

elif [[ "$OS_ID" == "alpine" ]]; then
    write_log "Alpine system detected. Running apk upgrade." "INFO"
    apk update && apk upgrade
    if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi

elif [[ "$OS_ID" == "opensuse"* || "$OS_LIKE" == *"suse"* ]]; then
    write_log "openSUSE system detected. Running zypper update." "INFO"
    zypper refresh && zypper update -y
    if [ $? -eq 0 ]; then write_log "System updated successfully." "SUCCESS"; else write_log "Update failed." "ERROR"; fi

else
    write_log "Unsupported package manager or OS ($PRETTY_NAME). Please update manually." "WARN"
fi

write_log "System Update Script Finished." "INFO"
