<#
.SYNOPSIS
    Updates applications using Winget and Chocolatey.
.DESCRIPTION
    Creates restore point and upgrades packages.
.PARAMETER QuietMode
    Minimal output.
.PARAMETER ListOnly
    Only list available updates.
.PARAMETER SkipPackages
    Comma-separated list of package IDs to skip.
#>
[CmdletBinding()]
param (
    [switch]$QuietMode,
    [switch]$ListOnly,
    [string]$SkipPackages
)

$ErrorActionPreference = "Stop"

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

Write-Log "Starting Application Update Process..." "INFO"

# Check Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found. Skipping Winget updates." "WARN"
}
else {
    # Create Restore Point
    if (-not $ListOnly) {
        Write-Log "Creating System Restore Point..." "INFO"
        try {
            Checkpoint-Computer -Description "Before Winget Upgrade" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Log "Restore point created." "SUCCESS"
        }
        catch {
            Write-Log "Failed to create restore point: $($_.Exception.Message)" "WARN"
        }
    }

    Write-Log "Checking for available Winget updates..." "INFO"

    # Refresh Winget Sources
    Write-Log "Maintenance: Checking Winget sources..." "INFO"
    $sourceUpdateOut = winget source update 2>&1
    $sourceUpdateStr = $sourceUpdateOut | Out-String

    if ($LASTEXITCODE -ne 0 -or $sourceUpdateStr -match "0x80190194" -or $sourceUpdateStr -match "404") {
        Write-Log "Winget source corruption detected. Resetting sources..." "WARN"
        winget source reset --force | Out-Null
        winget source update | Out-Null
    }

    # Get list of ID's that need upgrade
    $upgradeOutput = winget upgrade --accept-source-agreements 2>&1 | Out-String

    # Parse the output to find IDs
    # Output format is usually: Name | Id | Version | Available | Source
    # We look for lines that look like package entries (not headers)
    $lines = $upgradeOutput -split "`r`n"
    $idsToUpgrade = @()

    foreach ($line in $lines) {
        # Skip headers/empty lines
        if ($line -match "^Name" -or $line -match "^-" -or [string]::IsNullOrWhiteSpace($line)) { continue }
        
        # Splitting by multiple spaces is a decent heuristic.
        $parts = $line -split "\s{2,}"
        if ($parts.Count -ge 2) {
            # The ID is usually the second column
            $id = $parts[1]
            
            # Validation: ID shouldn't be a version number or too short.
            # winget IDs usually contain dots or are alphanumeric.
            if ($id -match "\." -and $id.Length -gt 2) {
                $idsToUpgrade += $id
            }
        }
    }

    if ($idsToUpgrade.Count -eq 0) {
        Write-Log "No upgradable Winget packages identified." "INFO"
    }
    else {
        Write-Log "Found $($idsToUpgrade.Count) packages to upgrade." "INFO"
        
        if ($ListOnly) {
            foreach ($id in $idsToUpgrade) { Write-Log "  [UPDATE] $id" "INFO" }
        }
        else {
            foreach ($id in $idsToUpgrade) {
                if ($SkipPackages -and $SkipPackages -match $id) {
                    Write-Log "Skipping $id (Skiplist)" "INFO"
                    continue
                }

                Write-Log "Upgrading $id..." "INFO"
                # Running iteratively allows one failure (404) to not block others
                $wingetArgs = "upgrade --id $id --accept-package-agreements --accept-source-agreements --include-unknown"
                if ($QuietMode) { $wingetArgs += " --silent" }
                
                Invoke-Expression "winget $wingetArgs"
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Failed to upgrade $id (Exit Code: $LASTEXITCODE)." "WARN"
                }
                else {
                    Write-Log "Successfully upgraded $id." "SUCCESS"
                }
            }
        }
    }
}

# --- Chocolatey Upgrade ---
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Log "Chocolatey detected. Checking for updates..." "INFO"
    try {
        if ($ListOnly) {
            choco outdated
        }
        else {
            $chocoArgs = "upgrade all -y"
            if ($QuietMode) { $chocoArgs += " -q" }
            Invoke-Expression "choco $chocoArgs"
            Write-Log "Chocolatey upgrade complete." "SUCCESS"
        }
    }
    catch {
        Write-Log "Chocolatey upgrade failed: $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Application update process finished." "SUCCESS"
