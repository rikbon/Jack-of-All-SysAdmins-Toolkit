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
$Version = "2.2.0"
$ReleaseDir = Join-Path $PSScriptRoot "Release"
$SourceDir = $PSScriptRoot
$RootDir   = Split-Path $SourceDir -Parent

# Windows-classic zip name (kept for back-compat).
$ClassicZipName = "SysAdminToolbox_v$Version.zip"
$ClassicZipPath = Join-Path $ReleaseDir $ClassicZipName

# Canonical asset names used by install.ps1 / install.sh one-liners.
$WindowsZipName = "Jack-of-All-SysAdmins-Toolkit-windows.zip"
$WindowsZipPath = Join-Path $ReleaseDir $WindowsZipName
$LinuxTarGzName = "Jack-of-All-SysAdmins-Toolkit-linux.tar.gz"
$LinuxTarGzPath = Join-Path $ReleaseDir $LinuxTarGzName

# Cleanup previous release
if (Test-Path $ReleaseDir) {
    Remove-Item $ReleaseDir -Recurse -Force
}
New-Item -Path $ReleaseDir -ItemType Directory | Out-Null
$StagingDir = Join-Path $ReleaseDir "SysAdminToolbox"
New-Item -Path $StagingDir -ItemType Directory | Out-Null

Write-Host "Building version $Version..." -ForegroundColor Cyan

# 1. Copy scripts from this (Windows) folder, excluding build/dev files.
Write-Host "Copying Windows scripts..."
Get-ChildItem -Path $SourceDir -Filter "*.*" | Where-Object {
    ($_.Extension -eq ".ps1" -or $_.Extension -eq ".bat" -or $_.Extension -eq ".md") -and
    ($_.Name -ne "build.ps1") -and
    ($_.Name -notlike "task.md") -and
    ($_.Name -notlike "implementation_plan.md") -and
    ($_.Name -notlike "feature_suggestions.md")
} | Copy-Item -Destination $StagingDir

# 2. Top-level files so the Windows zip carries README / LICENSE / installers.
foreach ($top in @("README.md", "LICENSE.md", "RELEASE_NOTES.md", "install.sh", "install.ps1")) {
    $p = Join-Path $RootDir $top
    if (Test-Path $p) { Copy-Item -Path $p -Destination $StagingDir }
}

# 3. Copy docs folder (this lives next to Windows/, i.e. at $RootDir/docs).
if (Test-Path (Join-Path $RootDir "docs")) {
    Write-Host "Copying documentation..."
    Copy-Item -Path (Join-Path $RootDir "docs") -Destination $StagingDir -Recurse
}

# 4. Windows ZIP — classic name + the canonical one.
Write-Host "Creating archive: $ClassicZipName"
Compress-Archive -Path "$StagingDir\*" -DestinationPath $ClassicZipPath -Force
Copy-Item -Path $ClassicZipPath -Destination $WindowsZipPath -Force

# 5. Linux tarball / zip fallback — the Linux installer installs to
#    /opt/sysadmin-toolbox/ and needs top-level Linux/ + README/LICENSE/docs.
$LinuxStagingDir = Join-Path $ReleaseDir "linux-dist"
if (Test-Path $LinuxStagingDir) { Remove-Item $LinuxStagingDir -Recurse -Force }
New-Item -Path $LinuxStagingDir -ItemType Directory | Out-Null

$LinuxSrc = Join-Path $RootDir "Linux"
if (Test-Path $LinuxSrc) {
    Write-Host "Copying Linux scripts..."
    Copy-Item -Path (Join-Path $LinuxSrc "*") -Destination $LinuxStagingDir -Recurse -Force
} else {
    Write-Warning "Linux source dir not found at $LinuxSrc"
}
foreach ($top in @("README.md", "LICENSE.md", "RELEASE_NOTES.md", "install.sh")) {
    $p = Join-Path $RootDir $top
    if (Test-Path $p) { Copy-Item -Path $p -Destination $LinuxStagingDir }
}
if (Test-Path (Join-Path $RootDir "docs")) {
    Copy-Item -Path (Join-Path $RootDir "docs") -Destination $LinuxStagingDir -Recurse
}

Write-Host "Creating archive: $LinuxTarGzName"
$hasTar = $false
try {
    $null = Get-Command tar -ErrorAction Stop
    $hasTar = $true
} catch { $hasTar = $false }

if ($hasTar) {
    Push-Location $LinuxStagingDir
    try {
        & tar -czf $LinuxTarGzPath .
        Write-Host "tar produced $LinuxTarGzPath"
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "tar not on PATH; producing a .zip fallback for Linux ($($LinuxTarGzName -replace '\.tar\.gz$','.zip'))."
    Compress-Archive -Path "$LinuxStagingDir\*" -DestinationPath ($LinuxTarGzName -replace '\.tar\.gz$','.zip') -Force
}

Write-Host ""
Write-Host "Build Complete! ($Version)" -ForegroundColor Green
Write-Host "  Windows ZIP       -> $ClassicZipPath"
Write-Host "  Windows ZIP (2)   -> $WindowsZipPath"
Write-Host "  Linux tarball     -> $LinuxTarGzPath"
Write-Host ""
Write-Host "Publish ALL of the above as GitHub Release assets." -ForegroundColor Yellow
