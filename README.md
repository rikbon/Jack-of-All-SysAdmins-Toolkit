# Jack-of-All-SysAdmins Toolkit

![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue)
![Shell](https://img.shields.io/badge/Shell-PowerShell%20%7C%20Bash-green)
![License](https://img.shields.io/badge/License-MIT-success)

**Version:** 2.2.0

## Overview
The Jack-of-All-SysAdmins Toolkit is a unified, menu-driven utility suite designed to streamline routine system administration tasks across both Windows (PowerShell) and Linux (Bash) environments. It emphasizes safety, standardized logging, and operational efficiency.

## Install (one-liner)

Both platforms ship a self-contained bootstrapper that installs the toolkit
`to a fixed location, adds it to your PATH, and installs every runtime
dependency the dashboard scripts need. After install, launch the dashboard
with `sysadmin-toolbox`.

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.sh | sudo bash
```

…or, with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.sh | sudo bash
```

#### What the Linux installer does

1. **Detects your distro** via `/etc/os-release`
   (Debian/Ubuntu, Fedora/CentOS/RHEL, Arch, Alpine, openSUSE and their
   derivatives — falls back to apt/dnf/yum/pacman/apk/zypper in that order).
2. **Installs every runtime dependency** the toolkit scripts need:
   - `util-linux` for `last` / `utmpdump` / `lastlog`,
   - `gawk` for `awk`,
   - `curl`,
   - `iproute2` for `ss`,
   - `iputils` for `ping`,
   - plus baseline `coreutils` / `procps`.
3. **Downloads the latest release** (falling back to the `main` branch
   tarball if no release is published yet) and installs it to
   `/opt/sysadmin-toolbox`.
4. **Symlinks the launcher** to `/usr/local/bin/sysadmin-toolbox`, so
   `sysadmin-toolbox` launches the dashboard from any shell.

> The scripts also use distro managers (`apt`, `dnf`, `pacman`, …) and
> Docker directly — these are part of the OS and aren't reinstalled.

### Windows (PowerShell)

Run from an **Administrator** PowerShell (5.1 or 7+):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force; iex "& { $(irm https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.ps1) }"
```

#### What the Windows installer does

1. **Sets the local execution policy** and **auto-elevates to Administrator**.
2. **Installs every runtime dependency**:
   - `PowerShellGet` (needed to install Windows-update support),
   - the `PSWindowsUpdate` PowerShell module, used by the Windows Update dashboard,
   - `winget` via the Microsoft Store App Installer bundle,
   - `Chocolatey` (optional, used by a few toolkit features).
3. **Downloads the latest release** (falling back to the `main` branch archive
   if no release is published yet) and installs it to
   `%ProgramFiles%\SysAdminToolbox`.
4. **Adds the directory to your system PATH** and drops a **Start-menu
   shortcut** so you can launch the dashboard with:
   - `Start Menu → "SysAdminToolbox"`, or
   - `sysadmin-toolbox` from any PowerShell/Command Prompt, or
   - `Start-SysAdminToolbox.ps1` from PowerShell.

## Uninstall

When you're done, a single one-liner per platform removes everything the
installer put in place: the on-disk installation, the `sysadmin-toolbox` launcher, and (on Windows) the Start-menu shortcut and PATH entry.

*The uninstall scripts **do not** remove the runtime dependencies the installer
pulled in (`util-linux`, `curl`, `iproute2`, … on Linux; `PSWindowsUpdate`,
`winget`, Chocolatey on Windows). Those are shared system packages — removing
them could break other software. The uninstall only touches the sysadmin-toolbox
directories, links, and shortcuts the installer created.*

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.sh | sudo bash
```

What `uninstall.sh` does:

1. Removes the `/usr/local/bin/sysadmin-toolbox` launcher symlink.
2. Removes the entire `/opt/sysadmin-toolbox` installation directory.
3. Leaves `/opt/sysadmin-toolbox/logs` **in place by default** so you can keep
   your historical logs — pass ` PURGE_LOGS=1` to delete them too:
   ```bash
   PURGE_LOGS=1 sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.sh)"
   ```

### Windows (PowerShell)

Run from an **Administrator** PowerShell (5.1 or 7+):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force; iex "& { $(irm https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.ps1) }"
```

What `uninstall.ps1` does:

1. Removes the Start-menu shortcut (`%ProgramData%\Microsoft\Windows\Start Menu\Programs\SysAdminToolbox.lnk`).
2. Removes the toolkit directory from the system `PATH`.
3. Renames `%ProgramFiles%\SysAdminToolbox` to a timestamped backup
   (`%ProgramFiles%\SysAdminToolbox_uninstall_<timestamp>`) instead of
   immediately deleting it, so you can recover any local edits you made.
   The installer re-creates a clean install if you run it again afterwards.
4. The log directory inside the renamed backup is preserved
   — you can delete the backup manually when you're ready.

## Quick Start (manual, no installer)

If you'd rather not use the bootstrapper, you can launch the dashboard
directly from the cloned repo:

### Windows (PowerShell)
```powershell
.\Windows\Start-SysAdminToolbox.ps1
```
*(Requires Administrator privileges)*

### Linux (Bash)
```bash
sudo bash ./Linux/start-sysadmintoolbox.sh
```
*(Requires root privileges via sudo)*

---

## Documentation

Detailed documentation for all modules and commands is available in the `docs/` directory:

* [Main Toolbox Interface](docs/SysAdminToolbox.md)
* [Linux Tools](docs/Linux_Tools.md)
* [Windows - Maintenance Tools](docs/Maintenance_Tools.md)
* [Windows - Security Tools](docs/Security_Tools.md)
* [Windows - Monitoring Tools](docs/Monitoring_Tools.md)
* [Windows - WSL Tools](docs/WSL_Tools.md)
* [Windows - Management Tools](docs/Management_Tools.md)

---

## Directory Structure

* `Windows/`: Contains all PowerShell (`.ps1`) scripts and the Windows TUI launcher.
* `Linux/`: Contains all Bash (`.sh`) scripts and the Linux TUI launcher.
* `docs/`: Contains comprehensive markdown documentation for all utilities.
* `logs/`: Centralized log directory where all scripts output uniform logs (`Toolkit_YYYYMMDD.log`).

---

## Core Principles
* **Auto-Elevation**: Scripts automatically request the necessary permissions (Administrator on Windows, root on Linux) prior to execution.
* **Standardized Logging**: All tools utilize a unified logging function to output events to a central log file with uniform severity levels (INFO, SUCCESS, WARN, ERROR, DEBUG).

---

## License
This project is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.
