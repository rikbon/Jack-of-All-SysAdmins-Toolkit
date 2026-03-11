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

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

# Set execution policy for the current process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue

Write-Log "Checking for PSWindowsUpdate module..." "INFO"

# Check/Install Module
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    try {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
        Write-Log "PSWindowsUpdate module installed." "SUCCESS"
    }
    catch {
        Write-Log "Failed to install PSWindowsUpdate module: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Import Module
try {
    Import-Module PSWindowsUpdate -Force -ErrorAction Stop
}
catch {
    Write-Log "Failed to import PSWindowsUpdate module." "ERROR"
    exit 1
}

# Scan for Updates
Write-Log "Scanning for Windows Updates..." "INFO"
try {
    # Get-WindowsUpdate is safe to run (read-only)
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction Stop
    
    if ($updates.Count -gt 0) {
        Write-Log "$($updates.Count) update(s) found." "INFO"
        $updates | Select-Object KB, Title, Size | Format-Table -AutoSize

        Write-Log "Installing updates..." "INFO"
        $params = @{
            MicrosoftUpdate = $true
            AcceptAll       = $true
            ErrorAction     = "Stop"
        }
        if ($AutoReboot) { $params.Add('AutoReboot', $true) }
        
        Install-WindowsUpdate @params
        Write-Log "Updates installed successfully." "SUCCESS"
    }
    else {
        Write-Log "No updates available." "SUCCESS"
    }
}
catch {
    Write-Log "Error during Windows Update process: $($_.Exception.Message)" "ERROR"
}
