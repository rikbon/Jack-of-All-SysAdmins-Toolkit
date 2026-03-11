<#
.SYNOPSIS
    Manages Windows Firewall rules interactively.
.DESCRIPTION
    Lists active blocking rules, allows searching, and adding simple block rules for applications.
#>
[CmdletBinding()]
param ()

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

function Show-FirewallMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Firewall Manager ===" -ForegroundColor Cyan
        Write-Host "1. List All Active 'BLOCK' Rules"
        Write-Host "2. Search Rules by Name"
        Write-Host "3. Block an Application (.exe)"
        Write-Host "4. Enable/Disable a Rule"
        Write-Host "Q. Quit"
        
        $choice = Read-Host "Select an option"
        switch ($choice) {
            "1" {
                Write-Log "Fetching blocking rules..." "INFO"
                Get-NetFirewallRule | Where-Object { $_.Action -eq 'Block' -and $_.Enabled -eq 'True' } | 
                Select-Object DisplayName, Direction, Profile | Format-Table -AutoSize
                Pause
            }
            "2" {
                $search = Read-Host "Enter search term"
                if ($search) {
                    Get-NetFirewallRule | Where-Object { $_.DisplayName -match $search } | 
                    Select-Object Name, DisplayName, Enabled, Action, Direction | Format-Table -AutoSize
                }
                Pause
            }
            "3" {
                $exePath = Read-Host "Enter full path to .exe to block"
                if ($exePath -and (Test-Path $exePath)) {
                    $name = Split-Path $exePath -Leaf
                    $ruleName = "Block_$name"
                    try {
                        New-NetFirewallRule -DisplayName "BLOCK $name" -Name $ruleName -Program $exePath -Action Block -Direction Outbound -ErrorAction Stop
                        Write-Log "Rule created successfully: BLOCK $name (Outbound)" "SUCCESS"
                    }
                    catch {
                        Write-Log "Failed to create rule: $($_.Exception.Message)" "ERROR"
                    }
                }
                else {
                    Write-Log "Invalid path." "WARN"
                }
                Pause
            }
            "4" {
                $ruleName = Read-Host "Enter Rule Name (internal Name, not DisplayName) to toggle"
                if ($ruleName) {
                    try {
                        $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction Stop
                        if ($rule.Enabled -eq 'True') {
                            Disable-NetFirewallRule -Name $ruleName
                            Write-Log "Rule '$ruleName' Disabled." "WARN"
                        }
                        else {
                            Enable-NetFirewallRule -Name $ruleName
                            Write-Log "Rule '$ruleName' Enabled." "SUCCESS"
                        }
                    }
                    catch {
                        Write-Log "Rule not found or error accessing it." "ERROR"
                    }
                }
                Pause
            }
            "Q" { return }
            "q" { return }
        }
    }
}

Show-FirewallMenu
