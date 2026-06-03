<#
.SYNOPSIS
    Shrinks WSL 2 VHDX files.
.DESCRIPTION
    Shuts down WSL, finds VHDX files for all distros, and runs Optimize-VHD.

#>
[CmdletBinding()]
param ()

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

# --- Prerequisite Check ---
if (-not (Get-Command Optimize-VHD -ErrorAction SilentlyContinue)) {
    Write-Log "The 'Optimize-VHD' cmdlet is not available. Please install the Hyper-V PowerShell module." "ERROR"
    exit 1
}

# --- Shutdown WSL ---
Write-Log "Preparing to shrink WSL disks..." "INFO"
Write-Log "Shutting down WSL..." "INFO"
wsl --shutdown

# Function to get VHDX Path
function Get-WslVhdXPath {
    param([string]$DistributionName)
    try {
        $regPath = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | 
        Where-Object { ($_.GetValue("DistributionName")) -eq $DistributionName }
        if ($regPath) {
            $basePath = $regPath.GetValue("BasePath")
            if ($basePath) { return Join-Path -Path $basePath -ChildPath "ext4.vhdx" }
        }
    }
    catch {
        Write-Log "Error finding VHDX for $DistributionName" "DEBUG"
    }
    return $null
}

# Get Distros using wsl -l -q
# Ensure UTF-8 handling if needed, though usually standard output works
$wslList = (wsl --list --quiet) -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$distrosToShrink = $wslList.Count
$currentShrinkDistro = 0

foreach ($distroRaw in $wslList) {
    $currentShrinkDistro++
    # Clean up distro name (remove null bytes if any, trim)
    $distroName = $distroRaw.Trim().Replace("`0", "")
    
    if (-not $distroName) { continue }

    Write-Progress -Activity "Shrinking WSL Disks" -Status "Processing: $distroName" -PercentComplete (($currentShrinkDistro / $distrosToShrink) * 100)

    Write-Log "Processing: $distroName" "INFO"
    $vhdxPath = Get-WslVhdXPath -DistributionName $distroName

    if ($vhdxPath -and (Test-Path $vhdxPath)) {
        $initialBytes = (Get-Item $vhdxPath).Length
        $initialGB = [math]::Round($initialBytes / 1GB, 2)
        Write-Log "  Found VHDX: $vhdxPath (Size: $initialGB GB)" "INFO"
            
        Write-Log "  Optimizing..." "INFO"
        try {
            Optimize-VHD -Path $vhdxPath -Mode Full -ErrorAction Stop
                
            $finalBytes = (Get-Item $vhdxPath).Length
            $finalGB = [math]::Round($finalBytes / 1GB, 2)
            $savedMB = [math]::Round(($initialBytes - $finalBytes) / 1MB, 2)
                
            Write-Log "  Optimization complete." "SUCCESS"
            Write-Log "  Before: $initialGB GB | After: $finalGB GB | Reclaimed: $savedMB MB" "SUCCESS"
        }
        catch {
            Write-Log "  Failed to optimize: $($_.Exception.Message)" "ERROR"
        }
    }
    else {
        Write-Log "  Could not locate VHDX file for '$distroName'." "WARN"
    }
}
Write-Progress -Activity "Shrinking WSL Disks" -Completed

Write-Log "WSL disk shrink process complete." "SUCCESS"