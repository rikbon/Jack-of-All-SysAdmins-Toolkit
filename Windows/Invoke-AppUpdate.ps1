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

if ($args -contains '-h' -or $args -contains '--help') {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

function Get-WingetUpgradeIds {
    param([string[]]$OutputLines)

    foreach ($line in $OutputLines) {
        $text = [string]$line
        if ([string]::IsNullOrWhiteSpace($text) -or
            $text -match '^\s*(Name|Id|Version|---|No upgrade|This operation)\b' -or
            $text -match '^\s*[-\\s]+$') {
            continue
        }

        # Winget's table uses: Name  Id  Version  Available  Source.
        # Require a package-like ID, not a table header or separator.
        $parts = $text.Trim() -split '\s{2,}' | ForEach-Object { $_.Trim() }
        if ($parts.Count -ge 2) {
            $candidate = $parts[1]
            if ($candidate -notmatch '^(Id|Name|Version|Available|Source)$' -and
                $candidate -match '^[A-Za-z0-9][A-Za-z0-9._-]+$') {
                $candidate
            }
        }
    }
}

function ConvertFrom-WingetUpgradeJson {
    param([string]$JsonOutput)

    if ([string]::IsNullOrWhiteSpace($JsonOutput)) { return @() }
    try {
        $parsed = $JsonOutput | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Log "Winget JSON output could not be parsed; using table fallback." "DEBUG"
        return @()
    }
    return @($parsed | ForEach-Object { $_.Id } | Where-Object { $_ -match '^[A-Za-z0-9][A-Za-z0-9._-]+$' })
}

function Get-WingetUpgrades {
    $jsonOutput = & winget upgrade --accept-source-agreements --disable-interactivity --output json 2>$null | Out-String
    if ($LASTEXITCODE -eq 0) {
        $ids = @(ConvertFrom-WingetUpgradeJson -JsonOutput $jsonOutput)
        if ($ids.Count -gt 0) { return $ids }
    }

    $tableOutput = & winget upgrade --accept-source-agreements --disable-interactivity 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Winget upgrade discovery failed with exit code $LASTEXITCODE." }
    return @(Get-WingetUpgradeIds -OutputLines $tableOutput)
}

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

    # Refresh Winget Sources
    Write-Log "Maintenance: Checking Winget sources..." "INFO"
    $sourceUpdateOut = winget source update 2>&1
    $sourceUpdateStr = $sourceUpdateOut | Out-String

    if ($LASTEXITCODE -ne 0 -or $sourceUpdateStr -match "0x80190194" -or $sourceUpdateStr -match "404") {
        Write-Log "Winget source corruption detected. Resetting sources..." "WARN"
        winget source reset --force | Out-Null
        winget source update | Out-Null
    }Write-Log "Checking for available updates simultaneously (Winget & Chocolatey)..." "INFO"
    # One job per package manager, not per package: discovery for both runs
    # concurrently, and the result is reused instead of invoking winget twice.
    $wingetJob = Start-Job -ScriptBlock {
        winget upgrade --accept-source-agreements --disable-interactivity --output json 2>$null | Out-String
    }

    $chocoJob = $null
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $chocoJob = Start-Job -ScriptBlock { choco outdated -r 2>&1 | Out-String }
    }

    $jobsToWait = @($wingetJob)
    if ($chocoJob) { $jobsToWait += $chocoJob }
    Wait-Job $jobsToWait | Out-Null

    $wingetJsonOutput = Receive-Job $wingetJob
    Remove-Job $wingetJob

    if ($chocoJob) {
        $chocoOut = Receive-Job $chocoJob
        Remove-Job $chocoJob
    }

    # Parse what the job already produced; only fall back to a second winget
    # invocation when the JSON output is unusable.
    try {
        $idsToUpgrade = @(ConvertFrom-WingetUpgradeJson -JsonOutput $wingetJsonOutput)
        if ($idsToUpgrade.Count -eq 0) {
            $idsToUpgrade = @(Get-WingetUpgrades)
        }
    }
    catch {
        Write-Log "Winget upgrade discovery failed: $($_.Exception.Message)" "ERROR"
        $idsToUpgrade = @()
    }

    if ($idsToUpgrade.Count -eq 0) {
        Write-Log "No upgradable Winget packages identified." "INFO"
    }
    else {
        Write-Log "Found $($idsToUpgrade.Count) packages to upgrade." "INFO"
        
        $totalWinget = $idsToUpgrade.Count
        $currentWinget = 0

        if ($ListOnly) {
            foreach ($id in $idsToUpgrade) { Write-Log "  [UPDATE] $id" "INFO" }
        }
        else {
            # Treat SkipPackages as a literal list: -match would treat each ID
            # as a regular expression (7-Zip would match unrelated packages).
            $skipList = @()
            if ($SkipPackages) {
                $skipList = @($SkipPackages -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }
            foreach ($id in $idsToUpgrade) {
                $currentWinget++
                Write-Progress -Activity "Upgrading Applications (Winget)" -Status "Upgrading $id" -PercentComplete (($currentWinget / $totalWinget) * 100)
                
                if ($skipList -contains $id) {
                    Write-Log "Skipping $id (SkipPackages)" "INFO"
                    continue
                }

                Write-Log "Upgrading $id..." "INFO"
                # Running iteratively allows one failure (404) to not block others
                $wingetArgs = @(
                    "upgrade"
                    "--id", $id
                    "--accept-package-agreements"
                    "--accept-source-agreements"
                    "--include-unknown"
                )
                if ($QuietMode) { $wingetArgs += "--silent" }
                
                & winget @wingetArgs
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Failed to upgrade $id (Exit Code: $LASTEXITCODE)." "WARN"
                }
                else {
                    Write-Log "Successfully upgraded $id." "SUCCESS"
                }
            }
            Write-Progress -Activity "Upgrading Applications (Winget)" -Completed
        }
    }
}

# --- Chocolatey Upgrade ---
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Log "Chocolatey detected. Processing updates..." "INFO"
    try {
        if ($ListOnly) {
            if (-not $chocoOut) {
                # Fallback if winget was not found and parallel job didn't run
                $chocoOut = choco outdated -r 2>&1 | Out-String
            }
            Write-Log "Chocolatey Outdated:" "INFO"
            $chocoOut -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Write-Log "  $_" "INFO" }
        }
        else {
            Write-Progress -Activity "Upgrading Applications (Chocolatey)" -Status "Upgrading all packages" -PercentComplete 50
            Write-Log "Upgrading all Chocolatey packages..." "INFO"
            $chocoArgs = @("upgrade", "all", "-y")
            if ($QuietMode) { $chocoArgs += "-q" }
            & choco @chocoArgs
            Write-Log "Chocolatey upgrade complete." "SUCCESS"
            Write-Progress -Activity "Upgrading Applications (Chocolatey)" -Completed
        }
    }
    catch {
        Write-Log "Chocolatey upgrade failed: $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Application update process finished." "SUCCESS"
