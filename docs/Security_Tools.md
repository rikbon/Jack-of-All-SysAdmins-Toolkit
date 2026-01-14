# Security & Auditing Tools

Tools to harden the system and audit usage.

## 1. Audit User Activity
**Script**: `Audit-UserActivity.ps1`

### Description
Scans the Windows Security Event Log for Logon (4624) and Logoff (4634) events to track user sessions.

### Parameters
- `Days`: Number of past days to scan (Default: 1).
- `UserName`: Filter by specific username.

---

## 2. Archive Event Logs
**Script**: `Archive-EventLogs.ps1`

### Description
Exports `Application`, `System`, and `Security` event logs to `.evtx` files and compresses them into a ZIP archive.

### Features
- **File Locking Handling**: Includes retry logic to handle cases where logs are in use.
- **Log Clearing**: Optional switch (`-ClearLogs`) to wipe logs after successful backup.

---

## 3. Port Scanner
**Script**: `Test-PortScan.ps1`

### Description
A fast TCP port scanner. Checks if common ports (SSH, HTTP, RDP, SMB, etc.) are open on a target.

### Parameters
- `Target`: Host to scan (Default: `localhost`).

---

## 4. Firewall Rule Manager
**Script**: `Manage-FirewallRules.ps1`

### Description
A simplified interface for Windows Firewall.
- **List**: Shows active blocking rules.
- **Block App**: Easily creates a rule to block a specific `.exe` from accessing the network.
- **Search**: Search rules by name.
