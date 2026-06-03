#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

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
        if [ -x "$(command -v systemctl)" ]; then
            systemctl $action "$svc"
            if [ $? -eq 0 ]; then
                write_log "Successfully ran '$action' on service '$svc'." "SUCCESS"
            else
                write_log "Failed to run '$action' on service '$svc'." "ERROR"
            fi
        else
            service "$svc" $action
            if [ $? -eq 0 ]; then
                write_log "Successfully ran '$action' on service '$svc'." "SUCCESS"
            else
                write_log "Failed to run '$action' on service '$svc'." "ERROR"
            fi
        fi
    else
        write_log "No service specified." "WARN"
    fi
    read -p "Press enter to continue..."
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Listing Failed Services:" "INFO"
            if [ -x "$(command -v systemctl)" ]; then
                systemctl --failed
            else
                write_log "systemctl not found. Unable to list failed services easily." "WARN"
            fi
            read -p "Press enter to continue..."
            ;;
        2) manage_service "restart" ;;
        3) manage_service "stop" ;;
        4) manage_service "start" ;;
        [bB]) break ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
