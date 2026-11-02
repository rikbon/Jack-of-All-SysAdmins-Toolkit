#!/usr/bin/env bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [--update] [--quiet]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "--update" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

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
    run_logged "Updating Debian/Ubuntu packages" bash -c 'apt-get update -y && apt-get upgrade -y'

elif [[ "$OS_ID" == "fedora" || "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_LIKE" == *"fedora"* || "$OS_LIKE" == *"rhel"* ]]; then
    if [ -x "$(command -v dnf)" ]; then
        run_logged "Updating Fedora/RHEL packages" dnf upgrade -y
    elif [ -x "$(command -v yum)" ]; then
        run_logged "Updating CentOS/RHEL packages" yum update -y
    fi

elif [[ "$OS_ID" == "arch" || "$OS_LIKE" == *"arch"* ]]; then
    run_logged "Updating Arch packages" pacman -Syu --noconfirm

elif [[ "$OS_ID" == "alpine" ]]; then
    run_logged "Updating Alpine packages" bash -c 'apk update && apk upgrade'

elif [[ "$OS_ID" == "opensuse"* || "$OS_LIKE" == *"suse"* ]]; then
    run_logged "Updating openSUSE packages" bash -c 'zypper refresh && zypper update -y'

else
    write_log "Unsupported package manager or OS ($PRETTY_NAME). Please update manually." "WARN"
fi

write_log "System Update Script Finished." "INFO"
