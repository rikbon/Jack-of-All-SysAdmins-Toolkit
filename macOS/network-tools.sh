#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--interfaces|--listening|--public-ip|--ping] [--quiet]\n' "$0"
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

show_interfaces() { require_command ifconfig && ifconfig; }
show_listening_sockets() { require_command netstat && netstat -anv -p tcp | awk 'NR == 1 || /LISTEN/'; }
show_public_ip() {
    require_command curl || return
    local public_ip
    public_ip=$(curl --fail --silent --show-error --max-time 5 https://api.ipify.org) || {
        write_log 'Failed to fetch public IP.' 'ERROR'
        return 1
    }
    write_log "Public IP: $public_ip" 'SUCCESS'
}
test_connectivity() {
    require_command ping || return
    if ping -c 4 1.1.1.1; then write_log 'Ping test passed.' 'SUCCESS'; else write_log 'Ping test failed.' 'ERROR'; return 1; fi
}

show_menu() {
    clear
    printf '%b=== macOS Network Tools ===%b\n' "$CYAN" "$NC"
    printf '1. Show network interfaces\n2. Show listening sockets\n3. Get public IP\n4. Ping 1.1.1.1\nB. Back\n\n'
}

if [[ "${1:-interactive}" == "--interfaces" ]]; then show_interfaces; exit $?; fi
if [[ "${1:-interactive}" == "--listening" ]]; then show_listening_sockets; exit $?; fi
if [[ "${1:-interactive}" == "--public-ip" ]]; then show_public_ip; exit $?; fi
if [[ "${1:-interactive}" == "--ping" ]]; then test_connectivity; exit $?; fi
if [[ "${1:-interactive}" != "interactive" ]]; then cli_usage_error "${1:-}" || true; show_help >&2; exit 2; fi

while true; do
    show_menu
    read -r -p 'Select an option: ' choice
    case "$choice" in
        1) show_interfaces; pause_toolkit ;;
        2) show_listening_sockets; pause_toolkit ;;
        3) show_public_ip; pause_toolkit ;;
        4) test_connectivity; pause_toolkit ;;
        [bB]) break ;;
        *) write_log 'Invalid option.' 'WARN' ;;
    esac
done
