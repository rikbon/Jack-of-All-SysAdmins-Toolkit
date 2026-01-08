<#
.SYNOPSIS
    Restarts WSL networking components.
.DESCRIPTION
    Restarts HNS, LxssManager, and vEthernet (WSL) adapter.
    Includes verification step.
.EXAMPLE
    .\wslNetworkFix.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please start PowerShell as Administrator."
    exit 1
}

$services = @("hns", "LxssManager")

foreach ($service in $services) {
    # Restart-Service supports -WhatIf automatically
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        Write-Host "Restarting service: $service" -ForegroundColor Cyan
        Restart-Service -Name $service -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Service $service not found."
    }
}

# Restart Network Adapter
$wslAdapterName = "vEthernet (WSL)"
if (Get-NetAdapter -Name $wslAdapterName -ErrorAction SilentlyContinue) {
    Write-Host "Restarting Network Adapter: $wslAdapterName" -ForegroundColor Cyan
    Restart-NetAdapter -Name $wslAdapterName -ErrorAction SilentlyContinue
} else {
    Write-Warning "Adapter '$wslAdapterName' not found."
}

# Verification
if (-not $WhatIfPreference) {
    Write-Host "Verifying connectivity (Ping 8.8.8.8)..." -ForegroundColor Yellow
    try {
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
        if ($ping.Status -eq 'Success') {
            Write-Host "Connectivity Verified." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Connectivity check failed. Please check your internet connection."
    }
}