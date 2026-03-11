# SysAdmin Toolbox (Main Menu)

**Script**: `Start-SysAdminToolbox.ps1`

## Overview
The **SysAdmin Toolbox** is the central hub for this suite of utilities. It provides a text-based, menu-driven interface to access all other scripts and built-in functions.

## Usage
Run the script from PowerShell. It will automatically attempt to elevate to Administrator privileges if not already running as Admin.

```powershell
.\Start-SysAdminToolbox.ps1
```

## Menu Structure
1.  **System Maintenance**: Access tools for cleaning disks, updating Windows, and updating apps (Winget/Chocolatey).
2.  **Disk & Storage**: Monitor disk space and manage WSL virtual disks.
3.  **Network Utility**: Flush DNS, Ping test, Public IP check, Active connections, and WSL network repair.
4.  **Service Utility**: Restart common services like Print Spooler and Windows Explorer.
5.  **System Health & Troubleshooting**: Generate reports, run SFC/DISM, check Event Logs and BSOD Minidumps.
6.  **Process & Performance**: Monitor resource usage, kill processes, and manage startup apps.
7.  **Security & File Utilities**: Audit users, hash files, find large files, scan ports, and manage firewall rules.
8.  **Logging & Auditing**: Audit user activity, archive event logs, and rotate toolkit logs.

## Features
- **Auto-Elevation**: Checks for Admin rights via `Assert-Admin` and relaunches itself with `RunAs` if needed.
- **Standardized Logging**: All actions performed via the menu are logged to `.\logs\Toolkit_YYYYMMDD.log` using the shared `Write-Log` function.
