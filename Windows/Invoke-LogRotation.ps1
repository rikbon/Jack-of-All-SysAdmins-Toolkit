<#
.SYNOPSIS
    Rotates and cleans up old Toolkit logs.
.DESCRIPTION
    Compresses logs older than 7 days.
    Deletes logs/archives older than 30 days.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Assert-Admin

Write-Log "Starting Log Rotation & Cleanup..." "INFO"

$LogDir = Join-Path $PSScriptRoot "logs"
$CurrentDate = Get-Date

# 1. Compress logs older than 7 days
$logsToCompress = Get-ChildItem -Path $LogDir -Filter "*.log" | Where-Object {
    $_.LastWriteTime -lt $CurrentDate.AddDays(-7)
}

if ($logsToCompress) {
    Write-Log "Found $($logsToCompress.Count) log(s) older than 7 days to compress." "INFO"
    
    $total = $logsToCompress.Count
    $current = 0
    
    foreach ($logFile in $logsToCompress) {
        $current++
        Write-Progress -Activity "Compressing Old Logs" -Status "Zipping $($logFile.Name)" -PercentComplete (($current / $total) * 100)
        
        $zipName = $logFile.FullName -replace '\.log$', '.zip'
        try {
            Compress-Archive -Path $logFile.FullName -DestinationPath $zipName -Force
            Remove-Item $logFile.FullName -Force
            Write-Log "Compressed and removed $($logFile.Name)" "SUCCESS"
        }
        catch {
            Write-Log "Failed to compress $($logFile.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    Write-Progress -Activity "Compressing Old Logs" -Completed
}
else {
    Write-Log "No logs older than 7 days need compression." "INFO"
}

# 2. Delete logs/archives older than 30 days
$itemsToDelete = Get-ChildItem -Path $LogDir | Where-Object {
    ($_.Extension -eq ".log" -or $_.Extension -eq ".zip") -and $_.LastWriteTime -lt $CurrentDate.AddDays(-30)
}

if ($itemsToDelete) {
    Write-Log "Found $($itemsToDelete.Count) item(s) older than 30 days to delete." "INFO"
    
    $totalDel = $itemsToDelete.Count
    $currentDel = 0
    foreach ($item in $itemsToDelete) {
        $currentDel++
        Write-Progress -Activity "Deleting Old Logs" -Status "Removing $($item.Name)" -PercentComplete (($currentDel / $totalDel) * 100)
        
        try {
            Remove-Item $item.FullName -Force
            Write-Log "Deleted old file: $($item.Name)" "SUCCESS"
        }
        catch {
            Write-Log "Failed to delete $($item.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    Write-Progress -Activity "Deleting Old Logs" -Completed
}
else {
    Write-Log "No logs older than 30 days need deletion." "INFO"
}

Write-Log "Log Rotation process finished." "SUCCESS"
