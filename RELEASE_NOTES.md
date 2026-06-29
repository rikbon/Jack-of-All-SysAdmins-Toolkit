# Release Notes - v2.2.0

**Date**: 2026-06-29
**Codename**: "One-Click Anywhere"

## 🚀 Major Update: One-Click Installers & Install-Site Bug Fixes
This release turns the SysAdmin Toolbox from "run the launcher from the cloned repo" into a one-command install on both platforms — and fixes a load-path bug that let the dashboard start while silently broken on the installed path.

### ✨ New Features
*   **Linux one-liner installer** (`install.sh`): detects the distro via `/etc/os-release` (apt / dnf / yum / pacman / apk / zypper + their derivatives), installs **every** runtime dependency the kit needs (`util-linux`, `gawk`, `curl`, `iproute2`, `iputils-ping`, `coreutils`, `procps`), downloads the latest release (falls back to the `main` branch tarball if no release is published), and installs to `/opt/sysadmin-toolbox` with a `/usr/local/bin/sysadmin-toolbox` symlink.
*   **Windows one-liner installer** (`install.ps1`): sets the local execution policy, self-elevates to Administrator, bootstraps `PowerShellGet` + `PSWindowsUpdate` + `winget` + Chocolatey where they're missing, installs to `%ProgramFiles%\SysAdminToolbox`, adds the directory to the system PATH, and drops a Start-menu shortcut — so `sysadmin-toolbox` works from any PowerShell or Command Prompt.
*   **Release archive convention** (`build.ps1`): now emits both the classic `SysAdminToolbox_v2.2.0.zip` and the canonical `Jack-of-All-SysAdmins-Toolkit-windows.zip` / `-linux.tar.gz` assets that the one-liners curl/wget. Publishing all of them as GitHub Release assets lets the installers grab a proper release rather than the main-branch fallback.
*   **Linux "Last Logins" fallback chain** (`Linux/audit-users.sh`): the Security menu option "Show last 10 successful logins" no longer just prints `last: command not found` on minimal installs and containers. It now tries `last`, then `lastlog`, then `utmpdump /var/log/wtmp`, then a grep over `/var/log/auth.log` and `/var/log/secure`.
*   **README.md** gains a prominent **Install (one-liner)** section with the exact commands for both platforms and an explanation of what each does.

### 🛠️ Maintenance & Refactoring
*   Launcher version banners bumped to `v2.2.0` (`Linux/start-sysadmintoolbox.sh`, `Windows/Start-SysAdminToolbox.ps1`).
*   **README.md** top-of-file version badge updated to `2.2.0`.
*   Workspace-version strings in `Windows/build.ps1` bumped from `1.3.0` to `2.2.0`.

### 🐛 Bug Fixes
*   **`write_log: command not found` through the `/usr/local/bin/sysadmin-toolbox` symlink**: the launcher resolved `SCRIPT_DIR` from `${BASH_SOURCE[0]}` directly, which on the installer's symlink returned the symlink's *owner* dir (`/usr/local/bin`) instead of the launcher's real dir. `source globals.sh` then silently failed (the launcher doesn't `set -e`), leaving `write_log`, `assert_root`, and all colour codes undefined so any error path printed the literal `write_log: command not found`. The launcher now follows the symlink chain via `readlink` (no `realpath` dependency) before sourcing globals.

---

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
