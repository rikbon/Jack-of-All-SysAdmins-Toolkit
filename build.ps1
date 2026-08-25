[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$buildScript = Join-Path $PSScriptRoot "Windows/build.ps1"

if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
    throw "Build script not found: $buildScript"
}

$arguments = @{}
if ($Version) {
    $arguments.Version = $Version
}
if ($OutputDirectory) {
    $arguments.OutputDirectory = $OutputDirectory
}

& $buildScript @arguments
if (-not $?) {
    throw "Platform build failed."
}
