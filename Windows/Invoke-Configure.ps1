<#
.SYNOPSIS
    Configuration Wizard for the SysAdmin Toolbox.
.DESCRIPTION
    Interactive TUI-style wizard that writes common runtime parameters to
    $TOOLKIT_CONFIG for Windows scripts that read them at launch time. The
    wizard does not overwrite user values it has already set, and saves its
    known state after finishing so subsequent non-interactive runs keep working.
#>
[CmdletBinding()]
param()

$ConfigPath = Join-Path $PSScriptRoot ".toolkit-config.ps1"
if ($args -contains '-h' -or $args -contains '--help') {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

function Read-Bool {
    while ($true) {
        $response = Read-Host '[Yy] yes / [Nn] no'
        switch (([string]::IsNullOrWhiteSpace($response) ? '' : $response.Trim().ToLower())) {
            ''     { continue }
            'y'    { return $true }
            default { return $false }
        }
    }
}

function Read-Threshold {
    while ($true) {
        $input = Read-Host "Free space threshold in GB (leave blank for default 10)"
        if ([string]::IsNullOrWhiteSpace($input)) { return "" }
        if ([double]::TryParse($input, [ref]$null)) { return $input }
        Write-Host "'$input' is not a valid number; try again." -ForegroundColor Yellow
    }
}

# Start from whatever the previous run remembered, so an operator can change it.
$savedThreshold = ""
if (Test-Path -LiteralPath $ConfigPath) {
    try {
        $saved = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop
        $parsed = ConvertFrom-Json $saved
        if ($parsed.ThresholdGB) { $savedThreshold = $parsed.ThresholdGB.ToString() }
    } catch {}
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  SysAdmin Toolbox Configuration Wizard" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$threshold = if ($savedThreshold) { $savedThreshold } else { "10" }
$autoEmail = ""
$smtpServer = ""
$toAddress = ""
$fromAddress = ""
$emailEnabled = $false

do {
    $autoEmail = (Read-Bool "Send email alerts when free space falls below the threshold?")
} until ([bool]$autoEmail -eq $true -or [bool]$autoEmail -eq $false)
if ($autoEmail) {
    $smtpServer = (Read-Host "SMTP server hostname" | Out-Null)
    if ($null -ne $smtpServer -and $smtpServer -ne '') {
        $toAddress = (Read-Host "Recipient email address" | Out-Null)
        if ($null -ne $toAddress -and $toAddress -ne '') {
            $fromAddress = (Read-Host "Sender email address (defaults to above)" | Out-Null)
            if ($null -ne $fromAddress -and $fromAddress -ne '') {
                # remember what we asked for, so subsequent prompts stay consistent
                $fromAddress = $fromAddress
            }
        }
    }
}

$newThreshold = Read-Threshold
if (-not [string]::IsNullOrWhiteSpace($newThreshold)) {
    $threshold = $newThreshold
}

$settings = @{
    ThresholdGB      = [double]$threshold
    EmailAlertsEnabled=$autoEmail
    SmtpServer       = $smtpServer
    ToAddress        = $toAddress
    FromAddress      = $fromAddress
}

try {
    ConvertTo-Json $settings | Out-File -LiteralPath $ConfigPath -Encoding utf8 -Force
    # Re-tag so Write-Output doesn't make the file need a BOM the tools ignore.
    (Get-Item -LiteralPath $ConfigPath).Length | Out-Null
    Write-Host "Settings saved." -ForegroundColor Green
} catch {
    Write-Log "Could not persist toolkit configuration: $($_.Exception.Message)" "ERROR"
    exit 1
}
