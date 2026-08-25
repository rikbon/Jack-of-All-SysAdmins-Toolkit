# Jack-of-All-SysAdmins Toolkit

![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![Shell](https://img.shields.io/badge/Shell-PowerShell%20%7C%20Bash-green)
![License](https://img.shields.io/badge/License-MIT-success)

**Version:** See [`VERSION`](VERSION)

## Overview
The Jack-of-All-SysAdmins Toolkit is a unified, menu-driven utility suite designed to streamline routine system administration tasks across Windows (PowerShell), Linux (Bash), and macOS (Bash) environments. It emphasizes safety, standardized logging, and operational efficiency.

## Quick Start

Launch the main dashboard for your respective environment:

### Windows (PowerShell)
```powershell
.\Windows\Start-SysAdminToolbox.ps1
```
*(Note: Requires Administrator privileges)*

### Linux (Bash)
```bash
sudo bash ./Linux/start-sysadmintoolbox.sh
```
*(Note: Requires root privileges via sudo)*

### macOS (Bash)
```bash
bash ./macOS/start-sysadmintoolbox.sh
```
*(The initial macOS tools are non-destructive diagnostics.)*

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
* [macOS Tools](docs/macOS_Tools.md)
* [Build and Packaging](docs/Build.md)

---

## Directory Structure

* `Windows/`: Contains all PowerShell (`.ps1`) scripts and the Windows TUI launcher.
* `Linux/`: Contains all Bash (`.sh`) scripts and the Linux TUI launcher.
* `macOS/`: Contains native macOS Bash scripts and the macOS TUI launcher.
* `docs/`: Contains comprehensive markdown documentation for all utilities.
* `logs/`: Centralized log directory where all scripts output uniform logs (`Toolkit_YYYYMMDD.log`).

---

## Core Principles
* **Auto-Elevation**: Scripts automatically request the necessary permissions (Administrator on Windows, root on Linux) prior to execution.
* **Standardized Logging**: All tools utilize a unified logging function to output events to a central log file with uniform severity levels (INFO, SUCCESS, WARN, ERROR, DEBUG).

---

## License
This project is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.
