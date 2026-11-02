#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive] [--quiet]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

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
    read -r -p "Select an option: " choice

    case $choice in
        1)
            write_log "Top 10 Memory Hogs:" "INFO"
            try bash -c 'ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11'
            pause_toolkit
            ;;
        2)
            write_log "Top 10 CPU Hogs:" "INFO"
            try bash -c 'ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11'
            pause_toolkit
            ;;
        3)
            read -r -p "Enter Process ID to kill: " pid_to_kill
            if valid_pid "$pid_to_kill"; then
                read -r -p "Send TERM to PID $pid_to_kill? (y/N) " confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    write_log "Process termination cancelled." "INFO"
                elif kill -0 "$pid_to_kill" 2>/dev/null; then
                    run_logged "Sending TERM to PID $pid_to_kill" kill "$pid_to_kill"
                else
                    write_log "PID $pid_to_kill is not running or is inaccessible." "WARN"
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
