#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

assert_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if grep -Fq -- "$pattern" "$file"; then pass "$description"; else fail "$description"; fi
}

assert_command() {
    local description="$1"
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

assert_command 'VERSION contains a semantic version' grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT/VERSION"

# Load Linux helpers in a temporary HOME/log location without running a toolkit command.
test_globals_dir=$(mktemp -d)
trap 'rm -rf "$test_globals_dir"' EXIT
cp "$ROOT/Linux/globals.sh" "$test_globals_dir/globals.sh"
(
    cd "$test_globals_dir"
    source ./globals.sh
    valid_port 1
    valid_port 65535
    ! valid_port 0
    ! valid_port 65536
    valid_pid() { [[ "$1" =~ ^[0-9]+$ ]] && (( 1 < 10#$1 )); }
    valid_pid 2
    ! valid_pid 1
) && pass 'Linux validation helpers accept/reject expected values' || fail 'Linux validation helpers accept/reject expected values'

assert_contains "$ROOT/Linux/globals.sh" 'set -Eeuo pipefail' 'Linux globals enable strict mode'
assert_contains "$ROOT/macOS/globals.sh" 'set -Eeuo pipefail' 'macOS globals enable strict mode'
assert_contains "$ROOT/Windows/Invoke-DiskCleanup.ps1" '[switch]$IncludeRecycleBin' 'Windows cleanup exposes Recycle Bin opt-in'
assert_contains "$ROOT/Windows/Invoke-DiskCleanup.ps1" '[switch]$IncludeWindowsUpdateCache' 'Windows cleanup exposes update-cache opt-in'
assert_contains "$ROOT/Windows/Invoke-DiskCleanup.ps1" '[switch]$LaunchWindowsCleanup' 'Windows cleanup exposes Cleanup Manager option'
assert_contains "$ROOT/Windows/Start-SysAdminToolbox.ps1" 'Run-DiskCleanup -LaunchWindowsCleanup' 'Windows launcher maps Cleanup Manager option'
assert_contains "$ROOT/build.sh" 'for platform in Windows Linux macOS' 'Bash build includes all platforms'
assert_contains "$ROOT/Windows/build.ps1" '$Platforms = @("Windows", "Linux", "macOS")' 'PowerShell build includes all platforms'
assert_contains "$ROOT/macOS/manage-services.sh" 'launchctl' 'macOS service tool uses launchctl'
assert_contains "$ROOT/macOS/manage-services.sh" 'valid_label' 'macOS service tool validates labels'
assert_contains "$ROOT/macOS/start-sysadmintoolbox.sh" '5) run_script manage-services.sh interactive' 'macOS launcher maps service management'
assert_contains "$ROOT/macOS/manage-homebrew.sh" 'find_brew' 'macOS Homebrew tool detects Homebrew safely'
assert_contains "$ROOT/macOS/manage-homebrew.sh" '--list' 'macOS Homebrew tool supports listing updates'
assert_contains "$ROOT/macOS/manage-homebrew.sh" '--upgrade' 'macOS Homebrew tool supports explicit upgrades'
assert_contains "$ROOT/macOS/start-sysadmintoolbox.sh" '6) run_script manage-homebrew.sh interactive' 'macOS launcher maps Homebrew updates'
assert_contains "$ROOT/Windows/Invoke-AppUpdate.ps1" 'Get-WingetUpgradeIds' 'Winget parsing is isolated'
assert_contains "$ROOT/Windows/Invoke-AppUpdate.ps1" 'ConvertFrom-Json' 'Winget JSON parsing is preferred'
assert_contains "$ROOT/macOS/cli.sh" 'cli_help_requested' 'macOS CLI helper supports help detection'
assert_contains "$ROOT/macOS/get-sysreport.sh" '--report' 'macOS system report supports non-interactive mode'
assert_contains "$ROOT/macOS/manage-homebrew.sh" '--upgrade' 'macOS Homebrew supports explicit upgrade mode'
assert_contains "$ROOT/Linux/globals.sh" 'cli_help_requested' 'Linux CLI helper supports help detection'
assert_contains "$ROOT/Linux/get-sysreport.sh" 'show_help' 'Linux system report supports help'
assert_contains "$ROOT/Windows/Invoke-DiskCleanup.ps1" 'Get-Help' 'Windows cleanup supports help'
assert_contains "$ROOT/Windows/Start-SysAdminToolbox.ps1" 'Get-Help' 'Windows launcher supports help'

if (( failures > 0 )); then exit 1; fi
printf 'All toolkit tests passed.\n'
