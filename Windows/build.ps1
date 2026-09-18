<#
.SYNOPSIS
    Builds the distribution archives for SysAdmin Toolbox.
.DESCRIPTION
    Creates a 'Release' folder, copies necessary files (scripts, docs, license,
    installers), excludes dev artifacts, and produces multiple archive flavours.

    The archive names MUST match what install.ps1 / install.sh download:
      Jack-of-All-SysAdmins-Toolkit-windows.zip      (Windows, zip, classic)
      Jack-of-All-SysAdmins-Toolkit-linux.tar.gz     (Linux,   tar.gz)
    publish ALL of these as GitHub Release assets or the one-liner installers will
    fall back to downloading the main branch archive.
#>
[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path
if (-not $Version) {
    $Version = (Get-Content -LiteralPath (Join-Path $RepositoryRoot "VERSION") -Raw).Trim()
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid toolkit version: $Version"
}
$ReleaseDir = if ($OutputDirectory) { (Resolve-Path $OutputDirectory -ErrorAction SilentlyContinue)?.Path ?? $OutputDirectory } else { Join-Path $RepositoryRoot "Release" }
$Platforms = @("Windows", "Linux", "macOS")
$StagingRoot = Join-Path $ReleaseDir ".staging"

function Copy-IfExists {
    param([string]$Source, [string]$Destination)
    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    }
}

if (Test-Path -LiteralPath $ReleaseDir) {
    Remove-Item -LiteralPath $ReleaseDir -Recurse -Force
}
New-Item -Path $ReleaseDir -ItemType Directory -Force | Out-Null
New-Item -Path $StagingRoot -ItemType Directory -Force | Out-Null

Write-Host "Building SysAdminToolbox v$Version..." -ForegroundColor Cyan

try {
    # Build each platform archive.
    foreach ($platform in $Platforms) {
        $platformSource = Join-Path $RepositoryRoot $platform
        $platformStaging = Join-Path $StagingRoot $platform
        $archiveRoot = Join-Path $platformStaging "SysAdminToolbox_$platform"
        $zipName = "SysAdminToolbox_${platform}_v$Version.zip"
        $zipPath = Join-Path $ReleaseDir $zipName

        if (-not (Test-Path -LiteralPath $platformSource -PathType Container)) {
            Write-Warning "Skipping ${platform}: source directory not found at $platformSource"
            continue
        }

        New-Item -Path $archiveRoot -ItemType Directory -Force | Out-Null
        Copy-IfExists (Join-Path $RepositoryRoot "README.md") $archiveRoot
        Copy-IfExists (Join-Path $RepositoryRoot "LICENSE.md") $archiveRoot
        Copy-IfExists (Join-Path $RepositoryRoot "RELEASE_NOTES.md") $archiveRoot
        Copy-IfExists (Join-Path $RepositoryRoot "VERSION") $archiveRoot
        Copy-IfExists (Join-Path $RepositoryRoot "docs") (Join-Path $archiveRoot "docs")
        Copy-IfExists $platformSource (Join-Path $archiveRoot $platform)

        Write-Host "Creating $zipName..."
        Compress-Archive -Path (Join-Path $archiveRoot "*") -DestinationPath $zipPath -Force
    }

    # Canonical asset copies for one-click installers
    $windowsZip = Join-Path $ReleaseDir "SysAdminToolbox_Windows_v$Version.zip"
    $windowsCanonical = Join-Path $ReleaseDir "Jack-of-All-SysAdmins-Toolkit-windows.zip"
    if (Test-Path -LiteralPath $windowsZip) {
        Copy-Item -LiteralPath $windowsZip -Destination $windowsCanonical -Force
    }

    $linuxZip = Join-Path $ReleaseDir "SysAdminToolbox_Linux_v$Version.zip"
    $canonicalLinuxZip = Join-Path $ReleaseDir "Jack-of-All-SysAdmins-Toolkit-linux.zip"
    if (Test-Path -LiteralPath $linuxZip) {
        Copy-Item -LiteralPath $linuxZip -Destination $canonicalLinuxZip -Force
    }

    $linuxTarGz = Join-Path $ReleaseDir "Jack-of-All-SysAdmins-Toolkit-linux.tar.gz"
    $hasTar = $false
    try {
        $null = Get-Command tar -ErrorAction Stop
        $hasTar = $true
    } catch { $hasTar = $false }

    if ($hasTar) {
        $linuxArchiveRoot = Join-Path (Join-Path $StagingRoot "Linux") "SysAdminToolbox_Linux"
        if (Test-Path -LiteralPath $linuxArchiveRoot) {
            Push-Location $linuxArchiveRoot
            try {
                & tar -czf $linuxTarGz .
            } finally {
                Pop-Location
            }
        }
    }
}
finally {
    if (Test-Path -LiteralPath $StagingRoot) {
        Remove-Item -LiteralPath $StagingRoot -Recurse -Force
    }
}

Write-Host "Build complete. Archives available in $ReleaseDir" -ForegroundColor Green
