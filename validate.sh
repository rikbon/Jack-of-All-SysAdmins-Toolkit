#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0

check() {
    local description="$1"
    shift
    if "$@"; then
        printf 'PASS: %s\n' "$description"
    else
        printf 'FAIL: %s\n' "$description" >&2
        failures=$((failures + 1))
    fi
}

check_shell_syntax() {
    local directory="$1"
    local failed=0
    while IFS= read -r -d '' script; do
        bash -n "$script" || failed=1
    done < <(find "$ROOT/$directory" -type f -name '*.sh' -print0)
    return "$failed"
}

check_version() {
    local version
    version=$(<"$ROOT/VERSION")
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

check_archive_layout() {
    command -v zip >/dev/null 2>&1 || return 0
    local output_directory
    output_directory=$(mktemp -d)
    trap 'rm -rf "$output_directory"' RETURN
    "$ROOT/build.sh" -o "$output_directory" >/dev/null

    local version
    version=$(<"$ROOT/VERSION")
    for platform in Windows Linux macOS; do
        local archive="$output_directory/SysAdminToolbox_${platform}_v${version}.zip"
        [[ -f "$archive" ]] || return 1
        local listing
        listing=$(unzip -Z1 "$archive")
        grep -q "^SysAdminToolbox_${platform}/${platform}/" <<< "$listing" || return 1
        grep -q "^SysAdminToolbox_${platform}/VERSION$" <<< "$listing" || return 1
        grep -q "^SysAdminToolbox_${platform}/docs/" <<< "$listing" || return 1
    done
}

check 'Linux shell syntax' check_shell_syntax Linux
check 'macOS shell syntax' check_shell_syntax macOS
check 'central version format' check_version
check 'root Bash build script exists' test -f "$ROOT/build.sh"
check 'root PowerShell build script exists' test -f "$ROOT/build.ps1"
check 'macOS launcher exists' test -f "$ROOT/macOS/start-sysadmintoolbox.sh"
check 'toolkit unit/static tests' bash "$ROOT/tests/test_toolkit.sh"
check 'error handling tests' bash "$ROOT/tests/test_error_handling.sh"

if command -v pwsh >/dev/null 2>&1; then
    check 'PowerShell syntax' pwsh -NoLogo -NoProfile -Command '$failed = $false; Get-ChildItem Windows/*.ps1, build.ps1 | ForEach-Object { $parseErrors = $null; [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors) | Out-Null; if ($parseErrors) { $failed = $true; $parseErrors | Format-List } }; if ($failed) { exit 1 }'
else
    printf 'SKIP: PowerShell syntax (pwsh not installed)\n'
fi

if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    check 'platform archive layout' check_archive_layout
else
    printf 'SKIP: platform archive layout (zip and unzip are required)\n'
fi

if (( failures > 0 )); then
    exit 1
fi
printf 'All validation checks passed.\n'
