<#
.SYNOPSIS
    Monitors free space on filesystem drives.
.DESCRIPTION
    Checks all drives for free space below a threshold. Can send email alerts.
.PARAMETER ThresholdGB
    The minimum free space in GB required before alerting. Default is 10.
.PARAMETER SmtpServer
    SMTP Server for email alerts.
.PARAMETER ToAddress
    Recipient email address.
.PARAMETER FromAddress
    Sender email address.

#>
[CmdletBinding()]
param (
    [double]$ThresholdGB = 10,
    [string]$SmtpServer,
    [string]$ToAddress,
    [string]$FromAddress
)

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Write-Log "Monitoring Disk Space (Threshold: $ThresholdGB GB)..." "INFO"

# Retrieve filesystem drives
$drives = Get-PSDrive -PSProvider FileSystem
$totalDrives = $drives.Count
$currentDriveIdx = 0

foreach ($drive in $drives) {
    $currentDriveIdx++
    # Skip if drive has no size
    if ($null -eq $drive.Used -or $drive.Used -eq 0) { continue }

    Write-Progress -Activity "Monitoring Disk Space" -Status "Checking Drive $($drive.Name):" -PercentComplete (($currentDriveIdx / $totalDrives) * 100)

    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
    
    $message = "Drive $($drive.Name): $freeGB GB free out of $totalGB GB."
    Write-Log $message "INFO"

    # Check threshold
    if ($drive.Free -lt ($ThresholdGB * 1GB)) {
        Write-Log "Low Disk Space: Drive $($drive.Name) (< $ThresholdGB GB)" "ERROR"

        if ($SmtpServer -and $ToAddress -and $FromAddress) {
            try {
                Send-MailMessage -From $FromAddress -To $ToAddress `
                    -Subject "Low Disk Space Alert on $env:COMPUTERNAME" `
                    -Body "Low Disk Space: Drive $($drive.Name) has only $freeGB GB free.`n`n$message" `
                    -SmtpServer $SmtpServer
                Write-Log "Alert email sent." "SUCCESS"
            }
            catch {
                Write-Log "Failed to send email: $($_.Exception.Message)" "ERROR"
            }
        }
    }
}
Write-Progress -Activity "Monitoring Disk Space" -Completed
