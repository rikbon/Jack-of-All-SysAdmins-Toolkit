#!/bin/bash
# --- install.sh ---
# One-liner installer for the Jack-of-All-SysAdmins Linux Toolkit.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.sh | sudo bash
#   # or, without sudo baked in, wrapped explicitly:
#   wget -qO- https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.sh | sudo bash
#
# What it does:
#   1. Detects the Linux distribution / package manager.
#   2. Installs all runtime dependencies required by the toolkit scripts.
#   3. Downloads the latest toolkit release and installs it to /opt/sysadmin-toolbox.
#   4. Drops a symlink in /usr/local/bin so `sysadmin-toolbox` launches the dashboard.

set -euo pipefail

# --- Configuration ---
REPO="rikbon/Jack-of-All-SysAdmins-Toolkit"
INSTALL_DIR="/opt/sysadmin-toolbox"
BIN_LINK="/usr/local/bin/sysadmin-toolbox"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/Jack-of-All-SysAdmins-Toolkit-linux.tar.gz"
# Fallback: the latest main branch archive (works even before any release is
# published from this repo).
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"
TMPDIR_INST="$(mktemp -d)"

# Colors
C_NC='\033[0m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'

log()      { echo -e "${C_CYAN}[install]${C_NC} $*"; }
log_ok()   { echo -e "${C_GREEN}[install]${C_NC} $*"; }
log_warn() { echo -e "${C_YELLOW}[install]${C_NC} $*"; }
log_err()  { echo -e "${C_RED}[install]${C_NC} $*" >&2; }

cleanup() {
    rm -rf "$TMPDIR_INST" 2>/dev/null || true
}
trap cleanup EXIT

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    log_err "This installer must be run as root. Re-run with: sudo bash $0"
    exit 1
fi

# --- Detect distro ---
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
        DISTRO_PRETTY="${PRETTY_NAME:-$DISTRO_ID}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
        DISTRO_PRETTY="unknown"
    fi
    log "Detected system: ${DISTRO_PRETTY}"
}

