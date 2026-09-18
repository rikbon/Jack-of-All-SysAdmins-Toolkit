#!/usr/bin/env bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [--check]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "--check" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

write_log "Starting Disk Space Monitor..." "INFO"

THRESHOLD=85

# Get disk usage and filter
df -P | awk 'NR > 1 && $1 !~ /^(tmpfs|cdrom|loop|snapfuse)/ { gsub(/%/, "", $5); print $5, $1 }' | while read -r usep partition;
do
    if (( usep >= THRESHOLD )); then
        write_log "Running out of space \"$partition ($usep%)\" on $(hostname) as of $(date)" "WARN"
    else
        write_log "Disk usage healthy for \"$partition ($usep%)\"" "SUCCESS"
    fi
done

write_log "Disk Space Monitor Finished." "INFO"
