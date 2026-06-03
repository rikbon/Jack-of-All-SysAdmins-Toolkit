#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

show_menu() {
    clear
    echo -e "${CYAN}=== Process & Performance ===${NC}"
    echo "1. Show Top 10 Memory Hogs"
    echo "2. Show Top 10 CPU Hogs"
    echo "3. Kill Process by ID"
    echo "B. Back"
    echo ""
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1)
            write_log "Top 10 Memory Hogs:" "INFO"
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11
            read -p "Press enter to continue..."
            ;;
        2)
            write_log "Top 10 CPU Hogs:" "INFO"
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11
            read -p "Press enter to continue..."
            ;;
        3)
            read -p "Enter Process ID to kill: " pid_to_kill
            if [[ -n "$pid_to_kill" && "$pid_to_kill" =~ ^[0-9]+$ ]]; then
                kill -9 "$pid_to_kill" 2>/dev/null
                if [ $? -eq 0 ]; then
                    write_log "Successfully sent kill signal to PID $pid_to_kill." "SUCCESS"
                else
                    write_log "Failed to kill PID $pid_to_kill. (Are you root? Does it exist?)" "ERROR"
                fi
            else
                write_log "Invalid PID." "WARN"
            fi
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
