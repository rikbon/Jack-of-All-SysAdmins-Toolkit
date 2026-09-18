#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

assert_root

show_menu() {
    clear
    echo -e "${CYAN}=== Firewall Manager ===${NC}"
    echo "1. Show Firewall Status"
    echo "2. Allow a Port (TCP)"
    echo "3. Deny a Port (TCP)"
    echo "B. Back"
    echo ""
}

# Detect firewall backend
if command -v ufw >/dev/null 2>&1; then
    FW="ufw"
elif command -v firewall-cmd >/dev/null 2>&1; then
    FW="firewalld"
else
    FW="none"
fi

while true; do
    show_menu
    
    if [ "$FW" == "none" ]; then
        write_log "No supported firewall (UFW/firewalld) found on this system." "ERROR"
        pause_toolkit
        break
    fi

    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Firewall Status ($FW):" "INFO"
            if [ "$FW" == "ufw" ]; then ufw status verbose; else firewall-cmd --list-all; fi
            pause_toolkit
            ;;
        2)
            read -p "Enter port number to allow (e.g. 80, 443): " port
            if valid_port "$port"; then
                if [ "$FW" == "ufw" ]; then
                    run_logged "Allowing port $port/tcp" ufw allow "$port/tcp"
                else
                    run_logged "Allowing port $port/tcp" bash -c "firewall-cmd --permanent --add-port='$port/tcp' && firewall-cmd --reload"
                fi
            else
                write_log "Invalid port." "ERROR"
            fi
            pause_toolkit
            ;;
        3)
            read -p "Enter port number to deny (e.g. 80, 443): " port
            if valid_port "$port"; then
                if [ "$FW" == "ufw" ]; then
                    run_logged "Denying port $port/tcp" ufw deny "$port/tcp"
                else
                    run_logged "Removing port $port/tcp" bash -c "firewall-cmd --permanent --remove-port='$port/tcp' && firewall-cmd --reload"
                fi
            else
                write_log "Invalid port." "ERROR"
            fi
            pause_toolkit
            ;;
        [bB]) break ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
