# macOS Tools

The `macOS/` directory contains native Bash tools for macOS system diagnostics. The initial implementation is non-destructive and does not require administrator privileges for its diagnostic commands.

All tools use the shared logging functions in `macOS/globals.sh` and write to `logs/Toolkit_YYYYMMDD.log`.

## Main launcher

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

The launcher provides access to system reports, disk monitoring, network diagnostics, and process monitoring.

## Utilities

### `get-sysreport.sh`

Reports:

- macOS product and build versions.
- Kernel, computer name, and uptime.
- Hardware model information.
- CPU core count and installed memory.
- Mounted volume usage.

### `monitor-disk.sh`

Checks mounted volumes with `df` and logs a warning for volumes at or above `DISK_THRESHOLD` percent. The default threshold is 85%.

Example:

```bash
DISK_THRESHOLD=90 bash ./macOS/monitor-disk.sh
```

### `network-tools.sh`

Provides interactive access to:

- Network interface information.
- Listening TCP sockets.
- Public IP lookup.
- Connectivity testing against `1.1.1.1`.

### `process-monitor.sh`

Displays top processes by memory or CPU and can send a normal `TERM` signal to a selected process after explicit confirmation. It does not use forced `KILL` termination.

### `manage-services.sh`

Uses native `launchctl` commands to list loaded services and start, stop, or restart a selected service label. Mutating actions require interactive confirmation, and labels are restricted to safe launchd identifier characters.

### `manage-homebrew.sh`

Detects an existing Homebrew installation without installing it. It can list outdated packages non-destructively or upgrade all packages after explicit confirmation.

```bash
bash ./macOS/manage-homebrew.sh --list
bash ./macOS/manage-homebrew.sh --upgrade
```

The upgrade mode is intentionally interactive so package changes cannot happen accidentally from a background invocation.

Read-only listing:

```bash
bash ./macOS/manage-services.sh --list
```

## Planned additions

Future macOS work will add service management through `launchctl`, Homebrew update support, maintenance tools, and user/security audits after their command behavior and safety boundaries are defined.
