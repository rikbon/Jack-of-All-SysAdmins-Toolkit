#!/bin/bash

# --- start-sysadmintoolbox.sh ---
# The master menu for the Linux Toolkit

# Resolve the *real* directory of this script, even when invoked through a
# symlink (e.g. the /usr/local/bin/sysadmin-toolbox shortcut created by
# install.sh). Without this, `dirname` returns the symlink's parent dir and
# globals.sh (write_log, colours, ...) isn't found.
__SRC="${BASH_SOURCE[0]}"
while [ -L "$__SRC" ]; do
    __LINK_DIR="$(cd "$(dirname "$__SRC")" >/dev/null 2>&1 && pwd)"
    __SRC="$(readlink "$__SRC")"
    # Resolve relative symlink paths against the directory holding the link.
    [[ "$__SRC" != /* ]] && __SRC="$__LINK_DIR/$__SRC"
done
SCRIPT_DIR="$(cd "$(dirname "$__SRC")" >/dev/null 2>&1 && pwd)"
unset __SRC __LINK_DIR
source "${SCRIPT_DIR}/globals.sh"

assert_root

show_main_menu() {
    clear
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN} Jack-of-All-SysAdmins Linux v2.2.1 ${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""
    echo "1. System Maintenance (Clean, Update)"
    echo "2. Disk & Storage (Monitor Space)"
    echo "3. Network Utility"
    echo "4. Service Utility"
    echo "5. System Health & Troubleshooting"
    echo "6. Process & Performance"
    echo "7. Security & File Utilities"
    echo "Q. Quit"
    echo ""
}

run_script() {
    local script_name="$1"
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    if [ -f "$script_path" ]; then
        write_log "Launching $script_name..." "INFO"
        bash "$script_path"
    else
        write_log "Script $script_name not found at $script_path" "ERROR"
        sleep 2
    fi
}

while true; do
    show_main_menu
    read -p "Select a Category: " choice

    case $choice in
        1)
            while true; do
                clear
                echo -e "${CYAN}=== System Maintenance ===${NC}"
                echo "1. System Cleanup"
                echo "2. System Update (apt/yum/pacman/etc)"
                echo "B. Back"
                echo ""
                read -p "Select an option: " subchoice
                
                case $subchoice in
                    1) run_script "cleanup.sh" ; read -p "Press enter to continue..." ;;
                    2) run_script "update-system.sh" ; read -p "Press enter to continue..." ;;
                    [bB]) break ;;
                esac
            done
            ;;
        2)
            while true; do
                clear
                echo -e "${CYAN}=== Disk & Storage ===${NC}"
                echo "1. Monitor Disk Space"
                echo "B. Back"
                echo ""
                read -p "Select an option: " subchoice
                
                case $subchoice in
                    1) run_script "monitor-disk.sh" ; read -p "Press enter to continue..." ;;
                    [bB]) break ;;
                esac
            done
            ;;
        3) run_script "network-tools.sh" ;;
        4) run_script "manage-services.sh" ;;
        5) run_script "get-sysreport.sh" ;;
        6) run_script "process-monitor.sh" ;;
        7)
            while true; do
                clear
                echo -e "${CYAN}=== Security & File Utilities ===${NC}"
                echo "1. Audit Users & Logins"
                echo "2. Manage Firewall Rules"
                echo "B. Back"
                echo ""
                read -p "Select an option: " subchoice
                
                case $subchoice in
                    1) run_script "audit-users.sh" ;;
                    2) run_script "manage-firewall.sh" ;;
                    [bB]) break ;;
                esac
            done
            ;;
        [qQ])
            write_log "Exiting Jack-of-All-SysAdmins Linux Toolkit." "INFO"
            exit 0
            ;;
        *)
            echo "Invalid option. Please select a valid number."
            sleep 1
            ;;
    esac
done