# --- Map the runtime deps to per-distro package names, then install. ---
# Commands the toolkit scripts rely on (audited across Linux/*.sh):
#   last(A), lastlog(A), utmpdump(A) -> fallbacks only; at least one good.
#   awk   -> gawk / mawk
#   curl  -> curl
#   ss    -> iproute2
#   ping  -> iputils-ping
#   df,free,uname,ps,uptime,hostname,head,tail,cut,grep,find,date,kill,getent
#        -> coreutils, procps, util-linux (always present or installed below)
#   systemctl -> systemd (assume present; only used on systemd distros)
#   apt-get,dnf,yum,pacman,apk,zypper -> the distro's own mgr (no action needed)
install_deps() {
    detect_distro

    # Packages per family. The lists are intentionally additive; missing
    # packages are simply skipped.
    PKGS_DEB=""     # apt (Debian/Ubuntu/Linux Mint/pop)
    PKGS_RPM=""     # yum/dnf (Fedora/CentOS/RHEL/Rocky/Alma)
    PKGS_ARCH=""    # pacman
    PKGS_APK=""     # apk (Alpine)
    PKGS_ZYPP=""    # zypper (openSUSE)

    for cmd in last awk curl ss ping lastlog utmpdump; do
        command -v "$cmd" >/dev/null 2>&1 && continue
        case "$cmd" in
            last|lastlog|utmpdump)
                PKGS_DEB+="util-linux util-linux-extra "
                PKGS_RPM+="util-linux "
                PKGS_ARCH+="util-linux "
                PKGS_APK+="util-linux "
                PKGS_ZYPP+="util-linux-systemd " ;;   # utmpdump lives here on SUSE
            awk)
                PKGS_DEB+="gawk "
                PKGS_RPM+="gawk "
                PKGS_ARCH+="gawk "
                PKGS_APK+="gawk "
                PKGS_ZYPP+="gawk " ;;
            curl)
                PKGS_DEB+="curl "
                PKGS_RPM+="curl "
                PKGS_ARCH+="curl "
                PKGS_APK+="curl "
                PKGS_ZYPP+="curl " ;;
            ss)
                PKGS_DEB+="iproute2 "
                PKGS_RPM+="iproute "
                PKGS_ARCH+="iproute2 "
                PKGS_APK+="iproute2 "
                PKGS_ZYPP+="iproute2 " ;;
            ping)
                PKGS_DEB+="iputils-ping "
                PKGS_RPM+="iputils "
                PKGS_ARCH+="iputils "
                PKGS_APK+="iputils "
                PKGS_ZYPP+="iputils " ;;
        esac
    done

    # base packages that should be present everywhere, but belt-and-suspenders
    PKGS_DEB+="coreutils procps "
    PKGS_RPM+="coreutils procps-ng "
    PKGS_ARCH+="coreutils procps-ng "
    PKGS_APK+="coreutils procps "
    PKGS_ZYPP+="coreutils ps "

    install_for_family() {
        local mgr="$1"; shift
        local pkgs="$*"
        # Drop duplicates / empties
        pkgs="$(echo "$pkgs" | tr ' ' '\n' | awk 'NF' | sort -u | tr '\n' ' ')"
        if [ -z "${pkgs// /}" ]; then
            log "All runtime dependencies already satisfied."
            return 0
        fi
        log "Installing missing packages via ${mgr}: ${pkgs}"
        case "$mgr" in
            apt)
                apt-get update -y -qq
                # shellcheck disable=SC2086
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pkgs ;;
            dnf)
                dnf install -y -q $pkgs ;;
            yum)
                yum install -y -q $pkgs ;;
            pacman)
                pacman -Sy --noconfirm --needed $pkgs ;;
            apk)
                apk add --no-cache $pkgs ;;
            zypper)
                zypper --non-interactive install $pkgs ;;
        esac
    }

    # Distro dispatch (mirrors update-system.sh logic).
    case "$DISTRO_ID" in
        debian|ubuntu|linuxmint|pop|kali|raspbian)
            install_for_family apt $PKGS_DEB ;;
        fedora)
            install_for_family dnf $PKGS_RPM ;;
        centos|rhel|rocky|almalinux|ol)
            if command -v dnf >/dev/null 2>&1; then
                install_for_family dnf $PKGS_RPM
            else
                install_for_family yum $PKGS_RPM
            fi ;;
        arch|manjaro|endeavouros)
            install_for_family pacman $PKGS_ARCH ;;
        alpine)
            install_for_family apk $PKGS_APK ;;
        opensuse*|sles*|suse)
            install_for_family zypper $PKGS_ZYPP ;;
        *)
            # Try by "like" field, then by guessing the package.
            if [[ "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
                install_for_family apt $PKGS_DEB
            elif [[ "$DISTRO_LIKE" == *"fedora"* || "$DISTRO_LIKE" == *"rhel"* || "$DISTRO_LIKE" == *"centos"* ]]; then
                command -v dnf >/dev/null 2>&1 && install_for_family dnf $PKGS_RPM || install_for_family yum $PKGS_RPM
            elif [[ "$DISTRO_LIKE" == *"arch"* ]]; then
                install_for_family pacman $PKGS_ARCH
            elif [[ "$DISTRO_LIKE" == *"suse"* ]]; then
                install_for_family zypper $PKGS_ZYPP
            elif command -v apt-get >/dev/null 2>&1; then
                log "Unknown distro; defaulting to apt. $DISTRO_PRETTY"
                install_for_family apt $PKGS_DEB
            elif command -v dnf >/dev/null 2>&1; then
                install_for_family dnf $PKGS_RPM
            elif command -v yum >/dev/null 2>&1; then
                install_for_family yum $PKGS_RPM
            elif command -v pacman >/dev/null 2>&1; then
                install_for_family pacman $PKGS_ARCH
            elif command -v apk >/dev/null 2>&1; then
                install_for_family apk $PKGS_APK
            elif command -v zypper >/dev/null 2>&1; then
                install_for_family zypper $PKGS_ZYPP
            else
                log_err "Unsupported package manager for dependency installation."
                log_err "Please install manually: util-linux (last/utmpdump), gawk, curl, iproute2 (ss), iputils-ping (ping)."
                exit 1
            fi ;;
    esac
}

# --- Download + install the toolkit ---
install_toolbox() {
    log "Downloading latest toolkit..."
    local tarball="${TMPDIR_INST}/toolkit.tar.gz"
    dl() {
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$1" -o "$tarball"
        elif command -v wget >/dev/null 2>&1; then
            wget -q "$1" -O "$tarball"
        else
            # Guaranteed present because we just installed curl.
            log_err "Neither curl nor wget available after dependency install."
            exit 1
        fi
    }
    # Prefer the published release tarball; fall back to the main branch
    # archive if none is published yet.
    dl "$RELEASE_URL" || {
        log_warn "Release asset not found; falling back to the main branch archive."
        dl "$ARCHIVE_URL"
    }

    log "Installing to ${INSTALL_DIR}..."
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$tarball" -C "$INSTALL_DIR" --strip-components=1

    # Find the launcher inside the extracted Linux/ directory and symlink it.
    local launcher=""
    for candidate in \
        "${INSTALL_DIR}/Linux/start-sysadmintoolbox.sh" \
        "${INSTALL_DIR}/start-sysadmintoolbox.sh" ; do
        if [ -f "$candidate" ]; then launcher="$candidate"; break; fi
    done

    if [ -z "$launcher" ]; then
        log_warn "Launcher not found at expected path; symlinking install dir instead."
        launcher="${INSTALL_DIR}"
    fi

    ln -sf "$launcher" "$BIN_LINK"
    chmod +x "$BIN_LINK"

    log_ok "Installed launcher -> ${BIN_LINK}"
}

# --- Main ---
log "Jack-of-All-SysAdmins Toolkit installer"
log "========================================"

install_deps
install_toolbox

log_ok "Done! Launch the dashboard with:"
log_ok ""
log_ok "   sysadmin-toolbox"
log_ok ""
log_ok "(You may need to re-open your shell for the PATH entry to take effect.)"
