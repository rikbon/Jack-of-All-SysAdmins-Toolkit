#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1
VERSION="$(<"${SCRIPT_DIR}/../VERSION")"

run_script() {
    local script_name="$1"
    local script_path="${SCRIPT_DIR}/${script_name}"

    if [[ ! -f "$script_path" ]]; then
        write_log "Script not found: $script_path" "ERROR"
        return 1
    fi

    write_log "Launching $script_name..." "INFO"
    if bash "$script_path"; then
        return 0
    fi
    local exit_code=$?
    write_log "$script_name failed (exit code: $exit_code)." "ERROR"
    return "$exit_code"
}

show_main_menu() {
    clear
    printf '%b=================================%b\n' "$CYAN" "$NC"
    printf '%b Jack-of-All-SysAdmins macOS v%s %b\n' "$CYAN" "$VERSION" "$NC"
    printf '%b=================================%b\n\n' "$CYAN" "$NC"
    printf '1. System Report\n'
    printf '2. Disk & Storage\n'
    printf '3. Network Utility\n'
    printf '4. Process & Performance\n'
    printf '5. Service Management\n'
    printf '6. Homebrew Updates\n'
    printf 'Q. Quit\n\n'
}

while true; do
    show_main_menu
    read -r -p 'Select a category: ' choice
    case "$choice" in
        1) run_script get-sysreport.sh interactive; pause_toolkit ;;
        2) run_script monitor-disk.sh interactive; pause_toolkit ;;
        3) run_script network-tools.sh interactive ;;
        4) run_script process-monitor.sh interactive ;;
        5) run_script manage-services.sh interactive ;;
        6) run_script manage-homebrew.sh interactive ;;
        [qQ])
            write_log 'Exiting Jack-of-All-SysAdmins macOS Toolkit.' 'INFO'
            exit 0
            ;;
        *) write_log 'Invalid option.' 'WARN' ;;
    esac
done
