# macOS Tools

The `macOS/` directory contains native Bash tools for macOS system administration.
The tool surface mirrors the Linux one file for file: `audit-users.sh`,
`cleanup.sh`, `manage-firewall.sh`, `manage-services.sh`, `monitor-disk.sh`,
`network-tools.sh`, `process-monitor.sh`, `get-sysreport.sh` and `update-system.sh`
exist on both platforms, so an operator moving between them finds the same names.

All tools use the shared logging functions in `macOS/globals.sh`, which sources the
option helpers from `macOS/cli.sh`, and write to `logs/Toolkit_YYYYMMDD.log`.

Every tool accepts `--help` (`-h`) and `--quiet` (`-q`). `--quiet` silences the
console only: the log file always keeps the full audit trail. Unknown options
exit with status `2`.

Tools that touch privileged state (`cleanup.sh`, `manage-firewall.sh`,
`update-system.sh`, and the two write operations of `manage-services.sh`) require
root. The launcher itself does not assert root so the read-only tools stay
usable by an unprivileged operator.

## Main launcher

```bash
bash ./macOS/start-sysadmintoolbox.sh
```

Seven categories, matching the Linux launcher:

1. System Maintenance (cleanup, updates)
2. Disk & Storage (monitor space)
3. Network Utility
4. Service Utility
5. System Health & Troubleshooting
6. Process & Performance
7. Security & File Utilities (user audit, firewall)

## Diagnostics

### `get-sysreport.sh`

Reports:

- macOS product and build versions.
- Kernel, computer name, and uptime.
- Hardware model information.
- CPU core count and installed memory.
- Mounted volume usage.

```bash
bash ./macOS/get-sysreport.sh --report
```

### `monitor-disk.sh`

Checks mounted volumes with `df` and logs a warning for volumes at or above `DISK_THRESHOLD` percent. The default threshold is 85%.

```bash
DISK_THRESHOLD=90 bash ./macOS/monitor-disk.sh --check
```

### `network-tools.sh`

Provides interactive access to:

- Network interface information (`--interfaces`).
- Listening TCP sockets (`--listening`).
- Public IP lookup (`--public-ip`).
- Connectivity testing against `1.1.1.1` (`--ping`).

### `process-monitor.sh`

Displays top processes by memory (`--memory`) or CPU (`--cpu`) and can send a
normal `TERM` signal to a selected process (`--terminate PID`) after explicit
confirmation. It does not use forced `KILL` termination.

## Management

### `manage-services.sh`

Uses native `launchctl` commands to list loaded services and start, stop, or
restart a selected service label. Mutating actions require interactive
confirmation, and labels are restricted to safe launchd identifier characters.

```bash
bash ./macOS/manage-services.sh --list
bash ./macOS/manage-services.sh --restart com.apple.smbd
```

### `update-system.sh`

Covers both package managers macOS actually has: Homebrew and the OS updater.

- `--update` runs a full update (Homebrew packages, then macOS software updates).
- `--list` lists outdated Homebrew packages and available OS updates.
- `--upgrade` upgrades Homebrew packages only.

```bash
bash ./macOS/update-system.sh --list
bash ./macOS/update-system.sh --upgrade
```

Homebrew is detected, never installed: the tool probes `PATH`, then
`/opt/homebrew/bin/brew`, then `/usr/local/bin/brew`, and reports clearly when it
is absent. The upgrade modes stay interactive so package changes cannot happen
accidentally from a background invocation.

### `cleanup.sh`

Six steps, each logged and individually failure-tolerant:

1. `brew cleanup -s` (cache, stale versions and downloads).
2. Purge the Homebrew download cache entries older than a week.
3. Thin Time Machine *local* snapshots with `tmutil thinlocalsnapshots`.
4. Delete rotated log archives (`*.gz`, `*.bz2`, `*.1`) older than a week.
5. Clear user caches and logs older than a week.
6. Clear per-user temporary files older than two days.

Safety notes: Apple and on-demand snapshots are left alone because removing them
can break restores; the currently-written `/var/log/*.log` files are never
deleted; and the caches removed are only well-known rebuildable ones.

## Security

### `audit-users.sh`

- `--privileged` lists the members of the `admin` group via `dscl`, plus any
  account holding `uid 0` that is not in that group (a root account hiding
  outside `admin` is still a full compromise).
- `--empty-passwords` scans each real account for an empty password attribute.
- `--logins` shows the last 10 logins, falling back to `who` and then to the
  unified log when `last` is unavailable.

### `manage-firewall.sh`

macOS filters by application bundle, not by port, so this tool drives both
mechanisms:

- `--status` reports the `socketfilterfw` global state and the `pf` ruleset.
- `--list` prints the application firewall lists and the active `pf` rules.
- `--allow PORT` / `--block PORT` append a `pf` rule to `/etc/pf.conf` after
  confirmation, loading it with `pfctl -e`.

Duplicate rules are not appended twice, and every mutation requires an explicit
`y`. Port numbers are validated through the shared `valid_port` helper.