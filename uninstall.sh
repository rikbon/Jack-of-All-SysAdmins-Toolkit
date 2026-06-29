#!/bin/bash
# --- uninstall.sh ---
# One-liner uninstaller for the Jack-of-All-SysAdmins Linux Toolkit.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.sh | sudo bash
#
# By default, your logs under /opt/sysadmin-toolbox/logs are kept. To purge
# them too, rerun with PURGE_LOGS=1:
#   PURGE_LOGS=1 sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.sh)"
#
# What it does:
#   1. Removes the /usr/local/bin/sysadmin-toolbox launcher symlink.
#   2. Removes the entire /opt/sysadmin-toolbox installation directory.
#   3. Leaves log files in place unless PURGE_LOGS=1 is set.

set -euo pipefail

# --- Configuration ---
INSTALL_DIR="/opt/sysadmin-toolbox"
BIN_LINK="/usr/local/bin/sysadmin-toolbox"

# Colors
C_NC='\033[0m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'

log()      { echo -e "${C_CYAN}[uninstall]${C_NC} $*"; }
log_ok()   { echo -e "${C_GREEN}[uninstall]${C_NC} $*"; }
log_warn() { echo -e "${C_YELLOW}[uninstall]${C_NC} $*"; }
log_err()  { echo -e "${C_RED}[uninstall]${C_NC} $*" >&2; }

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    log_err "This uninstaller must be run as root. Re-run with: sudo bash $0"
    exit 1
fi

# --- Resolve the install dir from the symlink if it still points at us. ---
if [ -L "$BIN_LINK" ]; then
    resolved="$(readlink -f "$BIN_LINK" 2>/dev/null || true)"
    if [ -n "$resolved" ]; then
        resolved_dir="$(dirname "$resolved")"
        # Only trust the resolved dir if it actually is our install dir; a
        # user may have pointed the symlink somewhere else.
        case "$resolved_dir" in
            "${INSTALL_DIR}/Linux"|"${INSTALL_DIR}")
                INSTALL_DIR="$(dirname "$resolved_dir")" ;;
        esac
    fi
fi

log "Jack-of-All-SysAdmins Linux Toolkit uninstaller"
log "================================================"

# 1) Remove the launcher symlink.
if [ -e "$BIN_LINK" ] || [ -L "$BIN_LINK" ]; then
    rm -f "$BIN_LINK"
    log_ok "Removed launcher symlink: $BIN_LINK"
else
    log "Launcher (already removed?): $BIN_LINK"
fi

# 2) Remove the installation directory.
if [ -d "$INSTALL_DIR" ]; then
    if [ "${PURGE_LOGS:-0}" = "1" ]; then
        rm -rf "$INSTALL_DIR"
        log_ok "Removed installation directory (logs purged): $INSTALL_DIR"
    else
        # Preserve logs by moving them out first, then removing the rest.
        LOG_BACKUP="$(mktemp -d)"
        if [ -d "$INSTALL_DIR/logs" ]; then
            mv "$INSTALL_DIR/logs" "$LOG_BACKUP/logs"
            log "Preserved logs to $LOG_BACKUP/logs"
        fi
        rm -rf "$INSTALL_DIR"
        # Drop the preserved logs somewhere the user can find them.
        PRESERVE_DIR="/var/log/sysadmin-toolbox"
        mkdir -p "$PRESERVE_DIR"
        if [ -d "$LOG_BACKUP/logs" ]; then
            cp -a "$LOG_BACKUP/logs/." "$PRESERVE_DIR/"
            rm -rf "$LOG_BACKUP"
            log_ok "Logs preserved at $PRESERVE_DIR"
        fi
        log_ok "Removed installation directory: $INSTALL_DIR"
    fi
else
    log "Installation directory not found (already removed?): $INSTALL_DIR"
fi

log_ok "Uninstall complete."
