<#
.SYNOPSIS
    Audits user logon and logoff activity from the Security Event Log.
.DESCRIPTION
    Scans the Security Event Log for successful logon (4624) and logoff (4634) events.
    Returns a custom object with details.
.PARAMETER Days
    Number of days back to scan. Default is 1.
.PARAMETER UserName
    Filter by a specific username (wildcards supported).
#>
[CmdletBinding()]
param (
    [int]$Days = 1,
    [string]$UserName = "*"
)

# --- Load Globals ---
$GlobalsPath = Join-Path $PSScriptRoot "Globals.ps1"
if (Test-Path $GlobalsPath) { . $GlobalsPath }

# --- Admin Check ---
Assert-Admin

Write-Log "Scanning Security Log for the last $Days day(s)..." "INFO"

$startTime = (Get-Date).AddDays(-$Days)
$events = $null

try {
    # 4624: Logon, 4634: Logoff
    # We only care about interactive/remote types usually, but let's grab all and filter later or grab interesting ones.
    # LogonType 2 (Interactive) and 10 (RemoteInteractive) are most relevant for users.
    
    $filterXml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4624 or EventID=4634) and TimeCreated[@SystemTime&gt;='AnalyzerTime']]]</Select>
  </Query>
</QueryList>
"@
    # Replace AnalyzerTime with actual ISO8601 time
    $isoDate = $startTime.ToString("s")
    $filterXml = $filterXml.Replace("AnalyzerTime", $isoDate)

    $events = Get-WinEvent -FilterXml $filterXml -ErrorAction Stop
}
catch {
    $err = $_.Exception.Message
    if ($err -match "No events" -or $err -match "criteria" -or $err -match "criteri" -or $err -match "trouver") {
        Write-Log "No logon/logoff events found in the specified timeframe." "WARN"
        return
    }
    Write-Log "Error querying Event Log: $err" "ERROR"
    return
}

$results = @()
$totalAuditEvents = $events.Count
$currentAuditEvent = 0

foreach ($evt in $events) {
    $currentAuditEvent++
    if ($currentAuditEvent % 10 -eq 0) {
        Write-Progress -Activity "Auditing User Activity" -Status "Analyzing event $currentAuditEvent of $totalAuditEvents" -PercentComplete (($currentAuditEvent / $totalAuditEvents) * 100)
    }

    # Extract XML for easier property access
    $xml = [xml]$evt.ToXml()
    $eventData = $xml.Event.EventData.Data

    # Helper to find data by name
    $targetUser = ($eventData | Where-Object { $_.Name -eq "TargetUserName" })."#text"
    $logonType = ($eventData | Where-Object { $_.Name -eq "LogonType" })."#text"
    $ipAddress = ($eventData | Where-Object { $_.Name -eq "IpAddress" })."#text"
    
    # Filter by user if requested
    if ($targetUser -notlike $UserName) { continue }
    # Filter out system accounts usually (ending in$) or ANONYMOUS LOGON
    if ($targetUser -match "\$$" -or $targetUser -eq "ANONYMOUS LOGON" -or $targetUser -match "^DWM-") { continue }

    $action = if ($evt.Id -eq 4624) { "Logon" } else { "Logoff" }
    
    # Map Logon Types (Essential ones)
    $typeDesc = switch ($logonType) {
        "2" { "Interactive (Local)" }
        "3" { "Network" }
        "4" { "Batch" }
        "5" { "Service" }
        "7" { "Unlock" }
        "10" { "Remote Desktop" }
        "11" { "CachedInteractive" }
        default { $logonType }
    }

    $results += [PSCustomObject]@{
        Time    = $evt.TimeCreated
        Action  = $action
        User    = $targetUser
        Type    = $typeDesc
        IP      = $ipAddress
        EventID = $evt.Id
    }
}
Write-Progress -Activity "Auditing User Activity" -Completed

if ($results.Count -gt 0) {
    # Sort and Display
    $results | Sort-Object Time -Descending | Format-Table -AutoSize
    Write-Log "Found $($results.Count) events." "SUCCESS"
}
else {
    Write-Log "No matching events found after filtering." "INFO"
}
