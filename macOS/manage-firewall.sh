#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--status|--allow PORT|--block PORT|--list] [--quiet]\n' "$0"
}

SOCKETFILTERFW='/usr/libexec/ApplicationFirewall/socketfilterfw'

show_status() {
    if [[ -x "$SOCKETFILTERFW" ]]; then
        write_log 'Application Firewall (socketfilterfw):' 'INFO'
        run_logged 'Reading the application firewall state' "$SOCKETFILTERFW" --getglobalstate
        "$SOCKETFILTERFW" --getblockall; try "$SOCKETFILTERFW" --getstealthmode
    else
        write_log 'socketfilterfw not available on this system.' 'WARN'
    fi

    if command -v pfctl >/dev/null 2>&1; then
        write_log 'Packet filter (pf):' 'INFO'
        # pfctl needs root and prints its own diagnostics on stderr.
        try bash -c "pfctl -s info 2>&1 | head -n 5"
    fi
}

list_rules() {
    if [[ -x "$SOCKETFILTERFW" ]]; then
        write_log 'Application firewall block/allow lists:' 'INFO'
        run_logged 'Reading the application firewall lists' "$SOCKETFILTERFW" --listapps
    fi
    if command -v pfctl >/dev/null 2>&1; then
        write_log 'pf rules:' 'INFO'
        try bash -c "pfctl -sr 2>&1 | head -n 20"
    fi
    if [[ ! -x "$SOCKETFILTERFW" ]] && ! command -v pfctl >/dev/null 2>&1; then
        write_log 'No macOS packet filtering mechanism found.' 'WARN'
    fi
}

# The application firewall filters by *application bundle*, not by port, so a
# port-oriented rule needs pf. Both paths are offered and both are confirmed.
allow_port() {
    local port="$1"
    local rule="pass in proto tcp from any to any port = $port"

    if ! valid_port "$port"; then
        write_log "Invalid port: $port" 'ERROR'
        return 2
    fi

    printf 'A macOS application firewall filters by bundle, not by port.\n'
    printf 'Use the pf rule instead: pass in proto tcp from any to any port = %s\n' "$port"
    read -r -p "Add this pf rule to /etc/pf.conf? (y/N) " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { write_log 'Firewall change cancelled.' 'INFO'; return 0; }

    command -v pfctl >/dev/null 2>&1 || {
        write_log 'pfctl not found; cannot apply the rule.' 'ERROR'
        return 1
    }

    # Guard against a duplicated anchor line growing on every run.
    if ! grep -Fq "$rule" /etc/pf.conf 2>/dev/null; then
        printf '%s\n' "$rule" >> /etc/pf.conf
    fi
    # pf must be loaded explicitly on macOS; --enable is what activates it.
    run_logged 'Loading the pf ruleset' pfctl -e
    write_log "Allowed TCP port $port via pf. Review /etc/pf.conf to keep the change." 'SUCCESS'
}

block_port() {
    local port="$1"
    local rule="block in proto tcp from any to any port = $port"

    if ! valid_port "$port"; then
        write_log "Invalid port: $port" 'ERROR'
        return 2
    fi

    read -r -p "Add this pf rule to /etc/pf.conf? (y/N) " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { write_log 'Firewall change cancelled.' 'INFO'; return 0; }

    command -v pfctl >/dev/null 2>&1 || {
        write_log 'pfctl not found; cannot apply the rule.' 'ERROR'
        return 1
    }

    if ! grep -Fq "$rule" /etc/pf.conf 2>/dev/null; then
        printf '%s\n' "$rule" >> /etc/pf.conf
    fi
    run_logged 'Loading the pf ruleset' pfctl -e
    write_log "Blocked TCP port $port via pf. Review /etc/pf.conf to keep the change." 'SUCCESS'
}

show_menu() {
    clear
    printf '%b=== macOS Firewall Manager ===%b\n' "$CYAN" "$NC"
    printf '1. Show firewall status (socketfilterfw + pf)\n'
    printf '2. List firewall rules\n'
    printf '3. Allow a TCP port (pf rule)\n'
    printf '4. Block a TCP port (pf rule)\n'
    printf 'B. Back\n\n'
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

# Validate the arguments before demanding root, so a usage error reports the
# usage error rather than a permission failure.
case "${1:-interactive}" in
    --status|--list|--allow|--block|interactive) ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac

assert_root

case "${1:-interactive}" in
    --status) show_status ;;
    --list) list_rules ;;
    --allow)
        [[ $# -eq 2 ]] || { printf 'Usage: %s --allow PORT\n' "$0" >&2; exit 2; }
        allow_port "$2"
        ;;
    --block)
        [[ $# -eq 2 ]] || { printf 'Usage: %s --block PORT\n' "$0" >&2; exit 2; }
        block_port "$2"
        ;;
    interactive)
        while true; do
            show_menu
            read -r -p 'Select an option: ' choice
            case "$choice" in
                1) show_status; pause_toolkit ;;
                2) list_rules; pause_toolkit ;;
                3)
                    read -r -p 'Enter port number to allow (e.g. 443): ' port
                    allow_port "$port"
                    pause_toolkit
                    ;;
                4)
                    read -r -p 'Enter port number to block (e.g. 3389): ' port
                    block_port "$port"
                    pause_toolkit
                    ;;
                [bB]) break ;;
                *) write_log 'Invalid option.' 'WARN' ;;
            esac
        done
        ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac