#!/bin/bash

# Source globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/globals.sh"

write_log "Starting Disk Space Monitor..." "INFO"

THRESHOLD=85

# Get disk usage and filter
df -h | grep -vE '^Filesystem|tmpfs|cdrom|loop|snapfuse' | awk '{ print $5 " " $1 }' | while read output;
do
    usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
    partition=$(echo $output | awk '{ print $2 }' )
    
    if [ $usep -ge $THRESHOLD ]; then
        write_log "Running out of space \"$partition ($usep%)\" on $(hostname) as of $(date)" "WARN"
    else
        write_log "Disk usage healthy for \"$partition ($usep%)\"" "SUCCESS"
    fi
done

write_log "Disk Space Monitor Finished." "INFO"
