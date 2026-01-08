<#
.SYNOPSIS
    Shrinks WSL 2 VHDX files.
.DESCRIPTION
    Shuts down WSL, finds VHDX files for all distros, and runs Optimize-VHD.
.PARAMETER DryRun
    If set, prints the actions instead of performing them.
#>
[CmdletBinding()]
param (
    [switch]$DryRun
)

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "This script requires Administrator privileges (for Optimize-VHD). Please run as Administrator."
    exit 1
}

# --- Prerequisite Check ---
if (-not (Get-Command Optimize-VHD -ErrorAction SilentlyContinue)) {
    Write-Error "The 'Optimize-VHD' cmdlet is not available. Please install the Hyper-V PowerShell module."
    exit 1
}

# --- Shutdown WSL ---
Write-Host "Preparing to shrink WSL disks..." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DryRun] Would execute: wsl --shutdown" -ForegroundColor Magenta
} else {
    Write-Host "Shutting down WSL..."
    wsl --shutdown
}

# Function to get VHDX Path (Improved with error handling)
function Get-WslVhdXPath {
    param([string]$DistributionName)
    try {
        $regPath = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | 
                   Where-Object { ($_.GetValue("DistributionName")) -eq $DistributionName }
        if ($regPath) {
            $basePath = $regPath.GetValue("BasePath")
            if ($basePath) { return Join-Path -Path $basePath -ChildPath "ext4.vhdx" }
        }
    } catch {
        Write-Debug "Error finding VHDX for $DistributionName"
    }
    return $null
}

# Get Distros using wsl -l -q
# Ensure UTF-8 handling if needed, though usually standard output works
$wslList = (wsl --list --quiet) -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

foreach ($distroRaw in $wslList) {
    # Clean up distro name (remove null bytes if any, trim)
    $distroName = $distroRaw.Trim().Replace("`0", "")
    
    if (-not $distroName) { continue }

    Write-Host "Processing: $distroName" -ForegroundColor Yellow
    $vhdxPath = Get-WslVhdXPath -DistributionName $distroName

        if ($vhdxPath -and (Test-Path $vhdxPath)) {
            $initialBytes = (Get-Item $vhdxPath).Length
            $initialGB = [math]::Round($initialBytes / 1GB, 2)
            Write-Host "  Found VHDX: $vhdxPath (Size: $initialGB GB)"
            
            if ($DryRun) {
                Write-Host "[DryRun] Would execute: Optimize-VHD -Path '$vhdxPath' -Mode Full" -ForegroundColor Magenta
            } else {
                Write-Host "  Optimizing..."
                try {
                    Optimize-VHD -Path $vhdxPath -Mode Full -ErrorAction Stop
                    
                    $finalBytes = (Get-Item $vhdxPath).Length
                    $finalGB = [math]::Round($finalBytes / 1GB, 2)
                    $savedMB = [math]::Round(($initialBytes - $finalBytes) / 1MB, 2)
                    
                    Write-Host "  Optimization complete." -ForegroundColor Green
                    Write-Host "  Before: $initialGB GB | After: $finalGB GB | Reclaimed: $savedMB MB" -ForegroundColor Cyan
                } catch {
                    Write-Error "  Failed to optimize: $($_.Exception.Message)"
                }
            }
    } else {
        Write-Warning "  Could not locate VHDX file for '$distroName'."
    }
}

Write-Host "Done." -ForegroundColor Cyan