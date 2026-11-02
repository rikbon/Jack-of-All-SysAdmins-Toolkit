# macOS Tools

Native macOS administration tools for the Jack-of-All-SysAdmins Toolkit.

## Quick start

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

## Tools

The file names match the Linux platform one for one, so the same mental model
applies on both:

- `get-sysreport.sh`: Collects macOS version, hardware, uptime, memory, and storage information.
- `monitor-disk.sh`: Reports mounted volume usage and warns above the configured threshold.
- `network-tools.sh`: Shows interfaces, listening sockets, public IP, and connectivity.
- `process-monitor.sh`: Shows top processes and can send a normal termination signal after confirmation.
- `manage-services.sh`: Lists loaded launchd services and controls a selected service after confirmation.
- `cleanup.sh`: Cleans Homebrew caches, thins Time Machine local snapshots, and trims logs, caches and temp files.
- `update-system.sh`: Updates Homebrew packages and installs macOS software updates, after confirmation.
- `audit-users.sh`: Lists admin and `uid 0` accounts, checks for empty passwords, and shows recent logins.
- `manage-firewall.sh`: Reports the application firewall and manages `pf` port rules.
- `globals.sh`: Shared logging, command checks, input validation, and menu helpers.
- `cli.sh`: Shared `--help` / `--quiet` option parsing.

## Privileges

Diagnostics do not need administrator rights. `cleanup.sh`,
`manage-firewall.sh` and `update-system.sh` do, and say so on startup.

## Options

Every tool accepts `--help` (`-h`) and `--quiet` (`-q`). `--quiet` silences the
console but keeps the audit trail in `logs/Toolkit_YYYYMMDD.log`.

See `docs/macOS_Tools.md` for the full reference.