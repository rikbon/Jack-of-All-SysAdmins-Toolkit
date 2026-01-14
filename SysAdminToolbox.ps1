<#
.SYNOPSIS
    The "Jack-of-All-SysAdmins" Toolkit.
.DESCRIPTION
    A comprehensive menu-driven utility for system administration.
    Integrates existing scripts and adds new network/system tools.

#>
[CmdletBinding()]
param()

# --- Auto-Elevation ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $argList = "-File `"$($MyInvocation.MyCommand.Path)`""
    
    Start-Process -FilePath "PowerShell.exe" -ArgumentList $argList -Verb RunAs
    exit
}

# --- Configuration ---
$ScriptDir = $PSScriptRoot
$LogFile = "$env:TEMP\SysAdminToolbox_$(Get-Date -Format 'yyyyMMdd').log"

# --- Helper Functions ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    $logEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "Gray" }
    }
    Write-Host $logEntry -ForegroundColor $color
}

function Run-Script {
    param([string]$ScriptName, [string]$ScriptArgs)
    $path = Join-Path $ScriptDir $ScriptName
    if (Test-Path $path) {
        Write-Log "Launching $ScriptName..." "INFO"
        $cmd = "& '$path' $ScriptArgs"
        
        Invoke-Expression $cmd
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    else {
        Write-Log "Script $ScriptName not found!" "ERROR"
        Start-Sleep -Seconds 2
    }
}

# --- Module: Network Tools ---
function Show-NetworkMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Network Tools ===" -ForegroundColor Cyan
        Write-Host "1. Flush DNS Cache"
        Write-Host "2. Test Connectivity (Ping 8.8.8.8)"
        Write-Host "3. Get Public IP"
        Write-Host "4. Active TCP Connections"
        Write-Host "5. WSL Network Fix (Script)"
        Write-Host "B. Back"
        
        $choice = Read-Host "Select an option"
        switch ($choice) {
            "1" { 
                try { Clear-DnsClientCache -ErrorAction Stop; Write-Log "DNS Cache Flushed." "SUCCESS" }
                catch { Write-Log "Failed to flush DNS: $($_.Exception.Message)" "ERROR" }
                Pause
            }
            "2" {
                Write-Host "Pinging 8.8.8.8..."
                Test-Connection -ComputerName 8.8.8.8 -Count 4
                Pause
            }
            "3" {
                try {
                    $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5
                    Write-Log "Public IP: $ip" "SUCCESS"
                }
                catch {
                    Write-Log "Failed to get Public IP." "ERROR"
                }
                Pause
            }
            "4" {
                Get-NetTCPConnection | Where-Object State -eq Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, CreationTime | Format-Table -AutoSize
                Pause
            }
            "5" { Run-Script "wslNetworkFix.ps1" }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Module: Logging & Auditing ---
function Show-LoggingMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Logging & Auditing ===" -ForegroundColor Cyan
        Write-Host "1. Audit User Logon/Logoff Activity"
        Write-Host "2. Archive & Backup Event Logs"
        Write-Host "B. Back"

        $choice = Read-Host "Select"
        switch ($choice) {
            "1" { Run-Script "Audit-UserActivity.ps1" }
            "2" { Run-Script "Archive-EventLogs.ps1" }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Module: Service Tools ---
function Show-ServiceMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Service Tools ===" -ForegroundColor Cyan
        Write-Host "1. Restart Print Spooler"
        Write-Host "2. Restart Windows Explorer"
        Write-Host "B. Back"

        $choice = Read-Host "Select an option"
        switch ($choice) {
            "1" {
                try {
                    Restart-Service -Name Spooler -Force -ErrorAction Stop
                    Write-Log "Print Spooler restarted." "SUCCESS"
                }
                catch { Write-Log "Failed: $($_.Exception.Message)" "ERROR" }
                Pause
            }
            "2" {
                Stop-Process -ProcessName explorer -Force -ErrorAction SilentlyContinue
                Write-Log "Explorer restarted." "SUCCESS"
                Pause
            }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Module: System Health ---
function Show-HealthMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== System Health & Troubleshooting ===" -ForegroundColor Cyan
        Write-Host "1. System Information Report (Script)"
        Write-Host "2. Quick SFC Scan (System File Checker)"
        Write-Host "3. Repair System Image (DISM)"
        Write-Host "4. View Recent Critical/Error Events"
        Write-Host "5. Check for BSOD Minidumps"
        Write-Host "B. Back"

        $choice = Read-Host "Select an option"
        switch ($choice) {
            "1" { Run-Script "SystemInfoReport.ps1" }
            "2" {
                sfc /verifyonly
                Pause
            }
            "3" {
                DISM /Online /Cleanup-Image /CheckHealth
                Pause
            }
            "4" {
                Write-Host "Fetching last 10 Error/Critical events..."
                Get-EventLog -LogName System -EntryType Error, Warning -Newest 10 | Format-Table TimeGenerated, Source, Message -AutoSize
                Get-EventLog -LogName Application -EntryType Error, Warning -Newest 10 | Format-Table TimeGenerated, Source, Message -AutoSize
                Pause
            }
            "5" {
                if (Test-Path "C:\Windows\Minidump") {
                    $dumps = Get-ChildItem "C:\Windows\Minidump" -Filter "*.dmp"
                    if ($dumps) { 
                        Write-Host "Found $($dumps.Count) Minidump(s):" -ForegroundColor Yellow
                        $dumps | Select-Object Name, CreationTime, @{Name = "Size(KB)"; Expression = { [math]::Round($_.Length / 1KB, 0) } } | Format-Table -AutoSize
                        
                        Write-Host ""
                        Write-Host "[I] Investigate (Correlate with Event Log)"
                        Write-Host "[D] Delete All Dumps"
                        Write-Host "[B] Back"
                        
                        $subChoice = Read-Host "Select"
                        if ($subChoice -eq 'I') {
                            foreach ($dump in $dumps) {
                                Write-Host "Checking Event Log for dump: $($dump.Name) ($($dump.CreationTime))" -ForegroundColor Cyan
                                $start = $dump.CreationTime.AddMinutes(-5)
                                $end = $dump.CreationTime.AddMinutes(5)
                                # Event ID 1001 is typically BugCheck in System log
                                $events = Get-EventLog -LogName System -Source "Microsoft-Windows-WER-SystemErrorReporting", "BugCheck" -After $start -Before $end -ErrorAction SilentlyContinue
                                if ($events) {
                                    $events | Select-Object TimeGenerated, EntryType, Message | Format-List
                                }
                                else {
                                    Write-Warning "  No correlated Event Log entries found around this time."
                                }
                                Write-Host "---"
                            }
                            Pause
                        }
                        elseif ($subChoice -eq 'D') {
                            $confirm = Read-Host "Are you SURE you want to delete all minidumps? (y/N)"
                            if ($confirm -eq 'y') {
                                Remove-Item "C:\Windows\Minidump\*.dmp" -Force -ErrorAction SilentlyContinue
                                Write-Host "Dumps deleted." -ForegroundColor Green
                            }
                        }
                    } 
                    else { Write-Host "Minidump folder exists but is empty (Good news!)." -ForegroundColor Green; Pause }
                }
                else {
                    Write-Host "No Minidump folder found (No recent BSODs detected)." -ForegroundColor Green
                    Pause
                }
            }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Module: Process & Performance ---
function Show-ProcessMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Process & Performance ===" -ForegroundColor Cyan
        Write-Host "1. Show Top 10 Memory Hogs"
        Write-Host "2. Show Top 10 CPU Hogs"
        Write-Host "3. Kill Process by ID"
        Write-Host "4. Manage Startup Apps"
        Write-Host "B. Back"
        
        $choice = Read-Host "Select"
        switch ($choice) {
            "1" { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Id, ProcessName, @{Name = "MB"; Expression = { [math]::Round($_.WorkingSet / 1MB, 1) } } | Format-Table -AutoSize; Pause }
            "2" { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Id, ProcessName, CPU | Format-Table -AutoSize; Pause }
            "3" {
                $pidToKill = Read-Host "Enter Process ID to kill"
                if ($pidToKill) {
                    Stop-Process -Id $pidToKill -ErrorAction Continue; Write-Log "Attempted to stop $pidToKill" "INFO"
                }
                Pause
            }
            "4" {
                Run-Script "Manage-StartupApps.ps1"
            }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Module: Security & File ---
function Show-SecurityFileMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Security & File Utilities ===" -ForegroundColor Cyan
        Write-Host "1. List Local Users (Status/Password Age)"
        Write-Host "2. Check File Hash (SHA256)"
        Write-Host "3. Find Large Files (>1GB) in a Directory"
        Write-Host "4. Port Scanner (Quick Scan)"
        Write-Host "5. Firewall Rule Manager"
        Write-Host "B. Back"
        
        $choice = Read-Host "Select"
        switch ($choice) {
            "1" {
                Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, LastLogon, InvalidLoginCount | Format-Table -AutoSize
                Pause
            }
            "2" {
                $f = Read-Host "Enter full path to file"
                if (Test-Path $f) {
                    Get-FileHash -Path $f -Algorithm SHA256 | Format-List
                }
                else { Write-Warning "File not found." }
                Pause
            }
            "3" {
                $d = Read-Host "Enter directory to scan (e.g. C:\Users)"
                if (Test-Path $d) {
                    Write-Host "Scanning... this may take a moment."
                    Get-ChildItem -Path $d -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB } | Sort-Object Length -Descending | Select-Object FullName, @{Name = "GB"; Expression = { [math]::Round($_.Length / 1GB, 2) } } | Format-Table -AutoSize
                }
                Pause
            }
            "4" { Run-Script "Test-PortScan.ps1" }
            "5" { Run-Script "Manage-FirewallRules.ps1" }
            "B" { return }
            "b" { return }
        }
    }
}

# --- Main Menu ---
function Show-MainMenu {
    # Check Admin Rights
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Warning "SysAdmin Toolbox requires Administrator privileges for most tasks."
    }

    while ($true) {
        Clear-Host
        Write-Host "===========================" -ForegroundColor Cyan
        Write-Host " Jack-of-All-SysAdmins v1.0" -ForegroundColor Cyan
        Write-Host "===========================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. System Maintenance (Clean, Update)"
        Write-Host "2. Disk & Storage (Monitor, WSL Shrink)"
        Write-Host "3. Network Utility"
        Write-Host "4. Service Utility"
        Write-Host "5. System Health & Troubleshooting"
        Write-Host "6. Process & Performance"
        Write-Host "7. Security & File Utilities"
        Write-Host "8. Logging & Auditing"
        Write-Host "Q. Quit"
        
        $choice = Read-Host "Select a Category"
        
        switch ($choice) {
            "1" { 
                while ($true) {
                    Clear-Host; Write-Host "=== Maintenance ===" -ForegroundColor Cyan
                    Write-Host "1. Disk Cleanup"; Write-Host "2. Windows Update"; Write-Host "3. App Updates (Winget/Choco)"; Write-Host "B. Back"
                    $s = Read-Host "Select"; if ($s -eq 'B') { break }
                    switch ($s) {
                        "1" { Run-Script "DiskCleanup.ps1" }
                        "2" { Run-Script "Update-Windows.ps1" }
                        "3" { Run-Script "update.ps1" }
                    }
                }
            }
            "2" {
                while ($true) {
                    Clear-Host; Write-Host "=== Disk & Storage ===" -ForegroundColor Cyan
                    Write-Host "1. Monitor Disk Space"; Write-Host "2. Shrink WSL VHDX"; Write-Host "B. Back"
                    $s = Read-Host "Select"; if ($s -eq 'B') { break }
                    switch ($s) {
                        "1" { Run-Script "Monitor-DiskSpace.ps1" }
                        "2" { Run-Script "shrink_wsl.ps1" }
                    }
                }
            }
            "3" { Show-NetworkMenu }
            "4" { Show-ServiceMenu }
            "5" { Show-HealthMenu }
            "6" { Show-ProcessMenu }
            "7" { Show-SecurityFileMenu }
            "8" { Show-LoggingMenu }
            "Q" { exit }
            "q" { exit }
        }
    }
}

# Run
Show-MainMenu
