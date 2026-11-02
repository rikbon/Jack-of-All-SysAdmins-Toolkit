#!/usr/bin/env bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive] [--quiet]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

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
    read -r -p "Select an option: " choice

    case $choice in
        1)
            write_log "Fetching Active TCP Connections..." "INFO"
            # A host with no listening sockets makes grep exit 1; that must not
            # tear down the menu.
            if ! try ss -tulpn | grep LISTEN; then
                write_log "No listening TCP sockets found." "WARN"
            fi
            pause_toolkit
            ;;
        2)
            write_log "Fetching Public IP..." "INFO"
            if ! require_command curl; then
                pause_toolkit
                continue
            fi
            if IP=$(curl --fail --silent --show-error --max-time 5 https://ifconfig.me) && [ -n "$IP" ]; then
                write_log "Public IP: $IP" "SUCCESS"
            else
                write_log "Failed to fetch Public IP." "ERROR"
            fi
            pause_toolkit
            ;;
        3)
            write_log "Pinging 8.8.8.8..." "INFO"
            if ! require_command ping; then
                pause_toolkit
                continue
            fi
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
