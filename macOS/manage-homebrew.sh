#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--list|--upgrade] [--quiet]\n' "$0"
}
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

find_brew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        printf '/opt/homebrew/bin/brew\n'
    elif [[ -x /usr/local/bin/brew ]]; then
        printf '/usr/local/bin/brew\n'
    else
        return 1
    fi
}

brew_path="$(find_brew || true)"
if [[ -z "$brew_path" ]]; then
    write_log 'Homebrew was not found. Install it separately before using this tool.' 'WARN'
    exit 1
fi

list_outdated() {
    write_log 'Checking for outdated Homebrew packages...' 'INFO'
    "$brew_path" outdated
}

upgrade_packages() {
    read -r -p 'Upgrade all outdated Homebrew packages? (y/N) ' confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        write_log 'Homebrew upgrade cancelled.' 'INFO'
        return 0
    fi
    run_logged 'Upgrading Homebrew packages' "$brew_path" upgrade
}

case "${1:-interactive}" in
    --list) list_outdated ;;
    --upgrade) upgrade_packages ;;
    interactive)
        clear
        printf '%b=== macOS Homebrew Updates ===%b\n' "$CYAN" "$NC"
        printf 'Homebrew: %s\n\n' "$brew_path"
        printf '1. List outdated packages\n'
        printf '2. Upgrade all packages\n'
        printf 'B. Back\n\n'
        read -r -p 'Select an option: ' choice
        case "$choice" in
            1) list_outdated; pause_toolkit ;;
            2) upgrade_packages; pause_toolkit ;;
            [bB]) exit 0 ;;
            *) write_log 'Invalid option.' 'WARN'; exit 2 ;;
        esac
        ;;
    *) cli_usage_error "${1:-}"; show_help >&2; exit 2 ;;
esac
