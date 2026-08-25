# macOS Tools

Native macOS administration tools for the Jack-of-All-SysAdmins Toolkit.

## Quick start

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

The initial macOS section is intentionally non-destructive. It provides system, disk,
network, process, and hardware diagnostics without requiring administrator privileges.

## Tools

- `get-sysreport.sh`: Collects macOS version, hardware, uptime, memory, and storage information.
- `monitor-disk.sh`: Reports mounted volume usage and warns above the configured threshold.
- `network-tools.sh`: Shows interfaces, listening sockets, public IP, and connectivity.
- `process-monitor.sh`: Shows top processes and can send a normal termination signal after confirmation.
- `manage-services.sh`: Lists loaded launchd services and controls a selected service after confirmation.
- `manage-homebrew.sh`: Lists outdated Homebrew packages and upgrades them only after confirmation.
- `globals.sh`: Shared logging, command checks, input validation, and menu helpers.
