#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() {
    printf 'Usage: %s [--cleanup] [--quiet]\n' "$0"
}
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "--cleanup" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

# `find_brew` is probed after argument validation, so a usage error or `--help`
# never triggers the package-manager probing first.
assert_root

get_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free"}'
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

before_usage=$(get_usage)
write_log 'Starting macOS cleanup' 'INFO'
write_log "Disk usage before: $before_usage" 'INFO'

step=1
total=6
next_step() {
    step=$((step + 1))
}

# 1. Homebrew cache and old versions. `brew cleanup -s` is the aggressive form
#    that also drops source downloads and stale versions of the current formula.
brew_path="$(find_brew || true)"
if [[ -n "$brew_path" ]]; then
    write_log "[$step/$total] Cleaning the Homebrew cache..." 'INFO'
    run_logged 'Homebrew cleanup' "$brew_path" cleanup -s || true
else
    write_log "[$step/$total] Homebrew not found; skipping package cleanup." 'WARN'
fi
next_step

# 2. Homebrew caches outside the main one (downloads, API and version caches).
if [[ -n "$brew_path" ]]; then
    write_log "[$step/$total] Purging the Homebrew download cache..." 'INFO'
    "$brew_path" --cache 2>/dev/null | while read -r cache_dir; do
        [[ -d "$cache_dir" ]] || continue
        try find "$cache_dir" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +
    done
fi
next_step

# 3. Time Machine local snapshots. Only local ones: Apple and on-demand
#    snapshots are managed by the OS and removing them can break restores.
if command -v tmutil >/dev/null 2>&1; then
    write_log "[$step/$total] Thinning Time Machine local snapshots..." 'INFO'
    run_logged 'Time Machine local snapshot thinning' tmutil thinlocalsnapshots / 10000000000 4 || true
else
    write_log "[$step/$total] tmutil not found; skipping snapshot thinning." 'WARN'
fi
next_step

# 4. Rotated and archived logs. Never delete the current file: macOS keeps
#    appending to /var/log/*.log and an unlinked-but-open file loses the trail.
write_log "[$step/$total] Removing rotated log archives..." 'INFO'
try find /var/log -type f \( -name '*.gz' -o -name '*.bz2' -o -name '*.1' \) -mtime +7 -delete
next_step

# 5. User caches: only well-known rebuildable ones, and only when older than a
#    week so a running application does not lose its warm cache.
write_log "[$step/$total] Clearing user caches (older than 7 days)..." 'INFO'
for cache_root in "$HOME/Library/Caches" "$HOME/Library/Logs"; do
    [[ -d "$cache_root" ]] || continue
    try find "$cache_root" -mindepth 2 -maxdepth 2 -type d -mtime +7 -exec rm -rf {} +
done
next_step

# 6. Temporary files. `getconf DARWIN_USER_TEMP_DIR` is the per-user temp dir;
#    /tmp is a symlink to /private/tmp on macOS.
write_log "[$step/$total] Clearing temporary files (older than 2 days)..." 'INFO'
user_temp="${TMPDIR:-/tmp}"
user_temp="${user_temp%/}"
[[ -d "$user_temp" ]] || user_temp=/tmp
try find "$user_temp" -mindepth 1 -maxdepth 1 -user "$(id -un)" -atime +2 -exec rm -rf {} +

write_log 'Cleanup complete.' 'SUCCESS'
write_log "BEFORE: $before_usage" 'INFO'
write_log "AFTER:  $(get_usage)" 'INFO'