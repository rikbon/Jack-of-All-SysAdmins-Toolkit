#!/usr/bin/env bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [--cleanup]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if [[ -n "${1:-}" && "${1:-}" != "--cleanup" ]]; then cli_usage_error "$1"; show_help >&2; exit 2; fi

assert_root

# Function to get current disk usage
get_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free"}'
}

BEFORE_USAGE=$(get_usage)
write_log "Starting System Cleanup" "INFO"
write_log "Disk Usage Before: $BEFORE_USAGE" "INFO"

# 1. Clean Package Manager Cache (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
    write_log "[1/6] Cleaning APT cache..." "INFO"
    apt-get autoremove -y > /dev/null 2>&1
    apt-get autoclean -y > /dev/null 2>&1
    apt-get clean
fi

# 2. Rotate and Clear System Logs (Journald)
if command -v journalctl >/dev/null 2>&1; then
    write_log "[2/6] Vacuuming systemd journal logs (keeping 2 days)..." "INFO"
    journalctl --vacuum-time=2d > /dev/null 2>&1
fi

# 3. Clear Old Log Files
write_log "[3/6] Removing old log archives..." "INFO"
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete

# 4. Cleanup Docker (if installed)
if command -v docker >/dev/null 2>&1; then
    write_log "[4/6] Pruning Docker (images, containers, networks)..." "INFO"
    docker system prune -af --volumes > /dev/null 2>&1
fi

# 5. Clear User Thumbnail Caches
write_log "[5/6] Clearing user thumbnail caches..." "INFO"
find /home -mindepth 3 -maxdepth 3 -path '*/.cache/thumbnails/*' -type f -delete 2>/dev/null || true

# 6. Clear Temporary Files
write_log "[6/6] Cleaning /tmp directory (older than 2 days)..." "INFO"
find /tmp -type f -atime +2 -delete 2> /dev/null

AFTER_USAGE=$(get_usage)
write_log "Cleanup Complete" "SUCCESS"
write_log "BEFORE: $BEFORE_USAGE" "INFO"
write_log "AFTER:  $AFTER_USAGE" "INFO"