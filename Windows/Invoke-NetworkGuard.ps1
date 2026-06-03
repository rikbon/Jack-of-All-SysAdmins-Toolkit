<#
.SYNOPSIS
    Monitors for suspicious outbound network connections.
.DESCRIPTION
    Checks active TCP connections for processes running from Temp or AppData folders.
#>
[CmdletBinding()]
param()

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Assert-Admin

Write-Log "Starting Network Guard Scan..." "INFO"

$SuspiciousPaths = @("AppData", "Temp", "ProgramData")
$FlaggedCount = 0

try {
    $Connections = Get-NetTCPConnection -State Established -ErrorAction Stop
    
    foreach ($conn in $Connections) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($process -and $process.Path) {
            $path = $process.Path
            
            $isSuspicious = $false
            foreach ($susPath in $SuspiciousPaths) {
                if ($path -match $susPath) {
                    $isSuspicious = $true
                    break
                }
            }
            
            if ($isSuspicious) {
                Write-Log "SUSPICIOUS CONNECTION: PID $($process.Id) ($($process.ProcessName)) connected to $($conn.RemoteAddress):$($conn.RemotePort)" "WARN"
                Write-Log "  -> Process Path: $path" "WARN"
                $FlaggedCount++
            }
        }
    }
    
    if ($FlaggedCount -eq 0) {
        Write-Log "No suspicious connections detected from monitored paths." "SUCCESS"
    } else {
        Write-Log "Network Guard found $FlaggedCount suspicious connection(s)." "WARN"
    }
}
catch {
    Write-Log "Failed to query network connections: $($_.Exception.Message)" "ERROR"
}

Write-Log "Network Guard scan complete." "INFO"
