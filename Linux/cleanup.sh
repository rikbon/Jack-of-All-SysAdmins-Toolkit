#!/bin/bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

assert_root

# Function to get current disk usage
get_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free"}'
}

BEFORE_USAGE=$(get_usage)
write_log "Starting System Cleanup" "INFO"
write_log "Disk Usage Before: $BEFORE_USAGE" "INFO"

# 1. Clean Package Manager Cache (Debian/Ubuntu)
if [ -x "$(command -v apt-get)" ]; then
    write_log "[1/6] Cleaning APT cache..." "INFO"
    apt-get autoremove -y > /dev/null 2>&1
    apt-get autoclean -y > /dev/null 2>&1
    apt-get clean
fi

# 2. Rotate and Clear System Logs (Journald)
if [ -x "$(command -v journalctl)" ]; then
    write_log "[2/6] Vacuuming systemd journal logs (keeping 2 days)..." "INFO"
    journalctl --vacuum-time=2d > /dev/null 2>&1
fi

# 3. Clear Old Log Files
write_log "[3/6] Removing old log archives..." "INFO"
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete

# 4. Cleanup Docker (if installed)
if [ -x "$(command -v docker)" ]; then
    write_log "[4/6] Pruning Docker (images, containers, networks)..." "INFO"
    docker system prune -af --volumes > /dev/null 2>&1
fi

# 5. Clear User Thumbnail Caches
write_log "[5/6] Clearing user thumbnail caches..." "INFO"
rm -rf /home/*/.cache/thumbnails/* 2> /dev/null

# 6. Clear Temporary Files
write_log "[6/6] Cleaning /tmp directory (older than 2 days)..." "INFO"
find /tmp -type f -atime +2 -delete 2> /dev/null

AFTER_USAGE=$(get_usage)
write_log "Cleanup Complete" "SUCCESS"
write_log "BEFORE: $BEFORE_USAGE" "INFO"
write_log "AFTER:  $AFTER_USAGE" "INFO"