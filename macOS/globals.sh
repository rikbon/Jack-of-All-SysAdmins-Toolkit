#!/usr/bin/env bash

set -Eeuo pipefail

_toolkit_error_trap() {
    local exit_code=$?
    write_log "Unexpected failure in ${BASH_SOURCE[1]} at line ${BASH_LINENO[0]} (exit code: $exit_code)." "ERROR" 2>/dev/null || true
    exit "$exit_code"
}
trap _toolkit_error_trap ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/cli.sh" || exit 1
LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/Toolkit_$(date +'%Y%m%d').log"

NC='\033[0m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
GRAY='\033[0;37m'
CYAN='\033[1;36m'

# `--quiet` silences the console only. The log file stays a faithful audit
# trail: an operator running a tool quietly still wants the record on disk.
write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp][$level] $message"

    printf '%s\n' "$log_entry" >> "$LOG_FILE"

    if [[ "${TOOLKIT_QUIET:-0}" == "1" ]]; then
        return 0
    fi

    case "$level" in
        INFO) printf '%b%s%b\n' "$WHITE" "$log_entry" "$NC" ;;
        WARN) printf '%b%s%b\n' "$YELLOW" "$log_entry" "$NC" ;;
        ERROR) printf '%b%s%b\n' "$RED" "$log_entry" "$NC" ;;
        SUCCESS) printf '%b%s%b\n' "$GREEN" "$log_entry" "$NC" ;;
        DEBUG) printf '%b%s%b\n' "$GRAY" "$log_entry" "$NC" ;;
        *) printf '%s\n' "$log_entry" ;;
    esac
}

# Interactive menus must survive an expected failure (a `grep` with no matches,
# killing a PID owned by another user, ...). `set -e` plus the ERR trap would
# otherwise abort the whole TUI, so wrap such commands in `try`, which always
# succeeds and only records the failure at DEBUG level.
try() {
    local exit_code=0
    "$@" || exit_code=$?
    if (( exit_code != 0 )); then
        write_log "Command failed (exit code: $exit_code): $*" "DEBUG"
    fi
    return 0
}

pause_toolkit() {
    read -r -p "Press enter to continue..."
}

require_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        write_log "Required command not found: $command_name" "ERROR"
        return 1
    fi
}

# Root is only needed by the privileged tools, so the launcher does not assert
# it globally: the read-only ones stay usable by an unprivileged operator.
assert_root() {
    if [[ $EUID -ne 0 ]]; then
        write_log "This script requires root privileges. Please run with sudo." "ERROR"
        exit 1
    fi
}

valid_pid() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 < 10#$1 ))
}

valid_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 <= 10#$1 && 10#$1 <= 65535 ))
}

run_logged() {
    local description="$1"
    shift
    write_log "$description" "INFO"
    if "$@"; then
        write_log "$description succeeded." "SUCCESS"
        return 0
    else
        local exit_code=$?
        write_log "$description failed (exit code: $exit_code)." "ERROR"
        return "$exit_code"
    fi
}
