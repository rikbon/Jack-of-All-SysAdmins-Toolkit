<#
.SYNOPSIS
    Restarts WSL networking components.
.DESCRIPTION
    Restarts HNS, LxssManager, and vEthernet (WSL) adapter.
    Includes verification step.
.EXAMPLE
    .\Invoke-WSLNetworkFix.ps1
#>
[CmdletBinding()]
param()

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

Write-Log "Restarting WSL networking components..." "INFO"

$services = @("hns", "LxssManager")

foreach ($service in $services) {
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        Write-Log "Restarting service: $service" "INFO"
        Restart-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Log "Service $service not found." "WARN"
    }
}

# Restart Network Adapter
$wslAdapterName = "vEthernet (WSL)"
if (Get-NetAdapter -Name $wslAdapterName -ErrorAction SilentlyContinue) {
    Write-Log "Restarting Network Adapter: $wslAdapterName" "INFO"
    Restart-NetAdapter -Name $wslAdapterName -ErrorAction SilentlyContinue
}
else {
    Write-Log "Adapter '$wslAdapterName' not found." "WARN"
}

# Verification
Write-Log "Verifying connectivity (Ping 8.8.8.8)..." "INFO"
try {
    $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
    if ($ping.Status -eq 'Success') {
        Write-Log "Connectivity Verified." "SUCCESS"
    }
}
catch {
    Write-Log "Connectivity check failed. Please check your internet connection." "WARN"
}