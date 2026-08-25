#!/usr/bin/env bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

show_menu() {
    clear
    echo -e "${CYAN}=== Network Tools ===${NC}"
    echo "1. Show Active TCP Connections"
    echo "2. Get Public IP"
    echo "3. Ping Test (8.8.8.8)"
    echo "B. Back"
    echo ""
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Fetching Active TCP Connections..." "INFO"
            ss -tulpn | grep LISTEN
            pause_toolkit
            ;;
        2)
            write_log "Fetching Public IP..." "INFO"
            IP=$(curl -s https://api.ipify.org)
            if [ -n "$IP" ]; then
                write_log "Public IP: $IP" "SUCCESS"
            else
                write_log "Failed to fetch Public IP." "ERROR"
            fi
            pause_toolkit
            ;;
        3)
            write_log "Pinging 8.8.8.8..." "INFO"
            if ping -c 4 8.8.8.8; then
                write_log "Ping test passed." "SUCCESS"
            else
                write_log "Ping test failed." "ERROR"
            fi
            pause_toolkit
            ;;
        [bB])
            break
            ;;
        *)
            echo "Invalid option. Please select a valid number."
            sleep 1
            ;;
    esac
done
