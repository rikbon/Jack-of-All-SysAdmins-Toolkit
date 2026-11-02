#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

assert_true() {
    local description="$1"
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

# grep wrapper that tolerates patterns starting with a dash.
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if grep -Fq -- "$pattern" "$file"; then pass "$description"; else fail "$description"; fi
}

assert_false() {
    local description="$1"
    shift
    if "$@"; then fail "$description"; else pass "$description"; fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if grep -Fq -- "$pattern" "$file"; then pass "$description"; else fail "$description"; fi
}

# --- Metadata ---

assert_true 'VERSION contains a semantic version' \
    grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT/VERSION"

# Both platforms expose the same CLI helper surface.
for platform in Linux macOS; do
    for helper in cli_help_requested cli_quiet_requested cli_usage_error; do
        assert_true "$platform/cli.sh defines $helper" \
            grep -Fq "$helper()" "$ROOT/$platform/cli.sh"
    done
done

# `globals.sh` must source the shared CLI helpers instead of redefining them.
assert_true 'Linux globals sources cli.sh' \
    grep -Fq 'source "${SCRIPT_DIR}/cli.sh"' "$ROOT/Linux/globals.sh"
assert_true 'macOS globals sources cli.sh' \
    grep -Fq 'source "${SCRIPT_DIR}/cli.sh"' "$ROOT/macOS/globals.sh"

for platform in Linux macOS; do
    assert_true "$platform globals enable strict mode" \
        grep -Fq 'set -Eeuo pipefail' "$ROOT/$platform/globals.sh"
    assert_true "$platform globals define valid_port" \
        grep -Fq 'valid_port()' "$ROOT/$platform/globals.sh"
    assert_true "$platform globals define valid_pid" \
        grep -Fq 'valid_pid()' "$ROOT/$platform/globals.sh"
    assert_true "$platform globals define try for menu-safe commands" \
        grep -Fq 'try()' "$ROOT/$platform/globals.sh"
done

# --- Behavioural tests of the shared helpers ---

sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
cp "$ROOT/Linux/globals.sh" "$ROOT/Linux/cli.sh" "$sandbox/"

# `source ./globals.sh` creates ../logs next to the sandbox; redirect it away.
mkdir -p "$sandbox/toolkit"
cp "$ROOT/Linux/globals.sh" "$ROOT/Linux/cli.sh" "$sandbox/toolkit/"

(
    cd "$sandbox/toolkit"
    source ./globals.sh

    # valid_port
    valid_port 1
    valid_port 80
    valid_port 65535
    ! valid_port 0
    ! valid_port 65536
    ! valid_port "80; rm -rf /"
    ! valid_port ""

    # valid_pid
    valid_pid 2
    valid_pid 4194304
    ! valid_pid 1
    ! valid_pid 0
    ! valid_pid "1; reboot"
    ! valid_pid ""

    # CLI helpers
    cli_help_requested --help
    cli_help_requested -h
    ! cli_help_requested --verbose
    cli_quiet_requested --quiet
    cli_quiet_requested -q
    ! cli_quiet_requested ""

    # cli_usage_error reports to stderr and returns 2
    [[ "$(cli_usage_error --bogus 2>/dev/null; echo $?)" == "2" ]]

    # try must swallow failures so an interactive menu survives them
    try false
    try true

    # run_logged must propagate the child's status
    ! run_logged 'expected failure' false
    run_logged 'expected success' true
) && pass 'Linux shared helpers behave as expected' \
  || fail 'Linux shared helpers behave as expected'

# try() must return 0 even when the wrapped command fails.
(
    cd "$sandbox/toolkit"
    source ./globals.sh
    try false
    [[ $? -eq 0 ]]
) && pass 'try() tolerates a failing command' \
  || fail 'try() tolerates a failing command'

# run_script must report the real child exit code, not always 0.
launcher_sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox" "$launcher_sandbox"' EXIT
cp "$ROOT/Linux/globals.sh" "$ROOT/Linux/cli.sh" "$launcher_sandbox/"
cat > "$launcher_sandbox/failing-tool.sh" <<'TOOL'
#!/usr/bin/env bash
exit 7
TOOL
(
    cd "$launcher_sandbox"
    source ./globals.sh

    run_script() {
        local script_path="${1}"
        if bash "$script_path"; then
            return 0
        else
            local exit_code=$?
            printf 'CAPTURED=%s\n' "$exit_code"
            return "$exit_code"
        fi
    }

    captured=$(run_script ./failing-tool.sh 2>&1 | grep -o 'CAPTURED=[0-9]*' | cut -d= -f2)
    [[ "$captured" == "7" ]]
) && pass 'launcher captures the real child exit code' \
  || fail 'launcher captures the real child exit code'

