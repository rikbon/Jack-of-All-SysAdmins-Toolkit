#!/usr/bin/env bash

set -Eeuo pipefail

_toolkit_error_trap() {
    local exit_code=$?
    write_log "Unexpected failure in ${BASH_SOURCE[1]} at line ${BASH_LINENO[0]} (exit code: $exit_code)." "ERROR" 2>/dev/null || true
    exit "$exit_code"
}
trap _toolkit_error_trap ERR

# --- globals.sh ---
# Shared configurations and functions for Jack-of-All-SysAdmins Linux Toolkit.

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/cli.sh" || exit 1

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

LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "$LOG_DIR"

DATE_STR=$(date +'%Y%m%d')
LOG_FILE="${LOG_DIR}/Toolkit_${DATE_STR}.log"

# Colors
NC='\033[0m' # No Color
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
GRAY='\033[0;37m'
CYAN='\033[1;36m'

# --- Functions ---

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

valid_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 <= 10#$1 && 10#$1 <= 65535 ))
}

valid_pid() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 < 10#$1 ))
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


write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp][$level] $message"

    # Append to log file
    echo "$log_entry" >> "$LOG_FILE"

    # `--quiet` silences the console only. The log file stays a faithful audit
    # trail: an operator running a tool quietly still wants the record on disk.
    if [[ "${TOOLKIT_QUIET:-0}" == "1" ]]; then
        return 0
    fi

    # Print to console with color
    case "$level" in
        "INFO")    echo -e "${WHITE}${log_entry}${NC}" ;;
        "WARN")    echo -e "${YELLOW}${log_entry}${NC}" ;;
        "ERROR")   echo -e "${RED}${log_entry}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}${log_entry}${NC}" ;;
        "DEBUG")   echo -e "${GRAY}${log_entry}${NC}" ;;
        *)         echo -e "${WHITE}${log_entry}${NC}" ;;
    esac
}

# Root is only needed by the privileged tools, so the launcher does not assert
# it globally: the read-only ones stay usable by an unprivileged operator.
assert_root() {
    if [[ $EUID -ne 0 ]]; then
        write_log "This script requires root privileges. Please run with sudo." "ERROR"
        exit 1
    fi
}
