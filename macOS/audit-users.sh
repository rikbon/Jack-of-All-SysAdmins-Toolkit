#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--privileged|--empty-passwords|--logins] [--quiet]\n' "$0"
}

list_privileged_users() {
    require_command dscl
    write_log 'Accounts in the admin group:' 'INFO'

    local members found_any=0
    # macOS grants admin rights through the `admin` group; `GroupMembership`
    # lists its *members*, which is what we want (not the group definitions).
    members=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | awk '{ $1=""; sub(/^ /, ""); print }')
    for member in $members; do
        write_log "  $member" 'INFO'
        found_any=1
    done

    if (( found_any == 0 )); then
        write_log 'No members found in the admin group (or dscl is unavailable).' 'WARN'
    fi

    # Also surface accounts whose uid is 0: a non-admin root account would not
    # show up in the admin group but is still a full compromise.
    local uid0
    uid0=$(dscl . -list /Users 2>/dev/null | awk '$2 == "0" { print $1 }')
    for account in $uid0; do
        # Skip the synthetic entries macOS always exposes.
        [[ "$account" == _* || "$account" == "root" || "$account" == "nobody" ]] && continue
        write_log "  $account has uid 0" 'WARN'
    done
}

list_empty_password_accounts() {
    require_command dscl
    write_log 'Accounts with an empty password attribute:' 'INFO'

    local accounts account password found_any=0
    # macOS keeps an authentication authority per user rather than a shadow
    # file, so an empty `dscl` password or a "guest-style" empty hash is the
    # signal we look for. Skip the synthetic accounts.
    accounts=$(dscl . -list /Users 2>/dev/null | awk '{ print $1 }')
    for account in $accounts; do
        [[ "$account" == _* ]] && continue
        password=$(dscl . -read "/Users/$account" 2>/dev/null | grep -i '^password:' | head -n 1 || true)
        if [[ -z "$password" || "$password" == *": "*":$" || "$password" =~ :[[:space:]]*$ ]]; then
            write_log "Empty password for account: $account" 'WARN'
            found_any=1
        fi
    done

    if (( found_any == 0 )); then
        write_log 'No empty passwords found.' 'SUCCESS'
    fi
}

show_last_logins() {
    if command -v last >/dev/null 2>&1; then
        # `last` exits non-zero on some machines once the utmp rotation
        # truncates a record; that must not kill the menu.
        try last -n 10
        return
    fi

    write_log "'last' not found; falling back to 'who'." 'WARN'
    if command -v who >/dev/null 2>&1; then
        try who
        return
    fi

    # Last resort: the unified log records successful authentications there.
    if command -v log >/dev/null 2>&1; then
        write_log 'No last-family tool found; showing recent authentication events.' 'WARN'
        try bash -c "log show --last 24h --predicate 'eventMessage CONTAINS[c] \"authentication\"' --style compact 2>/dev/null | head -n 20"
        return
    fi

    write_log 'Could not determine recent logins: no login-history tool found.' 'ERROR'
}

show_menu() {
    clear
    printf '%b=== macOS User & Login Audit ===%b\n' "$CYAN" "$NC"
    printf '1. List admin / uid 0 accounts\n'
    printf '2. Check for accounts with empty passwords\n'
    printf '3. Show the last 10 logins\n'
    printf 'B. Back\n\n'
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

case "${1:-interactive}" in
    --privileged) list_privileged_users ;;
    --empty-passwords) list_empty_password_accounts ;;
    --logins) show_last_logins ;;
    interactive)
        while true; do
            show_menu
            read -r -p 'Select an option: ' choice
            case "$choice" in
                1) list_privileged_users; pause_toolkit ;;
                2) list_empty_password_accounts; pause_toolkit ;;
                3) show_last_logins; pause_toolkit ;;
                [bB]) break ;;
                *) write_log 'Invalid option.' 'WARN' ;;
            esac
        done
        ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac