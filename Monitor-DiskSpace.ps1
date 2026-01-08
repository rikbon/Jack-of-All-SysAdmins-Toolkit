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
.PARAMETER DryRun
    If specified, runs checks but does not send emails.
#>
[CmdletBinding()]
param (
    [double]$ThresholdGB = 10,
    [string]$SmtpServer,
    [string]$ToAddress,
    [string]$FromAddress,
    [switch]$DryRun
)

# Retrieve filesystem drives
$drives = Get-PSDrive -PSProvider FileSystem

foreach ($drive in $drives) {
    # Skip if drive has no size (e.g. CD-ROM)
    if ($null -eq $drive.Used -or $drive.Used -eq 0) { continue }

    # Calculate free and total space in GB
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
    
    $message = "Drive $($drive.Name): $freeGB GB free out of $totalGB GB available."
    Write-Host $message

    # Check if free space is below the threshold
    if ($drive.Free -lt ($ThresholdGB * 1GB)) {
        $alertMsg = "Warning: Drive $($drive.Name) has less than $ThresholdGB GB free space!"
        Write-Warning $alertMsg

        pass
        if ($SmtpServer -and $ToAddress -and $FromAddress) {
            if ($DryRun) {
                Write-Host "[DryRun] Would send email to $ToAddress: $alertMsg" -ForegroundColor Magenta
            } else {
                try {
                    Send-MailMessage -From $FromAddress -To $ToAddress `
                        -Subject "Low Disk Space Alert on $env:COMPUTERNAME" `
                        -Body "$alertMsg`n$message" `
                        -SmtpServer $SmtpServer
                    Write-Host "Alert email sent." -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to send email: $($_.Exception.Message)"
                }
            }
        }
    }
}
