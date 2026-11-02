<#
.SYNOPSIS
    Builds distribution archives for SysAdmin Toolbox.
.DESCRIPTION
    Creates platform archives in a Release folder using the repository VERSION
    file unless a version or output directory is supplied.
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
$ReleaseDir = if ($OutputDirectory) { $OutputDirectory } else { Join-Path $RepositoryRoot "Release" }
$Platforms = @("Windows", "Linux", "macOS")
$StagingRoot = Join-Path $ReleaseDir ".staging"

function Copy-IfExists {
    param([string]$Source, [string]$Destination)
    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    }
}

# Remove a previous family of platform archives written by earlier builds
# (same platform stem, older version) so they don't accumulate alongside the
# new ones. Unrelated files placed in Release by hand stay where they were —
# deleting the whole directory every rebuild would clobber local customizations.
if (Test-Path -LiteralPath $ReleaseDir) {
    Get-ChildItem -LiteralPath $ReleaseDir -Filter 'SysAdminToolbox_*_v*.zip' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'SysAdminToolbox_(Windows|Linux|macOS)\\' } |
        Remove-Item -Force
}
New-Item -Path $ReleaseDir -ItemType Directory -Force | Out-Null
New-Item -Path $StagingRoot -ItemType Directory -Force | Out-Null

Write-Host "Building SysAdminToolbox v$Version..." -ForegroundColor Cyan

try {
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

    $windowsZipPath = Join-Path $ReleaseDir "SysAdminToolbox_Windows_v$Version.zip"
    $canonicalWindowsPath = Join-Path $ReleaseDir "Jack-of-All-SysAdmins-Toolkit-windows.zip"
    if (Test-Path -LiteralPath $windowsZipPath) {
        Copy-Item -LiteralPath $windowsZipPath -Destination $canonicalWindowsPath -Force
    }

    $linuxZipPath = Join-Path $ReleaseDir "SysAdminToolbox_Linux_v$Version.zip"
    $canonicalLinuxPath = Join-Path $ReleaseDir "Jack-of-All-SysAdmins-Toolkit-linux.tar.gz"
    if (Test-Path -LiteralPath $linuxZipPath) {
        $tar = Get-Command tar -ErrorAction SilentlyContinue
        if ($tar) {
            $linuxRoot = Join-Path $StagingRoot "Linux/SysAdminToolbox_Linux"
            Push-Location $linuxRoot
            try { & tar -czf $canonicalLinuxPath . }
            finally { Pop-Location }
        }
        else {
            Write-Warning "tar not found; canonical Linux tarball was not produced."
        }
    }
}
finally {
    if (Test-Path -LiteralPath $StagingRoot) {
        Remove-Item -LiteralPath $StagingRoot -Recurse -Force
    }
}

Write-Host "Build complete. Archives available in $ReleaseDir" -ForegroundColor Green
