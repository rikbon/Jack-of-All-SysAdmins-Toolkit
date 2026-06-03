# --- Globals.ps1 ---
# This file contains shared configurations and functions for the Jack-of-All-SysAdmins-Toolkit.

# --- Configuration ---
$LogDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "Toolkit_$(Get-Date -Format 'yyyyMMdd').log"

# --- Functions ---

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    
    # Append to log file
    try {
        $logEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Fallback if log file is inaccessible
    }

    # Color mapping
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    Write-Host $logEntry -ForegroundColor $color
}

function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-Admin)) {
        Write-Log "This script requires Administrator privileges. Please run as Administrator." "ERROR"
        exit 1
    }
}

# Export functions if needed, but dot-sourcing is fine for PS scripts.
