#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--list|--start SERVICE_LABEL|--stop SERVICE_LABEL|--restart SERVICE_LABEL] [--quiet]\n' "$0"
}
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

require_command launchctl

valid_label() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

list_services() {
    launchctl list
}

service_action() {
    local action="$1"
    local label="$2"

    if ! valid_label "$label"; then
        write_log "Invalid launchd service label: $label" "ERROR"
        return 2
    fi

    case "$action" in
        start) run_logged "Starting launchd service $label" launchctl start "$label" ;;
        stop) run_logged "Stopping launchd service $label" launchctl stop "$label" ;;
        restart)
            run_logged "Stopping launchd service $label" launchctl stop "$label" || true
            run_logged "Starting launchd service $label" launchctl start "$label"
            ;;
        *) write_log "Unsupported service action: $action" "ERROR"; return 2 ;;
    esac
}

show_menu() {
    clear
    printf '%b=== macOS Service Management ===%b\n' "$CYAN" "$NC"
    printf '1. List loaded services\n'
    printf '2. Start a service\n'
    printf '3. Stop a service\n'
    printf '4. Restart a service\n'
    printf 'B. Back\n\n'
}

case "${1:-interactive}" in
    --list) list_services ;;
    --start|--stop|--restart)
        [[ $# -eq 2 ]] || { printf 'Usage: %s %s SERVICE_LABEL\n' "$0" "$1" >&2; exit 2; }
        service_action "${1#--}" "$2"
        ;;
    interactive)
        while true; do
            show_menu
            read -r -p 'Select an option: ' choice
            case "$choice" in
                1) list_services; pause_toolkit ;;
                2|3|4)
                    action=start
                    [[ "$choice" == 3 ]] && action=stop
                    [[ "$choice" == 4 ]] && action=restart
                    read -r -p 'Enter launchd service label: ' label
                    if valid_label "$label"; then
                        read -r -p "Confirm $action for $label? (y/N) " confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then service_action "$action" "$label"; else write_log 'Service action cancelled.' 'INFO'; fi
                    else write_log "Invalid launchd service label: $label" 'ERROR'; fi
                    pause_toolkit
                    ;;
                [bB]) break ;;
                *) write_log 'Invalid option.' 'WARN' ;;
            esac
        done
        ;;
    *) cli_usage_error "${1:-}"; show_help >&2; exit 2 ;;
esac
