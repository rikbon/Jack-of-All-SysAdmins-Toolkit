#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

assert_root

show_menu() {
    clear
    echo -e "${CYAN}=== Service Management ===${NC}"
    echo "1. List Failed Services"
    echo "2. Restart a Service"
    echo "3. Stop a Service"
    echo "4. Start a Service"
    echo "B. Back"
    echo ""
}

manage_service() {
    local action=$1
    read -p "Enter service name (e.g. sshd, nginx): " svc
    if [ -n "$svc" ]; then
        if command -v systemctl >/dev/null 2>&1; then
            run_logged "Running '$action' on service '$svc'" systemctl "$action" "$svc"
        elif command -v service >/dev/null 2>&1; then
            run_logged "Running '$action' on service '$svc'" service "$svc" "$action"
        else
            write_log "Neither systemctl nor service is available." "ERROR"
        fi
    else
        write_log "No service specified." "WARN"
    fi
    pause_toolkit
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Listing Failed Services:" "INFO"
            if command -v systemctl >/dev/null 2>&1; then
                systemctl --failed
            else
                write_log "systemctl not found. Unable to list failed services easily." "WARN"
            fi
            pause_toolkit
            ;;
        2) manage_service "restart" ;;
        3) manage_service "stop" ;;
        4) manage_service "start" ;;
        [bB]) break ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
