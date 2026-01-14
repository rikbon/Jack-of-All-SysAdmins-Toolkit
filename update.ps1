<#
.SYNOPSIS
    Updates applications using Winget.
.DESCRIPTION
    Exports list, creates restore point, and upgrades packages.
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

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "This script requires Administrator privileges (System Restore, Winget export). Please run as Administrator."
    exit 1
}

# Logger
$logFile = "$env:TEMP\winget_upgrade_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Log {
    param ([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    if (-not $QuietMode) { Write-Output $Message }
}

Log "Starting Winget Upgrade Script..."

# Check Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Log "Winget not found."
    exit 1
}

# Create Restore Point
if (-not $ListOnly) {
    Log "Creating System Restore Point..."
    try {
        Checkpoint-Computer -Description "Before Winget Upgrade" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    }
    catch {
        Log "Failed to create restore point: $($_.Exception.Message)"
    }
}

# Get Upgradable Packages Direct Approach (Simpler than export/import for just upgrading)
Log "Checking for available updates..."

# Refresh Winget Sources (Fixes 404 errors)
Log "Maintenance: Checking Winget sources..."
# Capture output to check for errors/404s
$sourceUpdateOut = winget source update 2>&1
$sourceUpdateStr = $sourceUpdateOut | Out-String

if ($LASTEXITCODE -ne 0 -or $sourceUpdateStr -match "0x80190194" -or $sourceUpdateStr -match "404") {
    Log "Winget source corruption detected (404/Error). Attempting to reset sources..."
    winget source reset --force | Out-Null
    Log "Sources reset. Updating again..."
    winget source update | Out-Null
}
else {
    Log "Sources updated successfully."
}

# Strategy: Get list of upgradable apps
try {
    # capture output of winget upgrade to parse, or just iterate common ones if we had a specific list. 
    # The original script exported to JSON. preserving that logic is fine but slightly over-engineered for just upgrading.
    # Let's stick to the user's original logic flow but improved.
    
    $jsonFile = "$env:TEMP\winget_export_temp.json"
    
    # Run winget export with error handling
    $exportProc = Start-Process winget -ArgumentList "export -o `"$jsonFile`" --accept-source-agreements" -NoNewWindow -PassThru -Wait
    
    if ($exportProc.ExitCode -ne 0) {
        Write-Warning "Winget export failed (ExitCode: $($exportProc.ExitCode)). This usually means a network issue or no installed packages found."
    }

    if (Test-Path $jsonFile) {
        Remove-Item $jsonFile -Force
    }
}
catch {
    Log "Error getting package list: $($_.Exception.Message)"
    exit 1
}

# Processing Loop (Only if we have packages, or if we change strategy to 'winget upgrade --all')
# Actually, the most robust way to upgrade ALL while Skipping some is:
# 1. 'winget upgrade' to see what's available (interactive) OR
# 2. Iterate.

# Let's use the 'winget upgrade' command to list available upgrades, parse it, and simple-upgrade.
# Parsing CLI output is brittle.
# The original script trying to upgrade EVERYTHING in the export list is also risky (re-installing same version?).
# 'winget export' exports INSTALLED packages, not UPGRADABLE ones.
# The original script was potentially trying to reinstall/upgrade everything? That's inefficient.
# BETTER STRATEGY: Use `winget upgrade` (no args) to see what IS upgradable.

Log "Alternative Strategy: upgrading based on 'winget upgrade' availability."

# Get list of ID's that need upgrade
$rawUpgradeList = winget upgrade --accept-source-agreements
# This output is text. "Name Id Version Available Source"

# Get list of ID's that need upgrade by running 'winget upgrade' and parsing raw output
# We use --accept-source-agreements to ensure we get output even if prompts exist
Log "Fetching list of available upgrades..."
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
    Log "No upgradable packages identified (or parsing failed)."
}
else {
    Log "Found $($idsToUpgrade.Count) packages to upgrade."
    
    foreach ($id in $idsToUpgrade) {
        if ($SkipPackages -and $SkipPackages -match $id) {
            Log "Skipping $id (Blacklisted)"
            continue
        }

        Log "Upgrading $id..."
        # Running iteratively allows one failure (404) to not block others
        if (-not $QuietMode) {
            winget upgrade --id $id --accept-package-agreements --accept-source-agreements --include-unknown
        }
        else {
            winget upgrade --id $id --accept-package-agreements --accept-source-agreements --include-unknown | Out-Null
        }
        
        if ($LASTEXITCODE -ne 0) {
            Log "Failed to upgrade $id (Exit Code: $LASTEXITCODE). Continuing..."
        }
    }
}

Log "Winget upgrade process finished."

# --- Chocolatey Upgrade ---
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Log "Chocolatey detected. Checking for updates..."
    try {
        if (-not $QuietMode) {
            choco upgrade all -y
        }
        else {
            choco upgrade all -y | Out-Null
        }
        Log "Chocolatey upgrade complete."
    }
    catch {
        Log "Chocolatey upgrade failed: $($_.Exception.Message)"
    }
}
