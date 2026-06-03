#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

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
cat /proc/loadavg | awk '{print "1 min: "$1", 5 min: "$2", 15 min: "$3}'

echo -e "\n${CYAN}=== Memory Usage ===${NC}"
free -h | awk 'NR==1{print "      " $2 "  " $3 "  " $4} NR==2{print "RAM:  " $2 "   " $3 "  " $4} NR==3{print "Swap: " $2 "   " $3 "  " $4}'

echo ""
write_log "System Health Report Complete." "SUCCESS"
read -p "Press enter to continue..."