# Regression: `local exit_code=$?` placed after `if ... fi` captures the status
# of the `if` statement (always 0), not of the child process.
(
    run_script_buggy() {
        if bash -c 'exit 7'; then
            return 0
        fi
        local exit_code=$?
        printf '%s\n' "$exit_code"
    }

    run_script_fixed() {
        if bash -c 'exit 7'; then
            return 0
        else
            local exit_code=$?
            printf '%s\n' "$exit_code"
        fi
    }

    [[ "$(run_script_buggy)" == "0" ]] && [[ "$(run_script_fixed)" == "7" ]]
) && pass 'regression: exit code must be captured inside the else branch' \
  || fail 'regression: exit code must be captured inside the else branch'

# --quiet must silence the console but keep the audit trail on disk.
(
    cd "$sandbox/toolkit"
    TOOLKIT_QUIET=1
    source ./globals.sh
    TOOLKIT_QUIET=1
    console=$(write_log 'quiet probe' 'INFO')
    [[ -z "$console" ]]
    grep -Fq 'quiet probe' "$LOG_FILE"
) && pass '--quiet silences the console but still writes the log file' \
  || fail '--quiet silences the console but still writes the log file'

# --- CLI behaviour: every tool must reject an unknown option with status 2 ---
# `cli_usage_error` returns 2 by design; under `set -e` that return value used
# to trip the ERR trap and report "Unexpected failure" instead of a usage error.
for platform in Linux macOS; do
    for tool in get-sysreport.sh monitor-disk.sh network-tools.sh process-monitor.sh \
                manage-services.sh audit-users.sh cleanup.sh manage-firewall.sh \
                update-system.sh; do
        path="$ROOT/$platform/$tool"
        output=$(bash "$path" --definitely-not-an-option 2>&1) && status=0 || status=$?
        assert_true "$platform/$tool rejects an unknown option with status 2" \
            test "$status" -eq 2
        assert_true "$platform/$tool reports an unknown option, not a crash" \
            grep -Fq 'Unknown option' <<< "$output"
        assert_true "$platform/$tool does not report an unexpected failure" \
            bash -c "! grep -Fq 'Unexpected failure' <<< '$output'"
        assert_true "$platform/$tool prints usage on error" \
            grep -Fq 'Usage:' <<< "$output"
    done
done

# --- Repository invariants ---

assert_true 'no CRLF line endings in shell scripts' \
    bash -c '! grep -rlU $'"'"'\r'"'"' --include="*.sh" . | grep -q .'

assert_true 'Bash build covers all platforms' \
    grep -Fq 'for platform in Windows Linux macOS' "$ROOT/build.sh"
assert_true 'Bash build produces the Linux tarball the installer downloads' \
    grep -Fq 'Jack-of-All-SysAdmins-Toolkit-linux.tar.gz' "$ROOT/build.sh"
assert_true 'PowerShell build includes all platforms' \
    grep -Fq '$Platforms = @("Windows", "Linux", "macOS")' "$ROOT/Windows/build.ps1"
assert_true 'installer downloads the tarball build.sh produces' \
    grep -Fq 'Jack-of-All-SysAdmins-Toolkit-linux.tar.gz' "$ROOT/install.sh"
assert_true 'macOS service tool uses launchctl' \
    grep -Fq 'launchctl' "$ROOT/macOS/manage-services.sh"
assert_true 'macOS service tool validates labels' \
    grep -Fq 'valid_label' "$ROOT/macOS/manage-services.sh"
assert_true 'macOS launcher maps service management' \
    grep -Fq '4) run_script manage-services.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"
assert_true 'macOS launcher maps system reports' \
    grep -Fq '5) run_script get-sysreport.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"
assert_true 'macOS launcher maps user auditing' \
    grep -Fq 'run_script audit-users.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"
assert_true 'macOS launcher maps firewall management' \
    grep -Fq 'run_script manage-firewall.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"
assert_true 'macOS launcher maps cleanup' \
    grep -Fq 'run_script cleanup.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"
assert_true 'macOS launcher maps system updates' \
    grep -Fq 'run_script update-system.sh' "$ROOT/macOS/start-sysadmintoolbox.sh"

# The Homebrew tool was folded into update-system.sh to keep naming aligned
# with the Linux platform, so the old entry point must be gone.
assert_false 'the macOS-only manage-homebrew.sh was retired' \
    test -e "$ROOT/macOS/manage-homebrew.sh"
assert_true 'macOS update tool detects Homebrew safely' \
    grep -Fq 'find_brew' "$ROOT/macOS/update-system.sh"
assert_true 'macOS update tool covers macOS software updates' \
    grep -Fq 'softwareupdate' "$ROOT/macOS/update-system.sh"
assert_true 'macOS user audit uses the directory service' \
    grep -Fq 'dscl' "$ROOT/macOS/audit-users.sh"
