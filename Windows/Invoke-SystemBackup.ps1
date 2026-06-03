<#
.SYNOPSIS
    Performs automated system state backups.
.DESCRIPTION
    Backs up critical Registry Hives and Task Scheduler exports to a backup directory.
#>
[CmdletBinding()]
param(
    [string]$BackupDir = "C:\SysAdminBackups"
)

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Assert-Admin

Write-Log "Starting Automated System Backup..." "INFO"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Log "Created backup directory at $BackupDir" "INFO"
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$CurrentBackupDir = Join-Path $BackupDir "Backup_$Timestamp"
New-Item -ItemType Directory -Path $CurrentBackupDir -Force | Out-Null

try {
    # 1. Backup Registry (HKLM\SYSTEM and HKLM\SOFTWARE)
    Write-Log "Backing up Registry HKLM\SYSTEM..." "INFO"
    $sysPath = Join-Path $CurrentBackupDir "HKLM_SYSTEM.reg"
    & reg export HKLM\SYSTEM $sysPath /y | Out-Null

    Write-Log "Backing up Registry HKLM\SOFTWARE..." "INFO"
    $softPath = Join-Path $CurrentBackupDir "HKLM_SOFTWARE.reg"
    & reg export HKLM\SOFTWARE $softPath /y | Out-Null
    
    # 2. Export Scheduled Tasks (Optional, just a summary for now)
    Write-Log "Exporting Scheduled Tasks summary..." "INFO"
    $tasksPath = Join-Path $CurrentBackupDir "ScheduledTasks.csv"
    Get-ScheduledTask | Select-Object TaskName, TaskPath, State | Export-Csv -Path $tasksPath -NoTypeInformation
    
    Write-Log "System Backup completed successfully. Files saved to $CurrentBackupDir" "SUCCESS"
}
catch {
    Write-Log "Backup encountered an error: $($_.Exception.Message)" "ERROR"
}
