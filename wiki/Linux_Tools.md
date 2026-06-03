# Linux Tools

The `Linux/` directory contains bash scripts designed to automate system administration tasks on Linux environments (such as Ubuntu/Debian, RHEL/Fedora/CentOS, Arch, Alpine, and openSUSE). 

All tools log to the central `logs/Toolkit_YYYYMMDD.log` file using standardized functions defined in `globals.sh`.

## Main Launcher
- **`start-sysadmintoolbox.sh`**: The interactive Text User Interface (TUI) menu that allows you to launch all the tools below. 

## Utilities

### `cleanup.sh` (System Maintenance)
Performs a comprehensive cleanup of the system to reclaim disk space.
- Cleans APT package cache.
- Vacuums `systemd` journal logs (keeps 2 days).
- Removes old compressed log archives (`.gz`, `.1`).
- Prunes Docker resources (if installed).
- Clears user thumbnail caches.
- Cleans `/tmp` directory files older than 2 days.

### `update-system.sh` (System Maintenance)
A distro-aware update script that automatically detects the host OS (via `/etc/os-release`) and runs the appropriate system update commands (e.g., `apt-get update/upgrade`, `dnf upgrade`, `pacman -Syu`, `apk upgrade`, or `zypper update`).

### `monitor-disk.sh` (Disk & Storage)
Scans all mounted partitions and logs a warning for any partition that exceeds 85% usage. It intelligently ignores read-only mounts like `tmpfs`, `cdrom`, `loop`, and `snapfuse` to prevent false alarms.

### `network-tools.sh` (Network Utility)
A bundled utility providing quick access to:
- **Active TCP Connections**: Uses `ss -tulpn` to show listening ports.
- **Public IP Fetch**: Calls an external API to retrieve the host's public IP address.
- **Ping Test**: Runs a quick ping against Google's public DNS (8.8.8.8) to verify outbound connectivity.

### `manage-services.sh` (Service Utility)
A service manager script that lets you:
- List failed `systemd` services using `systemctl --failed`.
- Interactively start, stop, or restart specific services (supports both `systemctl` and legacy `service` commands).

### `get-sysreport.sh` (System Health & Troubleshooting)
Generates an immediate terminal report covering:
- OS Version and Kernel string.
- Hostname and Uptime.
- 1, 5, and 15-minute CPU load averages.
- RAM and Swap memory usage (`free -h`).

### `process-monitor.sh` (Process & Performance)
A performance monitoring menu that allows you to:
- Show the top 10 memory-consuming processes.
- Show the top 10 CPU-consuming processes.
- Send a `kill -9` signal to forcefully terminate a misbehaving process by its PID.

### `audit-users.sh` (Security & File Utilities)
A quick security audit script that:
- Identifies users with `sudo` or `wheel` (root) privileges.
- Scans `/etc/shadow` for any user accounts that have empty passwords.
- Displays the last 10 successful logins using the `last` command.

### `manage-firewall.sh` (Security & File Utilities)
A firewall abstraction tool that supports both `ufw` and `firewalld`:
- Displays current firewall status and active rules.
- Allows opening a specific TCP port.
- Allows denying/closing a specific TCP port.
