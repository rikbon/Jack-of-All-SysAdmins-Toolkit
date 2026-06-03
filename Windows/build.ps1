<#
.SYNOPSIS
    Builds the distribution ZIP file for SysAdmin Toolbox.
.DESCRIPTION
    Creates a 'Release' folder, copies necessary files (scripts, docs, license),
    excludes dev artifacts, and zips the result.
#>
$Version = "1.3.0"
$ReleaseDir = Join-Path $PSScriptRoot "Release"
$SourceDir = $PSScriptRoot
$ZipName = "SysAdminToolbox_v$Version.zip"
$ZipPath = Join-Path $ReleaseDir $ZipName

# Cleanup previous release
if (Test-Path $ReleaseDir) {
    Remove-Item $ReleaseDir -Recurse -Force
}
New-Item -Path $ReleaseDir -ItemType Directory | Out-Null
$StagingDir = Join-Path $ReleaseDir "SysAdminToolbox"
New-Item -Path $StagingDir -ItemType Directory | Out-Null

Write-Host "Building version $Version..." -ForegroundColor Cyan

# 1. Copy Scripts (*.ps1, *.bat)
Write-Host "Copying scripts..."
Get-ChildItem -Path $SourceDir -Filter "*.*" | Where-Object { 
    ($_.Extension -eq ".ps1" -or $_.Extension -eq ".bat" -or $_.Extension -eq ".md") -and
    ($_.Name -ne "build.ps1") -and # Exclude build script
    ($_.Name -notlike "task.md") -and # Exclude dev task list
    ($_.Name -notlike "implementation_plan.md") -and # Exclude dev plan
    ($_.Name -notlike "feature_suggestions.md") # Exclude notes
} | Copy-Item -Destination $StagingDir

# 2. Copy Docs folder
if (Test-Path (Join-Path $SourceDir "docs")) {
    Write-Host "Copying documentation..."
    Copy-Item -Path (Join-Path $SourceDir "docs") -Destination $StagingDir -Recurse
}

# 3. Zip it up
Write-Host "Creating archive: $ZipName"
Compress-Archive -Path "$StagingDir\*" -DestinationPath $ZipPath -Force

Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Release available at: $ZipPath"
