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
The initial macOS tools are non-destructive diagnostics and can be launched without administrator privileges:

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

## Menu Structures

Both launchers share a similar organizational structure:
1.  **System Maintenance**: Access tools for cleaning disks and updating the OS/apps.
2.  **Disk & Storage**: Monitor disk space and manage storage.
3.  **Network Utility**: Run network diagnostics and checks.
4.  *(Windows Only)* **Service Utility**: Restart common services like Print Spooler.
5.  *(Windows Only)* **System Health**: Generate reports and run system checks.
6.  *(Windows Only)* **Process & Performance**: Monitor resources.
7.  *(Windows Only)* **Security & File Utilities**: Audit users and files.
8.  *(Windows Only)* **Logging & Auditing**: Archive logs.

*(Note: The Linux and macOS toolkits are actively expanding to reach broader feature parity with the Windows suite.)*

## Features
- **Auto-Elevation**: Both scripts ensure you are running with the necessary permissions (`RunAs` for Windows, `sudo` enforcement for Linux).
- **Standardized Logging**: All actions performed via the menus are logged to the centralized `logs/Toolkit_YYYYMMDD.log` using the shared logging functions (`Write-Log` / `write_log`).
