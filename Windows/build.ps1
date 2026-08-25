<#
.SYNOPSIS
    Builds the distribution ZIP file for SysAdmin Toolbox.
.DESCRIPTION
    Creates a 'Release' folder, copies necessary files (scripts, docs, license),
    excludes dev artifacts, and zips the result.
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
}
finally {
    if (Test-Path -LiteralPath $StagingRoot) {
        Remove-Item -LiteralPath $StagingRoot -Recurse -Force
    }
}

Write-Host "Build complete. Archives available in $ReleaseDir" -ForegroundColor Green
