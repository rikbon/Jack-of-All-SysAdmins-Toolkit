#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--update] [--list|--upgrade] [--quiet]\n' "$0"
}

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

brew_path=""

list_outdated() {
    if [[ -z "$brew_path" ]]; then
        write_log 'Homebrew not installed; nothing to list.' 'WARN'
        return 1
    fi
    write_log 'Checking for outdated Homebrew packages...' 'INFO'
    run_logged 'Refreshing the Homebrew formula index' "$brew_path" update
    "$brew_path" outdated
}

upgrade_packages() {
    if [[ -z "$brew_path" ]]; then
        write_log 'Homebrew not installed; nothing to upgrade.' 'WARN'
        return 1
    fi
    read -r -p 'Upgrade all outdated Homebrew packages? (y/N) ' confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        write_log 'Homebrew upgrade cancelled.' 'INFO'
        return 0
    fi
    run_logged 'Upgrading Homebrew packages' "$brew_path" upgrade
}

list_os_updates() {
    require_command softwareupdate || return 1
    run_logged 'Listing available macOS updates' softwareupdate --list
}

install_os_updates() {
    require_command softwareupdate || return 1
    read -r -p 'Install all available macOS updates now? (y/N) ' confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        write_log 'macOS update cancelled.' 'INFO'
        return 0
    fi
    run_logged 'Installing macOS updates' softwareupdate --install --all
}

run_update() {
    write_log 'Starting macOS system update...' 'INFO'
    upgrade_packages || true
    install_os_updates || true
    write_log 'System update finished.' 'INFO'
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

case "${1:-interactive}" in
    --update|--list|--upgrade|interactive) ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac

# Probed only once the arguments are known to be valid, so `--help` and a
# usage error never print an install warning first.
brew_path="$(find_brew || true)"
if [[ -z "$brew_path" ]]; then
    write_log 'Homebrew was not found. Install it separately before using this tool.' 'WARN'
fi

assert_root

case "${1:-interactive}" in
    --update) run_update ;;
    --list) list_outdated; list_os_updates ;;
    --upgrade) upgrade_packages ;;
    interactive)
        clear
        printf '%b=== macOS System Updates ===%b\n' "$CYAN" "$NC"
        if [[ -n "$brew_path" ]]; then
            printf 'Homebrew: %s\n' "$brew_path"
        else
            printf 'Homebrew: not installed\n'
        fi
        printf '\n1. List outdated packages and OS updates\n'
        printf '2. Upgrade Homebrew packages\n'
        printf '3. Install macOS updates\n'
        printf '4. Run a full update (packages + OS)\n'
        printf 'B. Back\n\n'
        read -r -p 'Select an option: ' choice
        case "$choice" in
            1) list_outdated; list_os_updates; pause_toolkit ;;
            2) upgrade_packages; pause_toolkit ;;
            3) install_os_updates; pause_toolkit ;;
            4) run_update; pause_toolkit ;;
            [bB]) exit 0 ;;
            *) write_log 'Invalid option.' 'WARN'; exit 2 ;;
        esac
        ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac