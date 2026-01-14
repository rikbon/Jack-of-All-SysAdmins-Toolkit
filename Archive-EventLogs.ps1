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

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "Archiving event logs requires Administrator privileges. Please run as Administrator."
    exit 1
}

# Ensure Backup Directory Exists
if (-not (Test-Path $BackupPath)) {
    try {
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        Write-Host "Created backup directory: $BackupPath" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to create directory $BackupPath. Check permissions."
        exit 1
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempFolder = Join-Path $env:TEMP "LogBackup_$timestamp"
New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

$logsToBackup = @("Application", "System", "Security")
$allSuccess = $true

Write-Host "Starting Event Log Backup..." -ForegroundColor Cyan

foreach ($logName in $logsToBackup) {
    $outFile = Join-Path $tempFolder "$logName.evtx"
    Write-Host "  Exporting $logName..." -NoNewline
    
    try {
        # wevtutil epl is robust for exporting valid .evtx and avoiding lock issues
        $proc = Start-Process "wevtutil.exe" -ArgumentList "epl `"$logName`" `"$outFile`"" -Wait -PassThru -NoNewWindow
        
        if ($proc.ExitCode -eq 0 -and (Test-Path $outFile)) {
            Write-Host " [OK]" -ForegroundColor Green
        }
        else {
            Write-Host " [FAILED] (Exit Code: $($proc.ExitCode))" -ForegroundColor Red
            $allSuccess = $false
        }
    }
    catch {
        Write-Host " [ERROR]: $($_.Exception.Message)" -ForegroundColor Red
        $allSuccess = $false
    }
}

if ($allSuccess) {
    # Compress
    $zipPath = Join-Path $BackupPath "Logs_$timestamp.zip"
    
    # Wait for file handles to release
    Write-Host "Waiting for file locks to release..."
    Start-Sleep -Seconds 3
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    Write-Host "Compressing to $zipPath..."
    
    $maxRetries = 5
    $retryCount = 0
    $compressed = $false

    while (-not $compressed -and $retryCount -lt $maxRetries) {
        try {
            Compress-Archive -Path "$tempFolder\*.evtx" -DestinationPath $zipPath -Force -ErrorAction Stop
            $compressed = $true
            Write-Host "Backup Complete!" -ForegroundColor Green
        }
        catch {
            $retryCount++
            # If it's the specific file lock error or similar, we retry.
            if ($retryCount -lt $maxRetries) {
                Write-Warning "File locked. Retrying in 5 seconds... ($retryCount/$maxRetries)"
                Start-Sleep -Seconds 5
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            }
            else {
                Write-Error "Failed to compress archive after $maxRetries attempts: $($_.Exception.Message)"
            }
        }
    }

    if ($compressed) {
        # Cleanup Temp
        Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
        
        # Optional Clearing
        if ($ClearLogs) {
            Write-Warning "You have requested to CLEAR the logs."
            $confirm = Read-Host "Are you sure you want to clear Application, System, and Security logs? (y/N)"
            if ($confirm -eq 'y') {
                foreach ($logName in $logsToBackup) {
                    Write-Host "  Clearing $logName..." -NoNewline
                    try {
                        wevtutil cl $logName
                        Write-Host " [CLEARED]" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host " [FAILED]" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "Logs were NOT cleared."
            }
        }
    }
}
else {
    Write-Warning "Backup failed for one or more logs. Skipping compression and clearing."
}
