# --- install.ps1 ---
# One-liner installer for the Jack-of-All-SysAdmins Windows Toolkit.
#
# Windows PowerShell 5.1 one-liner (Admin PowerShell):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force; iex "& { $(irm https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.ps1) }"
#
# Windows PowerShell 7+ one-liner:
#   & { $script = (irm https://raw.githubusercontent.com/rikbon/Jack-of-All-SysAdmins-Toolkit/main/install.ps1); Set-Content -Path "$env:TEMP\install.ps1" -Value $script; & "$env:TEMP\install.ps1" }
#
# What it does:
#   1. Temporarily allows script execution and auto-elevates to Administrator.
#   2. Installs runtime prerequisites (PowerShellGet + PSWindowsUpdate, and
#      ensures winget is present via the App Installer package).
#   3. Downloads the latest toolkit release and installs it under
#      ${env:ProgramFiles}\SysAdminToolbox.
#   4. Adds the toolkit to PATH and creates a Start-menu shortcut so
#      `sysadmin-toolbox` launches the dashboard from any console.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$Repo      = 'rikbon/Jack-of-All-SysAdmins-Toolkit'
$InstallerUrl = "https://raw.githubusercontent.com/${Repo}/main/install.ps1"
$ReleaseUrl   = "https://github.com/${Repo}/releases/latest/download/Jack-of-All-SysAdmins-Toolkit-windows.zip"
$ArchiveUrl   = "https://github.com/${Repo}/archive/refs/heads/main.zip"
$InstallDir   = Join-Path $env:ProgramFiles 'SysAdminToolbox'
$ShortcutName = 'SysAdminToolbox.lnk'

# --- Helpers ---
function log     { param($msg) Write-Host -ForegroundColor Cyan "[install] $msg" }
function logOk   { param($msg) Write-Host -ForegroundColor Green "[install] $msg" }
function logWarn { param($msg) Write-Host -ForegroundColor Yellow "[install] $msg" }
function logErr  { param($msg) Write-Host -ForegroundColor Red    "[install] $msg" }

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
    $argList = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',
        ('"' + $PSCommandPath + '"')
    )
    Start-Process -FilePath PowerShell.exe -ArgumentList $argList -Verb RunAs
    exit 0
}

log 'Jack-of-All-SysAdmins Toolkit installer'
log '=========================================='

# --- Prerequisites ---
# The Windows toolkit modules rely on:
#   - PowerShellGet      (ships with PS5.1; used to install PSWindowsUpdate)
#   - PSWindowsUpdate    (Install-Module; used by Invoke-WindowsUpdate.ps1)
#   - winget             (App Installer; per-user or system-wide)
#   - choco              (optional; only some feature paths use it)
Install-Prerequisites

function Install-Prerequisites {
    log 'Checking prerequisites...'

    # 1) PackageManagement / PowerShellGet — ensure present so we can import modules.
    if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
        log 'Installing PackageManagement module...'
        Install-Module -Name PackageManagement -Scope AllUsers -Force -AllowClobber
    }
    if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
        log 'Installing PowerShellGet module...'
        Install-Module -Name PowerShellGet -Scope AllUsers -Force -AllowClobber
    }

    # 2) PSWindowsUpdate — used by Invoke-WindowsUpdate.ps1.
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        log 'Installing PSWindowsUpdate module...'
        try {
            Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck
        }
        catch {
            logWarn "Install-Module PSWindowsUpdate failed (will try PSResource): $($_.Exception.Message)"
        }
    }
    if (Get-Command 'Install-PSResource' -ErrorAction SilentlyContinue) {
        if (-not (Get-PSResource -Name PSWindowsUpdate -ErrorAction SilentlyContinue)) {
            Install-PSResource -Name PSWindowsUpdate -Scope AllUsers -TrustRepository -AcceptLicense -Quiet
        }
    }

    # 3) winget — bootstrap via the Microsoft Store App Installer package.
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        log 'Winget not found — attempting to bootstrap the App Installer package...'
        try {
            $storeUrl = 'https://aka.ms/getwinget'
            $bundle = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
            Invoke-WebRequest -Uri $storeUrl -OutFile $bundle -UseBasicParsing
            Add-AppxPackage -Path $bundle -ErrorAction Stop
            Remove-Item $bundle -Force -ErrorAction SilentlyContinue
            logOk 'winget installed.'
        }
        catch {
            logWarn "Could not install winget (continuing without it): $($_.Exception.Message)"
        }
    }
    else {
        logOk 'winget already present.'
    }

    # 4) Chocolatey — optional, used only in some toolkit feature paths.
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        log 'Chocolatey not found — installing in the background...'
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            $chocoInstallUrl = 'https://community.chocolatey.org/install.ps1'
            $chocoScript = (New-Object System.Net.WebClient).DownloadString($chocoInstallUrl)
            Invoke-Expression $chocoScript
            # Refresh PATH for current session
            $env:PATH += ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
            $env:PATH += ';' + [Environment]::GetEnvironmentVariable('PATH', 'Machine')
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                logOk 'Chocolatey installed.'
            }
            else {
                logWarn 'Chocolatey installed but not on PATH in this session.'
            }
        }
        catch {
            logWarn "Could not install Chocolatey (continuing without it): $($_.Exception.Message)"
        }
    }
    else {
        logOk 'Chocolatey already present.'
    }
}

