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

write_log() {
    if [[ "${TOOLKIT_QUIET:-0}" == "1" ]]; then
        return 0
    fi
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp][$level] $message"

    printf '%s\n' "$log_entry" >> "$LOG_FILE"
    case "$level" in
        INFO) printf '%b%s%b\n' "$WHITE" "$log_entry" "$NC" ;;
        WARN) printf '%b%s%b\n' "$YELLOW" "$log_entry" "$NC" ;;
        ERROR) printf '%b%s%b\n' "$RED" "$log_entry" "$NC" ;;
        SUCCESS) printf '%b%s%b\n' "$GREEN" "$log_entry" "$NC" ;;
        DEBUG) printf '%b%s%b\n' "$GRAY" "$log_entry" "$NC" ;;
        *) printf '%s\n' "$log_entry" ;;
    esac
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

valid_pid() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 < 10#$1 ))
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
