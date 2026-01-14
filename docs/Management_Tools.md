# Management Tools

## 1. Startup App Manager
**Script**: `Manage-StartupApps.ps1`

### Description
Lists applications configured to start automatically with Windows.

### Scopes Checked
- Registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- Registry: `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
- Folder: `Shell:Startup`

### Usage
Run usage via `SysAdminToolbox.ps1` (Menu 6 -> 4). It allows you to select an entry and **delete** it to prevent it from starting.
