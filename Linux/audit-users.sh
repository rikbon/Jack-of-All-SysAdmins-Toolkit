#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

assert_root

show_menu() {
    clear
    echo -e "${CYAN}=== Security & File Utilities ===${NC}"
    echo "1. List Users with Sudo/Root access"
    echo "2. Check for accounts with empty passwords"
    echo "3. Show last 10 successful logins"
    echo "B. Back"
    echo ""
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Users with Sudo/Root privileges:" "INFO"
            # Check wheel or sudo group
            grep -E '^sudo|^wheel|^root' /etc/group
            read -p "Press enter to continue..."
            ;;
        2)
            write_log "Accounts with empty passwords:" "INFO"
            empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow)
            if [ -z "$empty_pass" ]; then
                write_log "No empty passwords found. System is secure." "SUCCESS"
            else
                write_log "WARNING: Empty passwords found for: $empty_pass" "WARN"
            fi
            read -p "Press enter to continue..."
            ;;
        3)
            write_log "Last 10 Logins:" "INFO"
            last -n 10
            read -p "Press enter to continue..."
            ;;
        [bB])
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done
