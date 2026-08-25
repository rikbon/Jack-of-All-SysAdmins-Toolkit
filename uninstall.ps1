# --- uninstall.ps1 ---
# One-liner uninstaller for the Jack-of-All-SysAdmins Windows Toolkit.
#
# Run from an Administrator PowerShell (5.1 or 7+):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force; iex "& { $(irm https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/uninstall.ps1) }"
#
# What it does:
#   1. Removes the Start-menu shortcut (%ProgramData%\...\SysAdminToolbox.lnk).
#   2. Removes the toolkit directory from the system PATH.
#   3. Renames %ProgramFiles%\SysAdminToolbox to a timestamped backup
#      (%ProgramFiles%\SysAdminToolbox_uninstall_YYYYMMDDTHHmmss) instead of
#      immediately deleting it, so you can recover local edits; logs inside
#      survive. Running the installer afterwards places a fresh install dir.
#
# The runtime dependencies installed by install.ps1 (PSWindowsUpdate, winget,
# Chocolatey) are NOT removed — they're shared system software and uninstalling
# them could break other apps.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$InstallDir     = Join-Path $env:ProgramFiles 'SysAdminToolbox'
$ShortcutPath   = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\SysAdminToolbox.lnk'

# --- Helpers ---
function log     { param($msg) Write-Host -ForegroundColor Cyan "[uninstall] $msg" }
function logOk   { param($msg) Write-Host -ForegroundColor Green "[uninstall] $msg" }
function logWarn { param($msg) Write-Host -ForegroundColor Yellow "[uninstall] $msg" }
function logErr  { param($msg) Write-Host -ForegroundColor Red    "[uninstall] $msg" }

# --- Execution policy (local session only) ---
try {
    if ((Get-ExecutionPolicy) -eq 'Restricted') {
        log 'Setting local execution policy to RemoteSigned for this session...'
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
    }
}
catch {
    logWarn "Could not tweak execution policy (continuing): $($_.Exception.Message)"
}

# --- Auto-elevate to admin ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    log 'Restarting as Administrator...'
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $PSCommandPath + '"'))
    Start-Process -FilePath PowerShell.exe -ArgumentList $argList -Verb RunAs
    exit 0
}

log 'Jack-of-All-SysAdmins Windows Toolkit uninstaller'
log '=================================================='

# 1) Remove Start-menu shortcut.
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    logOk "Removed Start-menu shortcut: $ShortcutPath"
}
else {
    log 'Start-menu shortcut not found (already removed?).'
}

# 2) Remove the toolkit directory from system PATH.
$machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
if ($machinePath -like "*$InstallDir*") {
    $split = $machinePath -split ';' | Where-Object { $_ -and $_ -ne $InstallDir }
    $clean = ($split -join ';').TrimEnd(';')
    [Environment]::SetEnvironmentVariable('PATH', $clean, 'Machine')
    $env:PATH = (($env:PATH -split ';' | Where-Object { $_ -and $_ -ne $InstallDir }) -join ';').TrimEnd(';')
    logOk "Removed $InstallDir from system PATH."
}
else {
    log 'PATH entry not found (already removed?).'
}

# 3) Timestamped backup rename instead of delete (preserve logs + local edits).
if (Test-Path $InstallDir) {
    $ts = Get-Date -Format 'yyyyMMddTHHmmss'
    $backupName = "SysAdminToolbox_uninstall_$ts"
    $backupPath = Join-Path $env:ProgramFiles $backupName

    # Guard against an unlikely name collision.
    if (Test-Path $backupPath) {
        $backupName = "${backupName}_$([guid]::NewGuid().ToString('N').Substring(0,6))"
        $backupPath = Join-Path $env:ProgramFiles $backupName
    }

    Rename-Item -Path $InstallDir -NewName $backupName -Force
    logOk "Renamed $InstallDir -> $backupPath"
    log   "(logs and any local edits are kept in that backup; delete it manually when ready)"
}
else {
    log 'Installation directory not found (already removed?).'
}

logOk 'Uninstall complete.'

Write-Host ''
$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
