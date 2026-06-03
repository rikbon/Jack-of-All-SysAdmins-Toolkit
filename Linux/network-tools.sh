#!/bin/bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

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
            read -p "Press enter to continue..."
            ;;
        2)
            write_log "Fetching Public IP..." "INFO"
            IP=$(curl -s https://api.ipify.org)
            if [ -n "$IP" ]; then
                write_log "Public IP: $IP" "SUCCESS"
            else
                write_log "Failed to fetch Public IP." "ERROR"
            fi
            read -p "Press enter to continue..."
            ;;
        3)
            write_log "Pinging 8.8.8.8..." "INFO"
            ping -c 4 8.8.8.8
            if [ $? -eq 0 ]; then
                write_log "Ping test passed." "SUCCESS"
            else
                write_log "Ping test failed." "ERROR"
            fi
            read -p "Press enter to continue..."
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
