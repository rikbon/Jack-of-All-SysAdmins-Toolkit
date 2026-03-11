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

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Write-Log "Scanning $Target for $($Ports.Count) common ports..." "INFO"

$totalPorts = $Ports.Count
$currentPortIndex = 0

foreach ($port in $Ports) {
    $currentPortIndex++
    $percent = ($currentPortIndex / $totalPorts) * 100
    Write-Progress -Activity "Port Scanner" -Status "Scanning $Target" -SecondaryActivity "Checking Port $port" -PercentComplete $percent

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($Target, $port, $null, $null)
        if ($connect.AsyncWaitHandle.WaitOne(500, $false)) {
            if ($client.Connected) {
                Write-Log "  Port $port : OPEN" "SUCCESS"
            }
            $client.EndConnect($connect)
            $client.Close()
        }
        $client.Dispose()
    }
    catch {
        Write-Log "  Port $port : Error" "DEBUG"
    }
}

Write-Progress -Activity "Port Scanner" -Completed
Write-Log "Scan complete." "INFO"
