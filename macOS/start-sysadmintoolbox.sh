#!/usr/bin/env bash

set -Eeuo pipefail

# --- start-sysadmintoolbox.sh ---
# The master menu for the macOS Toolkit

# Resolve the real directory, including when launched through a symlink.
__SRC="${BASH_SOURCE[0]}"
while [ -L "$__SRC" ]; do
    __LINK_DIR="$(cd "$(dirname "$__SRC")" >/dev/null 2>&1 && pwd)"
    __SRC="$(readlink "$__SRC")"
    [[ "$__SRC" != /* ]] && __SRC="$__LINK_DIR/$__SRC"
done
SCRIPT_DIR="$(cd "$(dirname "$__SRC")" >/dev/null 2>&1 && pwd)"
unset __SRC __LINK_DIR
source "${SCRIPT_DIR}/globals.sh" || exit 1

VERSION="$(<"${SCRIPT_DIR}/../VERSION")"

show_main_menu() {
    clear
    printf '%b=================================%b\n' "$CYAN" "$NC"
    printf '%b Jack-of-All-SysAdmins macOS v%s %b\n' "$CYAN" "$VERSION" "$NC"
    printf '%b=================================%b\n\n' "$CYAN" "$NC"
    printf '1. System Maintenance (Clean, Update)\n'
    printf '2. Disk & Storage (Monitor Space)\n'
    printf '3. Network Utility\n'
    printf '4. Service Utility\n'
    printf '5. System Health & Troubleshooting\n'
    printf '6. Process & Performance\n'
    printf '7. Security & File Utilities\n'
    printf 'Q. Quit\n\n'
}

run_script() {
    local script_name="$1"
    shift
    local script_path="${SCRIPT_DIR}/${script_name}"

    if [[ ! -f "$script_path" ]]; then
        write_log "Script $script_name not found at $script_path" "ERROR"
        return 1
    fi

    write_log "Launching $script_name..." "INFO"
    # Capture the status inside the `else` branch: after `fi`, `$?` is the status
    # of the `if` statement (always 0), not of the child process.
    if bash "$script_path" "$@"; then
        return 0
    else
        local exit_code=$?
        write_log "$script_name failed (exit code: $exit_code)." "ERROR"
        return "$exit_code"
    fi
}

while true; do
    show_main_menu
    read -r -p 'Select a category: ' choice || exit 0

    case "$choice" in
        1)
            while true; do
                clear
                printf '%b=== System Maintenance ===%b\n' "$CYAN" "$NC"
                printf '1. System Cleanup\n'
                printf '2. System Update (brew / softwareupdate)\n'
                printf 'B. Back\n\n'
                read -r -p 'Select an option: ' subchoice || break

                case "$subchoice" in
                    1) run_script cleanup.sh; pause_toolkit ;;
                    2) run_script update-system.sh; pause_toolkit ;;
                    [bB]) break ;;
                    *) write_log 'Invalid option.' 'WARN' ;;
                esac
            done
            ;;
        2)
            while true; do
                clear
                printf '%b=== Disk & Storage ===%b\n' "$CYAN" "$NC"
                printf '1. Monitor Disk Space\n'
                printf 'B. Back\n\n'
                read -r -p 'Select an option: ' subchoice || break

                case "$subchoice" in
                    1) run_script monitor-disk.sh; pause_toolkit ;;
                    [bB]) break ;;
                    *) write_log 'Invalid option.' 'WARN' ;;
                esac
            done
            ;;
        3) run_script network-tools.sh ;;
        4) run_script manage-services.sh ;;
        5) run_script get-sysreport.sh ;;
        6) run_script process-monitor.sh ;;
        7)
            while true; do
                clear
                printf '%b=== Security & File Utilities ===%b\n' "$CYAN" "$NC"
                printf '1. Audit Users & Logins\n'
                printf '2. Manage Firewall Rules\n'
                printf 'B. Back\n\n'
                read -r -p 'Select an option: ' subchoice || break

                case "$subchoice" in
                    1) run_script audit-users.sh ;;
                    2) run_script manage-firewall.sh ;;
                    [bB]) break ;;
                    *) write_log 'Invalid option.' 'WARN' ;;
                esac
            done
            ;;
        [qQ])
            write_log 'Exiting Jack-of-All-SysAdmins macOS Toolkit.' 'INFO'
            exit 0
            ;;
        *) write_log 'Invalid option.' 'WARN' ;;
    esac
done