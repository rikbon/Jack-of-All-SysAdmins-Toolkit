#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--check] [--quiet]\n' "$0"
}

monitor_disk() {
    local threshold="${DISK_THRESHOLD:-85}"
    if [[ ! "$threshold" =~ ^[0-9]+$ ]] || (( threshold < 1 || threshold > 100 )); then
        write_log "Invalid DISK_THRESHOLD: $threshold" "ERROR"
        return 2
    fi

    write_log "Starting macOS disk space monitor..." "INFO"
    while read -r usep partition; do
        if (( usep >= threshold )); then
            write_log "Running out of space on $partition ($usep%)." "WARN"
        else
            write_log "Disk usage healthy for $partition ($usep%)." "SUCCESS"
        fi
    done < <(df -P | awk 'NR > 1 { gsub(/%/, "", $5); print $5, $6 }')
    write_log "macOS disk space monitor finished." "INFO"
}

if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi

case "${1:-interactive}" in
    --check) monitor_disk ;;
    interactive)
        monitor_disk
        pause_toolkit
        ;;
    *) cli_usage_error "${1:-}" || true; show_help >&2; exit 2 ;;
esac
