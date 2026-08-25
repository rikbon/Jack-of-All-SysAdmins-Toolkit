<#
.SYNOPSIS
    Safely cleans common Windows temporary files and optionally launches Cleanup Manager.
.DESCRIPTION
    Removes contents, not the configured cleanup directories, from standard temporary
    locations. Locked files are skipped. Recycle Bin cleanup is opt-in. Windows Cleanup
    Manager can be launched in the background with -LaunchWindowsCleanup.
.PARAMETER IncludeRecycleBin
    Empty the current user's Recycle Bin after confirmation unless -Confirm:$false is used.
.PARAMETER IncludeWindowsUpdateCache
    Clean the Windows Update download cache. This stops and starts services and requires admin rights.
.PARAMETER LaunchWindowsCleanup
    Launch cleanmgr.exe /verylowdisk in the background after the local cleanup.
.PARAMETER WhatIf
    Show what would be removed without deleting anything.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$IncludeRecycleBin,
    [switch]$IncludeWindowsUpdateCache,
    [switch]$LaunchWindowsCleanup
)

$ErrorActionPreference = 'Stop'

if ($args -contains '-h' -or $args -contains '--help') {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

$GlobalsPath = Join-Path $PSScriptRoot 'Globals.ps1'
if (-not (Test-Path -LiteralPath $GlobalsPath -PathType Leaf)) {
    throw "Required file not found: $GlobalsPath"
}
. $GlobalsPath

Assert-Admin

function Get-CleanupSize {
    param([System.IO.FileSystemInfo[]]$Items)

    $files = @($Items | Where-Object { -not $_.PSIsContainer })
    if ($files.Count -eq 0) { return 0 }
    return [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
}

function Remove-CleanupContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [switch]$Recurse
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq [IO.Path]::GetPathRoot($Path)) {
        throw "Refusing to clean an empty path or filesystem root: '$Path'"
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Log "Cleanup path not found: $Path" 'DEBUG'
        return
    }

    $items = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
    $sizeMB = Get-CleanupSize -Items $items
    Write-Log "Found $($items.Count) item(s), approximately $sizeMB MB, in $Path." 'INFO'

    foreach ($item in $items) {
        if ($item.PSIsContainer -and -not $Recurse) { continue }
        if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove')) {
            try {
                Remove-Item -LiteralPath $item.FullName -Recurse:$Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Log "Skipped $($item.FullName): $($_.Exception.Message)" 'DEBUG'
            }
        }
    }
}

Write-Log 'Starting Windows disk cleanup.' 'INFO'

$cleanupPaths = @(
    @{ Path = $env:TEMP; Recurse = $true; Description = 'Current user temporary files' },
    @{ Path = (Join-Path $env:WINDIR 'Temp'); Recurse = $true; Description = 'Windows temporary files' },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\INetCache'); Recurse = $true; Description = 'Current user internet cache' },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Explorer'); Recurse = $false; Description = 'Explorer thumbnail/icon cache' }
)

foreach ($target in $cleanupPaths) {
    Write-Log "Cleaning $($target.Description): $($target.Path)" 'INFO'
    Remove-CleanupContents -Path $target.Path -Recurse:$target.Recurse
}

if ($IncludeWindowsUpdateCache) {
    $downloadPath = Join-Path $env:WINDIR 'SoftwareDistribution\Download'
    Write-Log "Cleaning Windows Update download cache: $downloadPath" 'WARN'
    if ($PSCmdlet.ShouldProcess('Windows Update services', 'Stop and restart')) {
        try {
            Stop-Service -Name wuauserv, bits -Force -ErrorAction Stop
            Remove-CleanupContents -Path $downloadPath -Recurse
        }
        finally {
            Start-Service -Name bits -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
    }
}

if ($IncludeRecycleBin) {
    if ($PSCmdlet.ShouldProcess('Current user Recycle Bin', 'Empty')) {
        try {
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Log 'Current user Recycle Bin emptied.' 'SUCCESS'
        }
        catch {
            Write-Log "Recycle Bin cleanup skipped: $($_.Exception.Message)" 'WARN'
        }
    }
}

if ($LaunchWindowsCleanup) {
    $cleanmgr = Join-Path $env:WINDIR 'System32\cleanmgr.exe'
    if (Test-Path -LiteralPath $cleanmgr -PathType Leaf) {
        Write-Log 'Launching Windows Cleanup Manager in the background.' 'INFO'
        Start-Process -FilePath $cleanmgr -ArgumentList '/verylowdisk' -WindowStyle Hidden
    }
    else {
        Write-Log 'cleanmgr.exe was not found; Windows Cleanup Manager was not launched.' 'WARN'
    }
}

Write-Progress -Activity 'Disk Cleanup' -Completed
Write-Log 'Windows disk cleanup completed.' 'SUCCESS'
