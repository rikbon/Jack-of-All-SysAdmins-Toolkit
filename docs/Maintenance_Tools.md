# Maintenance Tools

These tools are designed to keep the system clean and up-to-date.

## 1. Disk Cleanup
**Script**: `Invoke-DiskCleanup.ps1`

### Description
Cleans temporary files from standard locations (`%TEMP%`, `C:\Windows\Temp`, Prefetch).

### Usage
```powershell
.\Invoke-DiskCleanup.ps1
```
It returns a summary of the space claimed and logs results to the central log file.

---

## 2. Windows Update
**Script**: `Invoke-WindowsUpdate.ps1`

### Description
A wrapper around the `PSWindowsUpdate` module (installing it if missing). It scans for and installs pending Windows Updates.

### Parameters
- `AutoReboot`: (Optional) Automatically reboot if required.

---

## 3. Application Update (Winget & Chocolatey)
**Script**: `Invoke-AppUpdate.ps1`

### Description
Updates installed applications using **Winget** and **Chocolatey** (if installed).

### Key Features
- **Auto-Source Repair**: If Winget sources are corrupted (404 errors), it attempts to reset them.
- **Robust Iteration**: Updates packages one by one so a single failure doesn't stop the batch.
- **Shared Logging**: All progress and errors are recorded in the central `.\logs\Toolkit_YYYYMMDD.log`.
