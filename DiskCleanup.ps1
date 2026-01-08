<#
.SYNOPSIS
    Cleans up temporary files from system directories.
.DESCRIPTION
    Deletes files from %TEMP%, C:\Windows\Temp, and C:\Windows\Prefetch.
    Supports -WhatIf for dry-run.
.EXAMPLE
    .\DiskCleanup.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit 1
}

Write-Host "Starting Disk Cleanup..." -ForegroundColor Cyan

# Define folders to clean
$foldersToClean = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch")

foreach ($folder in $foldersToClean) {
    if (Test-Path -Path $folder) {
        Write-Host "Processing folder: $folder" -ForegroundColor Yellow
        
        # Get items recursively
        $items = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        
        # Calculate Potential Savings
        $measure = $items | Measure-Object -Property Length -Sum
        $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
        Write-Host "  Found $($items.Count) files, approx. $sizeMB MB."
        
        foreach ($item in $items) {
            try {
                # Remove-Item supports -WhatIf automatically because of CmdletBinding
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Verbose "Could not delete $($item.FullName): $($_.Exception.Message)"
            }
        }
        
        if (-not $WhatIfPreference) { 
            Write-Host "  Cleaned: $folder (Reclaimed ~$sizeMB MB)" -ForegroundColor Green
        }
    } else {
        Write-Warning "Folder not found: $folder"
    }
}

Write-Host "Disk Cleanup completed." -ForegroundColor Green
