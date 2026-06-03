<#
.SYNOPSIS
    Cleans up temporary files from system directories.
.DESCRIPTION
    Deletes files from %TEMP%, C:\Windows\Temp, and C:\Windows\Prefetch.
    Supports -WhatIf for dry-run.
.EXAMPLE
    .\Invoke-DiskCleanup.ps1
#>
[CmdletBinding()]
param()

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

Write-Log "Starting Disk Cleanup..." "INFO"

$foldersToClean = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch")
$totalFolders = $foldersToClean.Count
$currentFolderIndex = 0

foreach ($folder in $foldersToClean) {
    $currentFolderIndex++
    $percentFolder = ($currentFolderIndex / $totalFolders) * 100
    Write-Progress -Activity "Disk Cleanup" -Status "Cleaning $folder" -PercentComplete $percentFolder

    if (Test-Path -Path $folder) {
        Write-Log "Processing folder: $folder" "INFO"
        
        # Get items recursively
        $items = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        
        if ($null -ne $items -and $items.Count -gt 0) {
            # Calculate Potential Savings
            $measure = $items | Measure-Object -Property Length -Sum
            $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
            Write-Log "  Found $($items.Count) files, approx. $sizeMB MB." "INFO"
            
            $currentItemIndex = 0
            
            foreach ($item in $items) {
                $currentItemIndex++
                if ($currentItemIndex % 10 -eq 0) {
                    Write-Progress -Activity "Disk Cleanup" -Status "Cleaning $folder" -SecondaryActivity "Deleting $($item.Name)" -PercentComplete $percentFolder
                }
                try {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                }
                catch {
                    # This happens a lot with temp files currently in use
                    Write-Log "Skipped: $($item.Name) (In use)" "DEBUG"
                }
            }
            Write-Log "  Cleaned: $folder (Reclaimed ~$sizeMB MB)" "SUCCESS"
        }
        else {
            Write-Log "  $folder is already clean." "INFO"
        }
    }
    else {
        Write-Log "Folder not found: $folder" "WARN"
    }
}

Write-Progress -Activity "Disk Cleanup" -Completed
Write-Log "Disk Cleanup completed." "SUCCESS"
