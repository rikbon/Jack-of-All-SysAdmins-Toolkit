#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

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
if [ -x "$(command -v ufw)" ]; then
    FW="ufw"
elif [ -x "$(command -v firewall-cmd)" ]; then
    FW="firewalld"
else
    FW="none"
fi

while true; do
    show_menu
    
    if [ "$FW" == "none" ]; then
        write_log "No supported firewall (UFW/firewalld) found on this system." "ERROR"
        read -p "Press enter to go back..."
        break
    fi

    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Firewall Status ($FW):" "INFO"
            if [ "$FW" == "ufw" ]; then ufw status verbose; else firewall-cmd --list-all; fi
            read -p "Press enter to continue..."
            ;;
        2)
            read -p "Enter port number to allow (e.g. 80, 443): " port
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                if [ "$FW" == "ufw" ]; then
                    ufw allow "$port/tcp"
                else
                    firewall-cmd --permanent --add-port="$port/tcp"
                    firewall-cmd --reload
                fi
                write_log "Port $port/tcp opened." "SUCCESS"
            else
                write_log "Invalid port." "ERROR"
            fi
            read -p "Press enter to continue..."
            ;;
        3)
            read -p "Enter port number to deny (e.g. 80, 443): " port
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                if [ "$FW" == "ufw" ]; then
                    ufw deny "$port/tcp"
                else
                    firewall-cmd --permanent --remove-port="$port/tcp"
                    firewall-cmd --reload
                fi
                write_log "Port $port/tcp denied/removed." "SUCCESS"
            else
                write_log "Invalid port." "ERROR"
            fi
            read -p "Press enter to continue..."
            ;;
        [bB]) break ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
