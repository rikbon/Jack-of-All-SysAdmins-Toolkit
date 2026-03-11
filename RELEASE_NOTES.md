# Release Notes - v1.3.0

**Date**: 2026-03-11
**Codename**: "The Parallel Patch & Polish"

## 🚀 Major Update: Performance & UX
This release focuses on significantly speeding up application updating scans and managing long-term toolkit artifact accumulation.

### ✨ New Features
*   **Parallel Patching** (`Invoke-AppUpdate.ps1`): Checking for updates is now handled simultaneously across both Winget and Chocolatey via background jobs, reducing time spent scanning.
*   **Log Rotation** (`Invoke-LogRotation.ps1`): A new tool to auto-compress logs older than 7 days and delete logs/archives older than 30 days. Added to the main menu under Logging & Auditing.

### 🛠️ Maintenance & Refactoring
*   **Progress Tracking**: Wider implementation of `Write-Progress` on existing maintenance tools to provide richer visual feedback.
*   **Dashboard Update**: Main dashboard `Start-SysAdminToolbox.ps1` version bumped to 1.3.0.

---

# Release Notes - v1.2.1

**Date**: 2026-03-11
**Codename**: "The Standardized SysAdmin"

## 🚀 Major Update: Standardization & Safety
This release focuses on centralizing core logic, standardizing naming conventions, and improving visual feedback for long-running operations.

### ✨ New Features
*   **Centralized Globals** (`Globals.ps1`): All scripts now share a common logging system and administrative privilege check.
*   **Progress Indicators**: Added `Write-Progress` bars to `Invoke-DiskCleanup` and `Invoke-PortScan` for better user feedback.
*   **Standardized Logging**: All operations are now logged to `.\logs\Toolkit_YYYYMMDD.log` with severity levels.

### 🛠️ Maintenance & Refactoring
*   **Naming Convention**: Renamed all scripts to follow PowerShell `Verb-Noun` standards (e.g., `shrink_wsl.ps1` -> `Invoke-ShrinkWSL.ps1`).
*   **Admin Enforcement**: Replaced custom elevation checks with a shared `Assert-Admin` function.
*   **Path Resolution**: Improved script calling logic using `$PSScriptRoot`.

### 🐛 Bug Fixes
*   Fixed `$args` collision in `Invoke-AppUpdate.ps1`.
*   Fixed inconsistent log formats across modules.
*   Updated main terminal menu to correctly reference renamed scripts.

---

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
