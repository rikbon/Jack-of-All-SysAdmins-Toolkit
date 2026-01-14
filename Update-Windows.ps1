<#
.SYNOPSIS
    Updates Windows using PSWindowsUpdate module.
.DESCRIPTION
    Installs the PSWindowsUpdate module if missing, then scans and installs updates.
.PARAMETER AutoReboot
    If set, automatically reboots if required by updates. Default is False.

#>
[CmdletBinding()]
param (
    [boolean]$AutoReboot = $false
)

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit 1
}

# Set execution policy for the current process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue

Write-Host "Checking for PSWindowsUpdate module..." -ForegroundColor Cyan

# Check/Install Module
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    try {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
        Write-Host "PSWindowsUpdate module installed." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install PSWindowsUpdate module: $($_.Exception.Message)"
        exit 1
    }
}

# Import Module
try {
    Import-Module PSWindowsUpdate -Force -ErrorAction Stop
}
catch {
    Write-Error "Failed to import PSWindowsUpdate module."
    exit 1
}

# Scan for Updates
Write-Host "Scanning for Windows Updates..." -ForegroundColor Yay
try {
    # Get-WindowsUpdate is safe to run (read-only)
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction Stop
    
    if ($updates.Count -gt 0) {
        Write-Host "$($updates.Count) update(s) found." -ForegroundColor Yellow
        $updates | Select-Object KB, Title, Size | Format-Table -AutoSize

        Write-Host "Installing updates..." -ForegroundColor Cyan
        $params = @{
            MicrosoftUpdate = $true
            AcceptAll       = $true
            ErrorAction     = "Stop"
        }
        if ($AutoReboot) { $params.Add('AutoReboot', $true) }
        
        Install-WindowsUpdate @params
        Write-Host "Updates installed." -ForegroundColor Green
    }
    else {
        Write-Host "No updates available." -ForegroundColor Green
    }
}
catch {
    Write-Error "Error during Windows Update process: $($_.Exception.Message)"
}