# --- Download + install the toolkit ---
function Install-Toolbox {
    log 'Downloading latest toolkit release...'
    $tmpRoot = Join-Path $env:TEMP "sysadmin-toolbox-install"
    if (Test-Path $tmpRoot) { Remove-Item $tmpRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $tmpRoot | Out-Null

    $zipPath = Join-Path $tmpRoot 'toolkit.zip'
    $dlOk = $false
    # Prefer the published release ZIP; fall back to the main branch archive.
    foreach ($url in @($ReleaseUrl, $ArchiveUrl)) {
        try {
            log "Trying $url"
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            }
            else {
                Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            }
            $dlOk = $true
            break
        }
        catch {
            logWarn "Download failed: $($_.Exception.Message)"
        }
    }

    if (-not $dlOk) {
        logErr "Could not download toolkit release. Please install manually from: https://github.com/$Repo/releases"
        exit 1
    }

    log "Extracting to $InstallDir..."
    if (Test-Path $InstallDir) {
        log "Removing previous install at $InstallDir"
        Remove-Item $InstallDir -Recurse -Force
    }
    Microsoft.PowerShell.Archive\Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force

    # Locate the launcher (Start-SysAdminToolbox.ps1). When using the
    # archive fallback, the scripts live one directory deeper.
    $launcher = Get-ChildItem -Path $InstallDir -Recurse -Filter 'Start-SysAdminToolbox.ps1' |
                Select-Object -First 1
    if (-not $launcher) {
        logErr 'Start-SysAdminToolbox.ps1 not found in the extracted archive.'
        exit 1
    }
    $LauncherDir = $launcher.Directory.FullName

    # Add to system PATH
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($machinePath -notlike "*$LauncherDir*") {
        log "Adding $LauncherDir to system PATH..."
        [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$LauncherDir", 'Machine')
        $env:PATH += ";$LauncherDir"
    }

    # Create Start-menu shortcut
    $startMenu = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
    $scPath = Join-Path $startMenu $ShortcutName
    $ws = New-Object -ComObject WScript.Shell
    $sc  = $ws.CreateShortcut($scPath)
    $sc.TargetPath = 'PowerShell.exe'
    $sc.Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$($launcher.FullName)`""
    $sc.WorkingDirectory = $LauncherDir
    $sc.Description = 'Jack-of-All-SysAdmins Toolkit'
    $sc.Save()

    # CONSOLE launcher so `sysadmin-toolbox` works in cmd/PowerShell.
    $cmdLauncher = Join-Path $LauncherDir 'sysadmin-toolbox.cmd'
    @"
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "$($launcher.FullName)"
"@ | Set-Content -Path $cmdLauncher -Encoding ASCII

    # Optional per-user PATH entry so users without admin access to the
    # system PATH can still launcher from their own shell.
    $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($userPath -notlike "*$LauncherDir*") {
        [Environment]::SetEnvironmentVariable('PATH', "$userPath;$LauncherDir", 'User')
    }

    # Clean up
    Remove-Item $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue

    logOk "Installed to $LauncherDir"
    logOk "Start-menu shortcut  -> $scPath"
    logOk "Console launcher     -> $cmdLauncher"
}

Install-Toolbox

logOk 'Done! Launch the dashboard any of these ways:'
logOk ''
logOk '   Start Menu  -> "SysAdminToolbox"'
logOk '   PowerShell  -> sysadmin-toolbox'
logOk '   PowerShell  -> Start-SysAdminToolbox.ps1'
logOk '(Restart your shell for the PATH entry to take effect.)'

Write-Host ''
$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
