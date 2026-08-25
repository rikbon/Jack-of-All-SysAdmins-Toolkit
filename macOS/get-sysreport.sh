#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--report] [--quiet]\n' "$0"
}

get_system_report() {
    require_command sw_vers
    require_command system_profiler
    require_command sysctl

    write_log "Generating macOS system report..." "INFO"
    printf '\n%b=== System Information ===%b\n' "$CYAN" "$NC"
    printf 'OS: %s\n' "$(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
    printf 'Kernel: %s\n' "$(uname -sr)"
    printf 'Hostname: %s\n' "$(scutil --get ComputerName 2>/dev/null || hostname)"
    printf 'Uptime: %s\n' "$(uptime)"

    printf '\n%b=== Hardware ===%b\n' "$CYAN" "$NC"
    system_profiler SPHardwareDataType | sed -n '1,12p'
    printf 'CPU cores: %s\n' "$(sysctl -n hw.ncpu)"
    printf 'Memory: %s\n' "$(sysctl -n hw.memsize | awk '{ printf "%.2f GB", $1 / 1024 / 1024 / 1024 }')"

    printf '\n%b=== Storage ===%b\n' "$CYAN" "$NC"
    df -h
    write_log "macOS system report complete." "SUCCESS"
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

case "${1:-interactive}" in
    --report) get_system_report ;;
    interactive)
        get_system_report
        pause_toolkit
        ;;
    *) cli_usage_error "${1:-}"; show_help >&2; exit 2 ;;
esac