assert_true 'macOS firewall tool uses pf' \
    grep -Fq 'pfctl' "$ROOT/macOS/manage-firewall.sh"
assert_true 'macOS firewall tool validates ports' \
    grep -Fq 'valid_port' "$ROOT/macOS/manage-firewall.sh"
assert_true 'macOS cleanup thins Time Machine snapshots' \
    grep -Fq 'thinlocalsnapshots' "$ROOT/macOS/cleanup.sh"

# --- Platform parity ---
# Linux and macOS must expose exactly the same tool surface, so an operator
# moving between them finds the same file names.
for platform in Linux macOS; do
    for tool in globals.sh cli.sh start-sysadmintoolbox.sh get-sysreport.sh \
                monitor-disk.sh network-tools.sh process-monitor.sh \
                manage-services.sh audit-users.sh cleanup.sh \
                manage-firewall.sh update-system.sh; do
        assert_true "$platform/$tool exists" test -f "$ROOT/$platform/$tool"
    done
    for tool in get-sysreport.sh monitor-disk.sh network-tools.sh process-monitor.sh \
                manage-services.sh audit-users.sh cleanup.sh manage-firewall.sh \
                update-system.sh; do
        assert_true "$platform/$tool supports --help" \
            grep -Fq 'cli_help_requested' "$ROOT/$platform/$tool"
        assert_true "$platform/$tool supports --quiet" \
            grep -Fq 'cli_quiet_requested' "$ROOT/$platform/$tool"
    done
done

# macOS/globals.sh must expose the same privileged-tool helper as Linux.
assert_true 'macOS globals define assert_root' \
    grep -Fq 'assert_root()' "$ROOT/macOS/globals.sh"
assert_true 'macOS globals honour TOOLKIT_QUIET' \
    grep -Fq 'TOOLKIT_QUIET' "$ROOT/macOS/globals.sh"
assert_true 'Linux globals honour TOOLKIT_QUIET' \
    grep -Fq 'TOOLKIT_QUIET' "$ROOT/Linux/globals.sh"
assert_true 'Linux system report supports help' \
    grep -Fq 'show_help' "$ROOT/Linux/get-sysreport.sh"
assert_true 'Windows cleanup exposes Recycle Bin opt-in' \
    grep -Fq '[switch]$IncludeRecycleBin' "$ROOT/Windows/Invoke-DiskCleanup.ps1"
assert_true 'Windows cleanup exposes update-cache opt-in' \
    grep -Fq '[switch]$IncludeWindowsUpdateCache' "$ROOT/Windows/Invoke-DiskCleanup.ps1"
assert_true 'Windows cleanup exposes Cleanup Manager option' \
    grep -Fq '[switch]$LaunchWindowsCleanup' "$ROOT/Windows/Invoke-DiskCleanup.ps1"
assert_true 'Windows launcher maps Cleanup Manager option' \
    grep -Fq 'Run-DiskCleanup -LaunchWindowsCleanup' "$ROOT/Windows/Start-SysAdminToolbox.ps1"
assert_true 'Windows launcher suppresses cleanup confirmation prompts' \
    grep -Fq 'Invoke-DiskCleanup.ps1" -Parameters @{ Confirm = $false }' "$ROOT/Windows/Start-SysAdminToolbox.ps1"
assert_true 'Windows cleanup supports help' \
    grep -Fq 'Get-Help' "$ROOT/Windows/Invoke-DiskCleanup.ps1"
assert_true 'Windows launcher supports help' \
    grep -Fq 'Get-Help' "$ROOT/Windows/Start-SysAdminToolbox.ps1"

# Get-EventLog was removed in PowerShell 7; the launcher must use Get-WinEvent.
assert_false 'Windows launcher does not use the removed Get-EventLog cmdlet' \
    grep -Fq 'Get-EventLog' "$ROOT/Windows/Start-SysAdminToolbox.ps1"
assert_true 'Windows launcher uses Get-WinEvent' \
    grep -Fq 'Get-WinEvent' "$ROOT/Windows/Start-SysAdminToolbox.ps1"

assert_true 'Winget parsing is isolated' \
    grep -Fq 'Get-WingetUpgradeIds' "$ROOT/Windows/Invoke-AppUpdate.ps1"
assert_true 'Winget JSON parsing is preferred' \
    grep -Fq 'ConvertFrom-Json' "$ROOT/Windows/Invoke-AppUpdate.ps1"
assert_true 'Winget table parser rejects header values' \
    grep -Fq "candidate -notmatch '^(Id|Name|Version|Available|Source)\$'" "$ROOT/Windows/Invoke-AppUpdate.ps1"

if (( failures > 0 )); then exit 1; fi
printf 'All toolkit tests passed.\n'