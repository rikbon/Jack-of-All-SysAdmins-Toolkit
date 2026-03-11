<#
.SYNOPSIS
    Backs up (archives) Windows Event Logs.
.DESCRIPTION
    Exports Application, System, and Security logs to .evtx files, then compresses them into a ZIP archive.
    Can optionally clear the logs after backup (requires user confirmation).
.PARAMETER BackupPath
    Directory to store backups. Default is C:\EventLogBackups.
.PARAMETER ClearLogs
    If specified, prompts to clear logs after successful backup.
#>
[CmdletBinding()]
param (
    [string]$BackupPath = "C:\EventLogBackups",
    [switch]$ClearLogs
)

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

# Ensure Backup Directory Exists
if (-not (Test-Path $BackupPath)) {
    try {
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        Write-Log "Created backup directory: $BackupPath" "SUCCESS"
    }
    catch {
        Write-Log "Failed to create directory $BackupPath. Check permissions." "ERROR"
        exit 1
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempFolder = Join-Path $env:TEMP "LogBackup_$timestamp"
New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

$logsToBackup = @("Application", "System", "Security")
$allSuccess = $true

Write-Log "Starting Event Log Backup..." "INFO"

$currentLogProgress = 0
$logsToBackupCount = $logsToBackup.Count

foreach ($logName in $logsToBackup) {
    $currentLogProgress++
    Write-Progress -Activity "Backing up Event Logs" -Status "Exporting: $logName" -PercentComplete (($currentLogProgress / $logsToBackupCount) * 100)
    
    $outFile = Join-Path $tempFolder "$logName.evtx"
    Write-Log "  Exporting $logName..." "INFO"
    
    try {
        # wevtutil epl is robust for exporting valid .evtx and avoiding lock issues
        $proc = Start-Process "wevtutil.exe" -ArgumentList "epl `"$logName`" `"$outFile`"" -Wait -PassThru -NoNewWindow
        
        if ($proc.ExitCode -eq 0 -and (Test-Path $outFile)) {
            Write-Log "    [OK]" "SUCCESS"
        }
        else {
            Write-Log "    [FAILED] (Exit Code: $($proc.ExitCode))" "ERROR"
            $allSuccess = $false
        }
    }
    catch {
        Write-Log "    [ERROR]: $($_.Exception.Message)" "ERROR"
        $allSuccess = $false
    }
}
Write-Progress -Activity "Backing up Event Logs" -Completed

if ($allSuccess) {
    # Compress
    $zipPath = Join-Path $BackupPath "Logs_$timestamp.zip"
    
    Write-Log "Compressing to $zipPath..." "INFO"
    
    try {
        Compress-Archive -Path "$tempFolder\*.evtx" -DestinationPath $zipPath -Force -ErrorAction Stop
        Write-Log "Backup Complete!" "SUCCESS"
        
        # Cleanup Temp
        Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
        
        # Optional Clearing
        if ($ClearLogs) {
            Write-Log "You have requested to CLEAR the logs." "WARN"
            $confirm = Read-Host "Are you sure you want to clear Application, System, and Security logs? (y/N)"
            if ($confirm -eq 'y') {
                foreach ($logName in $logsToBackup) {
                    try {
                        wevtutil cl $logName
                        Write-Log "  $logName cleared." "SUCCESS"
                    }
                    catch {
                        Write-Log "  Failed to clear $logName." "ERROR"
                    }
                }
            }
            else {
                Write-Log "Logs were NOT cleared." "INFO"
            }
        }
    }
    catch {
        Write-Log "Failed to compress archive: $($_.Exception.Message)" "ERROR"
    }
}
else {
    Write-Log "Backup failed for one or more logs. Skipping compression and clearing." "ERROR"
}
