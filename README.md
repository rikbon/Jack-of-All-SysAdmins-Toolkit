# 🛠️ The Jack-of-All-SysAdmins Toolkit

> *One script to rule them all, one script to find them, one script to bring them all and in the terminal bind them.*

Welcome to **The Jack-of-All-SysAdmins Toolkit**. This project is a unified, menu-driven PowerShell suite designed to handle the daily grind of system administration with style and safety.

## 🚀 Quick Start
Launch the master dashboard:
```powershell
.\SysAdminToolbox.ps1
```
*(Run as Administrator for full power)*

---

### 🛡️ Safety First
*   **Auto-Elevation**: Scripts automatically request Admin privileges if needed.


### 📊 Intelligent Reporting
*   **Before/After Scans**: Tools like `DiskCleanup` and `WSL Shrink` report exactly how much space you reclaimed.
*   **Logs**: All actions are logged to `%TEMP%` for audit trails.

### 🧰 The Arsenal

| Category | Tools Included |
| :--- | :--- |
| **System Maintenance** | Disk Cleanup, Windows Updates, App Updates (Winget) |
| **Disk & Storage** | Disk Monitor, WSL VHDX Shrinker (with size reporting) |
| **Network Ops** | Active TCP Connections, Flush DNS, Ping Test, Public IP, WSL Network Repair |
| **System Health** | Event Log Analyzer (Top Errors), BSOD Minidump Checker, SFC/DISM |
| **Process Control** | Top CPU/Mem Hogs, Kill Process, Startup Apps Audit |
| **Security & Files** | Local User Audit, File Hash Checker, Large File Finder |

---

## 📜 Standalone Scripts
You can still run individual modules if you prefer:

*   `SysAdminToolbox.ps1` - **The Master Menu**
*   `DiskCleanup.ps1` - Clean temp files (with reporting)
*   `Monitor-DiskSpace.ps1` - Check drive space & alert
*   `SystemInfoReport.ps1` - Generate config reports
*   `Update-Windows.ps1` - Manage Windows Updates
*   `shrink_wsl.ps1` - Optimize WSL disk usage
*   `update.ps1` - Update installed apps
*   `wslNetworkFix.ps1` - Repair WSL connectivity

## 📝 License
This project is licensed under the [WTFPL](LICENSE.md). Do what you want.

