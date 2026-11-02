# SysAdmin Toolbox (Main Menus)

**Windows Script**: `Windows/Start-SysAdminToolbox.ps1`
**Linux Script**: `Linux/start-sysadmintoolbox.sh`
**macOS Script**: `macOS/start-sysadmintoolbox.sh`

## Overview
The **SysAdmin Toolbox** is the central hub for this suite of utilities. It provides text-based, menu-driven interfaces to access all other scripts and built-in functions, tailored for the respective operating system.

## Usage

### Windows (PowerShell)
Run the script from PowerShell. It will automatically attempt to elevate to Administrator privileges via `Assert-Admin` if not already running as Admin.

```powershell
.\Windows\Start-SysAdminToolbox.ps1
```

### Linux (Bash)
Run the script from your terminal using `sudo` to ensure you have the necessary root privileges via `assert_root`.

```bash
sudo bash ./Linux/start-sysadmintoolbox.sh
```

### macOS (Bash)

The diagnostic tools run without administrator privileges. The tools that change
system state (`cleanup.sh`, `manage-firewall.sh`, `update-system.sh`) call
`assert_root` themselves and exit with a clear message otherwise, so you can
start the launcher unprivileged and escalate only where it is needed:

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

## Menu Structures

The Linux and macOS launchers share the exact same seven-category structure, and
the tool file names match one for one:

1.  **System Maintenance**: Cleanup (`cleanup.sh`) and updates (`update-system.sh`).
2.  **Disk & Storage**: Monitor disk space (`monitor-disk.sh`).
3.  **Network Utility**: Network diagnostics (`network-tools.sh`).
4.  **Service Utility**: `launchctl` service control (`manage-services.sh`).
5.  **System Health & Troubleshooting**: System reports (`get-sysreport.sh`).
6.  **Process & Performance**: Top processes and termination (`process-monitor.sh`).
7.  **Security & File Utilities**: User audit (`audit-users.sh`) and firewall (`manage-firewall.sh`).

The Windows launcher adds two categories the other platforms have no equivalent
for: **Logging & Auditing** and the WSL maintenance tools.

## Features
- **Auto-Elevation**: Windows elevates with `RunAs`, Linux enforces `sudo` via
  `assert_root`, and macOS asserts it per tool so diagnostics stay unprivileged.
- **Standardized Logging**: All actions performed via the menus are logged to the centralized `logs/Toolkit_YYYYMMDD.log` using the shared logging functions (`Write-Log` / `write_log`).
- **Resilient Menus**: The launchers log the real exit code of each tool they
  launch and wrap diagnostic commands in `try`, so an expected failure returns
  you to the menu instead of terminating the session.
