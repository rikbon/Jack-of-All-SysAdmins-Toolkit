<#
.SYNOPSIS
    Checks for expiring certificates.
.DESCRIPTION
    Scans LocalMachine\My and LocalMachine\Root for certificates expiring within 30 days.
#>
[CmdletBinding()]
param(
    [int]$DaysThreshold = 30
)

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Write-Log "Starting Certificate Watcher..." "INFO"

$ExpiringDate = (Get-Date).AddDays($DaysThreshold)
$FlaggedCount = 0

try {
    $Certs = Get-ChildItem -Path Cert:\LocalMachine\My, Cert:\LocalMachine\Root -Recurse -ErrorAction SilentlyContinue
    
    foreach ($cert in $Certs) {
        if ($cert.NotAfter -lt $ExpiringDate -and $cert.NotAfter -gt (Get-Date)) {
            Write-Log "EXPIRING SOON: Cert '$($cert.Subject)' expires on $($cert.NotAfter.ToString('yyyy-MM-dd'))." "WARN"
            $FlaggedCount++
        } elseif ($cert.NotAfter -le (Get-Date)) {
            # Write-Log "EXPIRED: Cert '$($cert.Subject)' expired on $($cert.NotAfter.ToString('yyyy-MM-dd'))." "ERROR"
            # Optional: Uncomment above to log all already expired certs, but can be noisy.
        }
    }
    
    if ($FlaggedCount -eq 0) {
        Write-Log "No certificates are expiring within the next $DaysThreshold days." "SUCCESS"
    } else {
        Write-Log "Found $FlaggedCount certificate(s) expiring soon." "WARN"
    }
}
catch {
    Write-Log "Failed to query certificates: $($_.Exception.Message)" "ERROR"
}

Write-Log "Certificate Watcher scan complete." "INFO"
