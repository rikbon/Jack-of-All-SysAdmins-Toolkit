<#
.SYNOPSIS
    Tests common ports on a target computer (default: localhost).
.DESCRIPTION
    Scans a set of common ports to check if they are open (Listening).
.PARAMETER Target
    The hostname or IP to scan. Default is 'localhost'.
.PARAMETER Ports
    Comma-separated list of ports to scan. Default is a common list.
#>
[CmdletBinding()]
param (
    [string]$Target = "localhost",
    [int[]]$Ports = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3306, 3389, 5900, 8080)
)

Write-Host "Scanning $Target for $($Ports.Count) common ports..." -ForegroundColor Cyan

$results = @()

foreach ($port in $Ports) {
    $status = "Closed"
    try {
        $tcpArgs = @{
            ComputerName     = $Target
            Port             = $port
            InformationLevel = 'Quiet'
            ErrorAction      = 'SilentlyContinue'
            TimeoutMillis    = 500
        }
        
        # Test-NetConnection is slow for scanning multiple ports because it includes ping/trace.
        # System.Net.Sockets.TcpClient is faster.
        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($Target, $port, $null, $null)
        if ($connect.AsyncWaitHandle.WaitOne(500, $false)) {
            if ($client.Connected) {
                $status = "OPEN"
            }
            $client.EndConnect($connect)
            $client.Close()
        }
        $client.Dispose()
    }
    catch {
        $status = "Error"
    }

    $color = if ($status -eq "OPEN") { "Green" } else { "Gray" }
    
    # Only show open ports or explicit requested
    if ($status -eq "OPEN") {
        Write-Host "  Port $port : $status" -ForegroundColor $color
    }

    $results += [PSCustomObject]@{
        Port   = $port
        Status = $status
    }
}

Write-Host "Scan complete." -ForegroundColor Cyan
