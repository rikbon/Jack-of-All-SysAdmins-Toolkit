#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh" || exit 1

show_help() { printf 'Usage: %s [--report] [--quiet]\n' "$0"; }
if cli_help_requested "${1:-}"; then show_help; exit 0; fi
if cli_quiet_requested "${1:-}"; then TOOLKIT_QUIET=1; shift; fi
if [[ -n "${1:-}" && "${1:-}" != "--report" ]]; then cli_usage_error "$1" || true; show_help >&2; exit 2; fi

write_log "Generating System Health Report..." "INFO"

echo -e "\n${CYAN}=== System Information ===${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
else
    echo "OS: $(uname -srm)"
fi
echo "Kernel: $(uname -r)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"

echo -e "\n${CYAN}=== CPU Load ===${NC}"
awk '{print "1 min: "$1", 5 min: "$2", 15 min: "$3}' /proc/loadavg

echo -e "\n${CYAN}=== Memory Usage ===${NC}"
free -h | awk 'NR==1{print "      " $2 "  " $3 "  " $4} NR==2{print "RAM:  " $2 "   " $3 "  " $4} NR==3{print "Swap: " $2 "   " $3 "  " $4}'

echo ""
write_log "System Health Report Complete." "SUCCESS"
pause_toolkit
