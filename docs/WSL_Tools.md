# WSL Tools

Utilities specifically for managing Windows Subsystem for Linux (WSL).

## 1. WSL Network Fix
**Script**: `Invoke-WSLNetworkFix.ps1`

### Description
Fixes common WSL2 connectivity issues where the VM loses internet access.

### Actions
1.  Resets Windows Network Interfaces.
2.  Flushes DNS.
3.  Restarts the `LxssManager` (WSL Service).
4.  (Optional) Resets TCP/IP stack.

---

## 2. Shrink WSL Disk
**Script**: `Invoke-ShrinkWSL.ps1`

### Description
Reclaims disk space from WSL2 `.vhdx` virtual disk files. WSL disks grow dynamically but do not shrink automatically when files are deleted inside Linux.

### Actions
1.  Locates all `.vhdx` files for registered WSL distros.
2.  Terminates WSL (`wsl --shutdown`).
3.  Uses `diskpart` to compact the VHDX file, displaying a progress bar during the operation.
4.  Reports the size difference ("Space reclaimed").
