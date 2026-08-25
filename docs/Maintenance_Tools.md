# Maintenance Tools

These tools are designed to keep the system clean and up-to-date.

## 1. Disk Cleanup
**Script**: `Invoke-DiskCleanup.ps1`

### Description
Safely cleans the contents of standard temporary locations without deleting the directories themselves. Locked files are skipped and failures are logged. The default cleanup includes:

- Current-user temporary files.
- `C:\Windows\Temp`.
- Current-user Internet cache.
- Explorer thumbnail and icon cache.

Recycle Bin cleanup and Windows Update download-cache cleanup are opt-in because they have broader impact. Windows Cleanup Manager can also be launched in the background.

### Usage
```powershell
.\Invoke-DiskCleanup.ps1
```

Preview changes without deleting anything:

```powershell
.\Invoke-DiskCleanup.ps1 -WhatIf
```

Include the current user's Recycle Bin:

```powershell
.\Invoke-DiskCleanup.ps1 -IncludeRecycleBin
```

Include the Windows Update download cache:

```powershell
.\Invoke-DiskCleanup.ps1 -IncludeWindowsUpdateCache
```

Launch Windows Cleanup Manager in the background after the toolkit cleanup:

```powershell
.\Invoke-DiskCleanup.ps1 -LaunchWindowsCleanup
```

The script requires Administrator privileges, logs skipped locked files, and supports PowerShell's standard `-WhatIf` and `-Confirm` safeguards.

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
- **Parallel Scanning**: Uses PowerShell background jobs to check for Winget and Chocolatey updates simultaneously, speeding up the initial evaluation phase.
- **Auto-Source Repair**: If Winget sources are corrupted (404 errors), it attempts to reset them.
- **Robust Iteration**: Updates packages one by one so a single failure doesn't stop the batch.
- **Shared Logging**: All progress and errors are recorded in the central `.\logs\Toolkit_YYYYMMDD.log`.
