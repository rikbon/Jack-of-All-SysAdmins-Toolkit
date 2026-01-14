# Monitoring & Reporting Tools

Tools to inspect system state and generate reports.

## 1. Monitor Disk Space
**Script**: `Monitor-DiskSpace.ps1`

### Description
Checks the free space of local drives (C:, D:, etc.). If space is below a threshold (default 10%), it can send an alert email.

### Configuration
Edit the script variables `$SmtpServer`, `$FromAddress`, and `$ToAddress` to enable email alerting.

---

## 2. System Information Report
**Script**: `SystemInfoReport.ps1`

### Description
Generates a comprehensive system report including:
- OS Version
- CPU/RAM details
- Network details (IP, MAC)
- Disk usage

### Output
Saves a text report to the current directory or specified path.
