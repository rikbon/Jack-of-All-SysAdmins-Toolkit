<#
.SYNOPSIS
    Checks for missing or problematic drivers.
.DESCRIPTION
    Uses Get-PnpDevice to flag devices with status other than OK.
#>
[CmdletBinding()]
param()

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Write-Log "Starting Driver Management Scan..." "INFO"

try {
    $BadDevices = Get-PnpDevice | Where-Object Status -ne 'OK' -ErrorAction SilentlyContinue
    
    if ($BadDevices) {
        Write-Log "Found $($BadDevices.Count) device(s) with issues:" "WARN"
        foreach ($dev in $BadDevices) {
            Write-Log "  -> Name: $($dev.FriendlyName) | Status: $($dev.Status) | Class: $($dev.Class)" "WARN"
        }
        Write-Host "`nUse Device Manager (devmgmt.msc) or Windows Update to resolve these driver issues." -ForegroundColor Yellow
    } else {
        Write-Log "All devices report Status OK. No missing or errored drivers found." "SUCCESS"
    }
}
catch {
    Write-Log "Failed to query PNP devices: $($_.Exception.Message)" "ERROR"
}

Write-Log "Driver scan complete." "INFO"
