# 🛠️ The Jack-of-All-SysAdmins Toolkit `v1.2.1`

> *One script to rule them all, one script to find them, one script to bring them all and in the terminal bind them.*

Welcome to **The Jack-of-All-SysAdmins Toolkit**. This project is a unified, menu-driven PowerShell suite designed to handle the daily grind of system administration with style and safety.

## 🚀 Quick Start
Launch the master dashboard:
```powershell
.\Start-SysAdminToolbox.ps1
```
*(Run as Administrator for full power)*

---

## 📚 Documentation
Detailed documentation for each module is available in the `docs/` folder:

*   [**Main Toolbox**](docs/SysAdminToolbox.md): The menu-driven interface.
*   [**Maintenance Tools**](docs/Maintenance_Tools.md): Disk Cleanup, Windows/App Updates.
*   [**Security Tools**](docs/Security_Tools.md): Auditing, Firewalls, Port Scanning.
*   [**Monitoring Tools**](docs/Monitoring_Tools.md): Reports, Disk Space Alerts.
*   [**WSL Tools**](docs/WSL_Tools.md): Network fixes, VHDX shrinking.
*   [**Management Tools**](docs/Management_Tools.md): Startup App management.

---

### 🛡️ Safety First
*   **Auto-Elevation**: Scripts automatically request Admin privileges if needed via `Assert-Admin`.
*   **Standardized Naming**: All tools follow the `Verb-Noun.ps1` naming convention.

### 📊 Intelligent Reporting & Logging
*   **Centralized Logging**: All tools now log to `.\logs\Toolkit_YYYYMMDD.log` using a standardized `Write-Log` function.
*   **Standard Levels**: Logs use uniform levels (`INFO`, `SUCCESS`, `WARN`, `ERROR`, `DEBUG`) with color-coded console output.
*   **Before/After Scans**: Tools like `Invoke-DiskCleanup` and `Invoke-ShrinkWSL` report exactly how much space you reclaimed.

### 🧰 The Arsenal

| Category | Tools Included |
| :--- | :--- |
| **System Maintenance** | Disk Cleanup, Windows Updates, App Updates (Winget/Choco) |
| **Disk & Storage** | Disk Monitor, WSL VHDX Shrinker (with size reporting) |
| **Network Ops** | Active TCP Connections, Flush DNS, Ping Test, Public IP, WSL Network Repair |
| **System Health** | Event Log Analyzer (Top Errors), BSOD Minidump Checker, SFC/DISM |
| **Process Control** | Top CPU/Mem Hogs, Kill Process, Startup Apps Audit |
| **Security & Files** | Local User Audit, File Hash Checker, Large File Finder |

---

## 🗺️ Roadmap
We are constantly evolving! Here’s what’s next on the horizon:

### 🚀 Near-Term (v1.3 - Performance & UX)
*   **Parallel Patching**: Check for updates simultaneously across Winget and Chocolatey.
*   **Wider Progress Implementation**: Add `Write-Progress` to all long-running scans.
*   **Log Rotation**: Auto-compress logs older than 7 days and cleanup after 30 days.

### 🛡️ Mid-Term (v1.4 - Security Hardening)
*   **Admin Audit**: Automatically flag unauthorized members of the local `Administrators` group.
*   **Network Guard**: Identify suspicious outbound connections from system processes.
*   **File Integrity**: Monitor critical system folders for unauthorized hash changes.

### 🛠️ Long-Term (v2.0 - Extended Management)
*   **Driver Management**: Integrated hardware driver checking and updates.
*   **Automated Backups**: Scheduled backups for IIS, Task Scheduler, and Registry hives.
*   **Certificate Watcher**: Proactive alerts for expiring SSL/System certificates.

---

## 📜 Standardized Scripts
You can still run individual modules:

*   `Start-SysAdminToolbox.ps1` - **The Master Menu**
*   `Globals.ps1` - **Core Shared Logic**
*   `Invoke-DiskCleanup.ps1` - Clean temp files
*   `Invoke-MonitorDiskSpace.ps1` - Check drive space & alert
*   `Get-SystemReport.ps1` - Generate config reports
*   `Invoke-WindowsUpdate.ps1` - Manage Windows Updates
*   `Invoke-ShrinkWSL.ps1` - Optimize WSL disk usage
*   `Invoke-AppUpdate.ps1` - Update installed apps
*   `Invoke-WSLNetworkFix.ps1` - Repair WSL connectivity

## 📝 License
This project is licensed under the [WTFPL](LICENSE.md). Do what you want.

