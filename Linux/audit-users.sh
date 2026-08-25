#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [interactive]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "interactive" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

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
            pause_toolkit
            ;;
        2)
            write_log "Accounts with empty passwords:" "INFO"
            empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow)
            if [ -z "$empty_pass" ]; then
                write_log "No empty passwords found. System is secure." "SUCCESS"
            else
                write_log "WARNING: Empty passwords found for: $empty_pass" "WARN"
            fi
            pause_toolkit
            ;;
        3)
            write_log "Last 10 Logins:" "INFO"
<<<<<<< HEAD
            last -n 10
            pause_toolkit
=======

            show_last_logins() {
                # 1) Prefer `last` (from util-linux) if present.
                if command -v last >/dev/null 2>&1; then
                    last -n 10
                    return
                fi
                # 2) Fall back to `lastlog` (from shadow/login), shows recent
                #    successful logins for local users.
                if command -v lastlog >/dev/null 2>&1; then
                    write_log "`'last'` not found; falling back to `'lastlog'`." "WARN"
                    lastlog | grep -vi "never"
                    return
                fi
                # 3) Fall back to dumping /var/log/wtmp directly with utmpdump.
                if command -v utmpdump >/dev/null 2>&1 && [ -f /var/log/wtmp ]; then
                    write_log "`'last'` not found; dumping /var/log/wtmp via utmpdump." "WARN"
                    utmpdump /var/log/wtmp | awk -F'[\\[\\]]' '$2==8{print}' \
                        | tail -n 10
                    return
                fi
                # 4) Last-ditch: grep successful ssh/console logins from auth logs.
                if ls /var/log/auth.log* /var/log/secure* >/dev/null 2>&1; then
                    write_log "No `last`-family tool found; showing recent auth logins." "WARN"
                    grep -h "Accepted \(publickey\|password\)\|session opened" \
                        /var/log/auth.log /var/log/secure 2>/dev/null \
                        | tail -n 10
                    return
                fi
                write_log "Could not determine recent logins: no 'last', 'lastlog', 'utmpdump', or readable auth log found." "ERROR"
            }

            show_last_logins
            read -p "Press enter to continue..."
>>>>>>> d195c5a4a0a263f554b9a72b7e90e0dade4a66e9
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
