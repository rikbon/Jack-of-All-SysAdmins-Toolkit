# Release Notes - v1.0.0

**Date**: 2026-01-14
**Codename**: "The Jack-of-All-SysAdmins"

## 🚀 Major Release: Full Feature Set
This release marks the transition of the SysAdmin Toolbox into a complete management suite. It introduces significant capabilities in security, auditing, and maintenance.

### ✨ New Features
#### 🔒 Security & Hardening
*   **Port Scanner** (`Test-PortScan.ps1`): Lightning-fast TCP port scanner to check for open services.
*   **Firewall Manager** (`Manage-FirewallRules.ps1`): Interactive tool to list blocking rules, search, and block applications.
*   **User Auditing** (`Audit-UserActivity.ps1`): Track user logon and logoff events directly from the Security Log.

#### 🛠️ Maintenance & management
*   **Log Archiving** (`Archive-EventLogs.ps1`): Exports System, Application, and Security logs to compressed `.zip` archives. Includes robust retry logic for locked files.
*   **Startup App Manager** (`Manage-StartupApps.ps1`): Review and delete startup items from both Registry and Startup folders.
*   **Robust App Updater** (`update.ps1`):
    *   Iterative updates (failures on one app don't stop the rest).
    *   Auto-repair for Winget 404/Source corruption errors.
    *   Chocolatey support added.

#### 🖥️ System Health
*   **BSOD Analysis**: Now correlates Minidumps with Event Logs to show "BugCheck" error codes immediately. Added option to delete old dumps.

### 📚 Documentation
*   Added `docs/` folder with detailed Markdown guides for every module.
*   Added `build.ps1` for generating distribution ZIP files.

### 💥 Breaking Changes
*   **Removed "DryRun" / "WhatIf" Mode**: All scripts now execute actions immediately. The simulation mode was removed to simplify logic and ensuring consistent behavior.

### 🐛 Bug Fixes
*   Fixed file locking issues when compressing Event Logs.
*   Fixed Winget 404 errors by implementing auto-source reset.
