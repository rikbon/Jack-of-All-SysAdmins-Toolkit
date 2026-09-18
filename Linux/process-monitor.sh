#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

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
            pause_toolkit
            ;;
        2)
            write_log "Top 10 CPU Hogs:" "INFO"
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11
            pause_toolkit
            ;;
        3)
            read -p "Enter Process ID to kill: " pid_to_kill
            if [[ -n "$pid_to_kill" && "$pid_to_kill" =~ ^[0-9]+$ && "$pid_to_kill" -gt 1 ]]; then
                kill "$pid_to_kill" 2>/dev/null
                if [ $? -eq 0 ]; then
                    write_log "Successfully sent termination signal to PID $pid_to_kill." "SUCCESS"
                else
                    write_log "Failed to kill PID $pid_to_kill. (Are you root? Does it exist?)" "ERROR"
                fi
            else
                write_log "Invalid PID." "WARN"
            fi
            pause_toolkit
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
