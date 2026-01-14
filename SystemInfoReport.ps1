<#
.SYNOPSIS
    Generates a system configuration report.
.DESCRIPTION
    Collects info about Computer, BIOS, CPU, and Disks.
    Outputs to a file or console (DryRun).
.PARAMETER ReportPath
    Full path to the output report file. Defaults to Desktop\system_config_report.txt.

#>
[CmdletBinding()]
param (
    [string]$ReportPath = (Join-Path ([Environment]::GetFolderPath("Desktop")) "system_config_report.txt")
)

Write-Host "Gathering System Information..." -ForegroundColor Cyan

# Gather Data using CIM (Modern replacement for WMI)
$computerSys = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Build the Report Content as an Array of Strings
$reportContent = @()
$reportContent += "===== System Configuration Report ====="
$reportContent += "Report generated on: $(Get-Date)"
$reportContent += "---------------------------------------"
$reportContent += "Manufacturer: $($computerSys.Manufacturer)"
$reportContent += "Model: $($computerSys.Model)"
$reportContent += "BIOS Version: $($bios.SMBIOSBIOSVersion)"
$reportContent += "OS: $($os.Caption) (Version: $($os.Version))"
$reportContent += "Processor: $($cpu.Name)"
$reportContent += "Total RAM: $([math]::Round($computerSys.TotalPhysicalMemory / 1GB, 2)) GB"

# Network Info (IP Address)
$reportContent += ""
$reportContent += "Network Information:"
$netAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $netAdapters) {
    $ip = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ip) {
        $reportContent += "  Interface: $($adapter.Name) - IPv4: $($ip.IPAddress)"
    }
}

# Disk Info
$reportContent += ""
$reportContent += "Disk Information:"
Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
    $reportContent += "  Drive $($_.DeviceID): Free $([math]::Round($_.FreeSpace/1GB,2)) GB of $([math]::Round($_.Size/1GB,2)) GB"
}

# Output
try {
    $reportContent | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "System configuration report saved to: $ReportPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to save report: $($_.Exception.Message)"
}
