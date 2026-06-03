<#
.SYNOPSIS
    Audits the local Administrators group.
.DESCRIPTION
    Lists all members of the local Administrators group and flags any unexpected accounts.
#>
[CmdletBinding()]
param()

$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

Assert-Admin

Write-Log "Starting Admin Audit..." "INFO"

# Define expected default admins (adjust as needed for the environment)
$ExpectedAdmins = @("Administrator", "Domain Admins") 
$WarningCount = 0

try {
    $Admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
    
    Write-Host "`nCurrent Members of 'Administrators' Group:" -ForegroundColor Cyan
    foreach ($admin in $Admins) {
        $name = $admin.Name.Split('\')[-1] # Get just the username part if domain prefixed
        
        if ($name -notin $ExpectedAdmins) {
            Write-Log "FLAGGED: User '$($admin.Name)' is in the Administrators group." "WARN"
            $WarningCount++
        } else {
            Write-Log "OK: User '$($admin.Name)' is an expected Admin." "SUCCESS"
        }
    }
}
catch {
    Write-Log "Failed to query Administrators group: $($_.Exception.Message)" "ERROR"
}

Write-Log "Admin Audit complete. Found $WarningCount flagged account(s)." "INFO"
