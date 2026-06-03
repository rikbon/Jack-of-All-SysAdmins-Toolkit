<#
.SYNOPSIS
    Monitors file integrity using SHA256 hashes.
.DESCRIPTION
    Checks a specified file or directory against a known baseline.
#>
[CmdletBinding()]
param()

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Write-Log "Starting File Integrity Monitor..." "INFO"

$BaselinePath = Join-Path $PSScriptRoot "baseline_hashes.csv"

Write-Host "1. Create Baseline for a File/Directory"
Write-Host "2. Verify Files against Baseline"
Write-Host "B. Back"
$choice = Read-Host "Select an option"

if ($choice -eq "1") {
    $path = Read-Host "Enter path to baseline (File or Directory)"
    if (Test-Path $path) {
        Write-Log "Generating baseline for $path..." "INFO"
        $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            $baseline = @()
            foreach ($file in $files) {
                $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
                $baseline += [PSCustomObject]@{
                    Path = $file.FullName
                    Hash = $hash.Hash
                }
            }
            $baseline | Export-Csv -Path $BaselinePath -NoTypeInformation -Force
            Write-Log "Baseline saved to $BaselinePath." "SUCCESS"
        } elseif (Test-Path $path -PathType Leaf) {
            $hash = Get-FileHash -Path $path -Algorithm SHA256
            [PSCustomObject]@{ Path = $path; Hash = $hash.Hash } | Export-Csv -Path $BaselinePath -NoTypeInformation -Force
            Write-Log "Baseline saved to $BaselinePath." "SUCCESS"
        }
    } else {
        Write-Log "Path not found." "ERROR"
    }
} elseif ($choice -eq "2") {
    if (Test-Path $BaselinePath) {
        Write-Log "Loading baseline from $BaselinePath..." "INFO"
        $baseline = Import-Csv -Path $BaselinePath
        $mismatch = 0
        
        foreach ($entry in $baseline) {
            if (Test-Path $entry.Path) {
                $currentHash = Get-FileHash -Path $entry.Path -Algorithm SHA256
                if ($currentHash.Hash -ne $entry.Hash) {
                    Write-Log "INTEGRITY VIOLATION: Hash mismatch for $($entry.Path)" "ERROR"
                    $mismatch++
                }
            } else {
                Write-Log "INTEGRITY VIOLATION: File missing - $($entry.Path)" "ERROR"
                $mismatch++
            }
        }
        
        if ($mismatch -eq 0) {
            Write-Log "All files match the baseline." "SUCCESS"
        } else {
            Write-Log "Found $mismatch integrity violation(s)." "WARN"
        }
    } else {
        Write-Log "No baseline found. Please create one first." "WARN"
    }
}
