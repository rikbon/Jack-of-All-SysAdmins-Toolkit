<#
.SYNOPSIS
    Manages Windows Firewall rules interactively.
.DESCRIPTION
    Lists active blocking rules, allows searching, and adding simple block rules for applications.
#>
[CmdletBinding()]
param ()

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "Managing Firewall rules requires Administrator privileges. Please run as Administrator."
    exit 1
}

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
                Write-Host "Fetching blocking rules..."
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
                        Write-Host "Rule created successfully: BLOCK $name (Outbound)" -ForegroundColor Green
                    } catch {
                        Write-Error "Failed to create rule: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "Invalid path."
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
                            Write-Host "Rule '$ruleName' Disabled." -ForegroundColor Yellow
                        } else {
                            Enable-NetFirewallRule -Name $ruleName
                            Write-Host "Rule '$ruleName' Enabled." -ForegroundColor Green
                        }
                    } catch {
                        Write-Error "Rule not found or error accessing it."
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
