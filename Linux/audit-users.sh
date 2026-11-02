#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive] [--quiet]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

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

show_last_logins() {
    if command -v last >/dev/null 2>&1; then
        try last -n 10
        return
    fi
    if command -v lastlog >/dev/null 2>&1; then
        write_log "'last' not found; falling back to 'lastlog'." "WARN"
        # Every account may be "never logged in": grep exits 1.
        try bash -c 'lastlog | grep -vi "never"'
        return
    fi
    if command -v utmpdump >/dev/null 2>&1 && [ -f /var/log/wtmp ]; then
        write_log "'last' not found; dumping /var/log/wtmp via utmpdump." "WARN"
        # utmpdump exits non-zero on a truncated wtmp; that must not kill the menu.
        try bash -c "utmpdump /var/log/wtmp 2>/dev/null | awk -F'[][]' '\$2==8{print}' | tail -n 10"
        return
    fi
    if ls /var/log/auth.log* /var/log/secure* >/dev/null 2>&1; then
        write_log "No last-family tool found; showing recent auth logins." "WARN"
        try bash -c 'grep -hE "Accepted (publickey|password)|session opened" /var/log/auth.log /var/log/secure 2>/dev/null | tail -n 10'
        return
    fi
    write_log "Could not determine recent logins: no login-history tool or readable auth log found." "ERROR"
}

show_privileged_users() {
    write_log "Users with Sudo/Root privileges:" "INFO"
    # List the *members* of the privileged groups, not the group definitions.
    local group members found_any=0
    for group in root sudo wheel admin adm; do
        members=$(getent group "$group" 2>/dev/null | cut -d: -f4)
        if [ -n "$members" ]; then
            write_log "  $group: $members" "INFO"
            found_any=1
        fi
    done
    if [ "$found_any" -eq 0 ]; then
        write_log "No sudo/wheel group members found (or getent is unavailable)." "WARN"
    fi
}

show_empty_password_accounts() {
    write_log "Accounts with empty passwords:" "INFO"
    local empty_pass account
    empty_pass=$(awk -F: '($2 == "") { print $1 }' /etc/shadow)
    if [ -z "$empty_pass" ]; then
        write_log "No empty passwords found. System is secure." "SUCCESS"
        return
    fi
    for account in $empty_pass; do
        write_log "Empty password for account: $account" "WARN"
    done
}

while true; do
    show_menu
    read -r -p "Select an option: " choice

    case $choice in
        1) show_privileged_users ; pause_toolkit ;;
        2) show_empty_password_accounts ; pause_toolkit ;;
        3) show_last_logins ; pause_toolkit ;;
        [bB]) break ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done