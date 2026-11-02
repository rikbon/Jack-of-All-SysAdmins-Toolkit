# Release Notes - v2.5.1

**Date**: 2026-09-30
**Codename**: "The Clean Bill of Health"

## Bug Fixes

* **Installers were unusable**: `install.sh` and `uninstall.sh` were stored with
  CRLF line endings, so `bash` rejected them with
  `set: pipefail\r: invalid option name`. Added `.gitattributes` and normalized
  every text file to LF; the validation suite now fails on CRLF shell scripts.
* **Validation always failed**: a `trap ... RETURN` in `validate.sh` fired in the
  caller's scope, where its variable no longer existed, so the script exited `1`
  even when every check passed.
* **Interactive menus could die**: `set -Eeuo pipefail` plus the `ERR` trap
  aborted the whole TUI when a diagnostic command returned non-zero (a `grep`
  with no matches, killing a PID owned by another user). Added a `try` helper
  and applied it across the Linux and macOS tools.
* **Wrong exit codes logged**: both launchers read `$?` after `if ... fi`, which
  always yields `0`. Failures were always reported as `failed (exit code: 0)`.
* **PowerShell 7 incompatibility**: the launcher used `Get-EventLog`, which was
  removed in PowerShell 7. Replaced with `Get-WinEvent`.
* **`--quiet` silenced the audit trail**: it suppressed the log file as well as
  the console. It now silences the console only.
* **Linux one-liner install fell back to source**: `build.sh` did not produce
  `Jack-of-All-SysAdmins-Toolkit-linux.tar.gz`, the asset `install.sh` downloads,
  so the installer always unpacked the whole GitHub repository.
* **Unknown options crashed instead of printing usage**: `cli_usage_error` returns
  `2` by design, and under `set -e` that return value tripped the `ERR` trap, so
  every tool logged `Unexpected failure` and exited `1` instead of `2`.
* **`--help` could fail on some platforms**: `macOS/manage-services.sh` and
  `macOS/update-system.sh` probed for `launchctl` / Homebrew before parsing
  arguments, so `--help` reported a missing command or a missing install first.

## Improvements

* Added a GitHub Actions workflow running the validation suite on Ubuntu, macOS,
  and Windows, plus a job that rejects CRLF shell scripts.
* Extended validation to root-level and test shell scripts, added a `shellcheck`
  pass, and added an archive-layout check for the canonical installer assets.
* Replaced grep-based tests with behavioural tests of the shared helpers, and
  added regression tests for the exit-code and `--quiet` bugs.
* Extracted `Linux/cli.sh` so Linux and macOS expose the same CLI helper surface.
* `Invoke-AppUpdate.ps1` no longer invokes winget twice, and `SkipPackages` is
  now matched literally instead of as a regular expression.
* Process termination on Windows now validates the PID and asks for confirmation.
* `audit-users.sh` lists privileged group *members* and reports empty-password
  accounts individually; `manage-services.sh` validates service names and
  requires confirmation.
* Documented the validation suite and CI in `README.md` and `docs/Build.md`.

## macOS parity with Linux

The macOS toolkit was diagnostics-only. It now exposes the same tool surface as
Linux, with native implementations:

* **`audit-users.sh`** (new): lists `admin` group members and any account holding
  `uid 0`, checks for empty password attributes, and shows recent logins with
  `last`, `who`, and the unified log as fallbacks.
* **`cleanup.sh`** (new): `brew cleanup -s`, Homebrew download-cache purge,
  Time Machine *local* snapshot thinning, rotated log removal, user cache
  clearing, and per-user temp cleanup.
* **`manage-firewall.sh`** (new): reports `socketfilterfw` and `pf` state, lists
  rules, and manages `pf` port rules with confirmation and de-duplication.
* **`update-system.sh`** (new): covers Homebrew packages and macOS software
  updates with `--update`, `--list`, and `--upgrade` modes.
* **`manage-homebrew.sh` removed**: its behaviour is now `update-system.sh`, so
  the file names match Linux one for one. Existing invocations must be updated.

Both platforms now also share the `--quiet` flag, the `assert_root` helper,
`read -r -p` prompts, and the same seven-category launcher. Root is asserted per
tool on macOS instead of globally, keeping the diagnostic tools usable without
`sudo`.

---

# Release Notes - v2.5.0

**Date**: 2026-09-01

## v2.5.0

* Added native macOS diagnostics, service management, and Homebrew tooling.
* Added unified Windows, Linux, and macOS packaging.
* Added centralized version metadata and cross-platform validation.
* Improved command safety, error handling, cleanup safeguards, and CLI help.

# Release Notes - v2.2.1

**Date**: 2026-06-29
**Codename**: "One-Click In, One-Click Out"

## Update: one-click Uninstall for both platforms
Adds an uninstall workflow to match the v2.2.0 install workflow, so the
entire lifecycle of the SysAdmin Toolbox is a one-liner: install and remove.

### New Features
* **Linux one-liner uninstaller** (`uninstall.sh`): fetches itself just like
  `install.sh`. Removes the launcher symlink and installation directory while
  preserving logs by default.
* **Windows one-liner uninstaller** (`uninstall.ps1`): self-elevating, removes
  the Start-menu shortcut and toolkit PATH entry, then renames the installation
  directory to a timestamped backup.
* **README.md** documents the exact one-liners and shared dependencies that are
  intentionally not removed.

### Maintenance & Refactoring
* Version metadata is maintained centrally in `VERSION`.

---

# Release Notes - v2.2.0

**Date**: 2026-06-29
**Codename**: "One-Click Anywhere"

## Major Update: One-Click Installers & Install-Site Bug Fixes
This release turns the SysAdmin Toolbox into a one-command install on both
platforms and fixes the installed-path load bug.

### New Features
* **Linux one-liner installer** (`install.sh`) detects the distro, installs
  runtime dependencies, downloads the release, and creates the launcher.
* **Windows one-liner installer** (`install.ps1`) installs dependencies, adds
  the system PATH entry, and creates a Start-menu shortcut.
* **Release archive convention** (`build.ps1`) emits canonical Windows and
  Linux assets alongside the classic Windows archive.
* **Linux Last Logins fallback chain** (`Linux/audit-users.sh`) tries `last`,
  `lastlog`, `utmpdump`, and authentication logs.
* **README.md** documents the one-liner installers.

### Bug Fixes
* The Linux launcher follows symlinks before sourcing `globals.sh`.

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
