#!/bin/bash
# --- globals.sh ---
# Shared configurations and functions for Jack-of-All-SysAdmins Linux Toolkit.

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
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

write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp][$level] $message"

    # Append to log file
    echo "$log_entry" >> "$LOG_FILE"

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

assert_root() {
    if [[ $EUID -ne 0 ]]; then
        write_log "This script requires root privileges. Please run with sudo." "ERROR"
        exit 1
    fi
}
