#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--memory|--cpu|--terminate PID] [--quiet]\n' "$0"
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

show_top_memory() { ps -axo pid,ppid,%mem,%cpu,comm -r | head -n 11; }
show_top_cpu() { ps -axo pid,ppid,%mem,%cpu,comm -r | sort -k4 -nr | head -n 11; }
terminate_process() {
    local pid="$1"
    if ! valid_pid "$pid"; then write_log 'Invalid process ID.' 'WARN'; return 2; fi
    if kill -0 "$pid" 2>/dev/null; then run_logged "Terminating PID $pid" kill "$pid"; else write_log "PID $pid is not running or is inaccessible." 'WARN'; return 1; fi
}

show_menu() {
    clear
    printf '%b=== macOS Process & Performance ===%b\n' "$CYAN" "$NC"
    printf '1. Show top 10 memory consumers\n2. Show top 10 CPU consumers\n3. Terminate a process\nB. Back\n\n'
}

case "${1:-interactive}" in
    --memory) show_top_memory ;;
    --cpu) show_top_cpu ;;
    --terminate)
        [[ $# -eq 2 ]] || { printf 'Usage: %s --terminate PID\n' "$0" >&2; exit 2; }
        terminate_process "$2"
        ;;
    interactive)
        while true; do
            show_menu
            read -r -p 'Select an option: ' choice
            case "$choice" in
                1) show_top_memory; pause_toolkit ;;
                2) show_top_cpu; pause_toolkit ;;
                3)
                    read -r -p 'Enter process ID to terminate: ' pid
                    if valid_pid "$pid"; then
                        read -r -p "Send TERM to PID $pid? (y/N) " confirm
                        [[ "$confirm" =~ ^[Yy]$ ]] && terminate_process "$pid" || write_log 'Process termination cancelled.' 'INFO'
                    else write_log 'Invalid process ID.' 'WARN'; fi
                    pause_toolkit
                    ;;
                [bB]) break ;;
                *) write_log 'Invalid option.' 'WARN' ;;
            esac
        done
        ;;
    *) cli_usage_error "${1:-}"; show_help >&2; exit 2 ;;
esac
