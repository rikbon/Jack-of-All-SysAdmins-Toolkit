<#
.SYNOPSIS
    Lists and manages startup applications.
.DESCRIPTION
    Checks Registry (HKCU/HKLM) and Startup Folder for auto-start entries.
    Allows deleting entries to disable them.
#>
[CmdletBinding()]
param ()

function Get-StartupApps {
    $apps = @()

    # Registry - Current User
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $path) {
        Get-Item $path | Select-Object -ExpandProperty Property | ForEach-Object {
            $apps += [PSCustomObject]@{
                Name     = $_
                Command  = (Get-ItemProperty $path).$_
                Location = "Reg:HKCU"
                Path     = $path
            }
        }
    }

    # Registry - Local Machine (Admin)
    $path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $path) {
        Get-Item $path | Select-Object -ExpandProperty Property | ForEach-Object {
            $apps += [PSCustomObject]@{
                Name     = $_
                Command  = (Get-ItemProperty $path).$_
                Location = "Reg:HKLM"
                Path     = $path
            }
        }
    }

    # Startup Folder
    $startupPath = [Environment]::GetFolderPath("Startup")
    if (Test-Path $startupPath) {
        Get-ChildItem $startupPath -Filter *.lnk | ForEach-Object {
            $apps += [PSCustomObject]@{
                Name     = $_.BaseName
                Command  = $_.FullName
                Location = "Folder:Startup"
                Path     = $startupPath
            }
        }
    }

    return $apps
}

function Show-StartupMenu {
    while ($true) {
        Clear-Host
        Write-Host "=== Startup App Manager ===" -ForegroundColor Cyan
        
        $apps = Get-StartupApps
        $i = 1
        foreach ($app in $apps) {
            Write-Host "$i. [$($app.Location)] $($app.Name)"
            $i++
        }
        Write-Host "Q. Quit"

        $choice = Read-Host "Enter number to DELETE/DISABLE or Q to quit"
        if ($choice -match "^\d+$" -and $choice -le $apps.Count) {
            $selected = $apps[$choice - 1]
            Write-Warning "You are about to remove: $($selected.Name) from $($selected.Location)"
            $confirm = Read-Host "Type 'DELETE' to confirm"
            
            if ($confirm -eq "DELETE") {
                try {
                    if ($selected.Location -like "Reg:*") {
                        Remove-ItemProperty -Path $selected.Path -Name $selected.Name -ErrorAction Stop
                    }
                    elseif ($selected.Location -like "Folder:*") {
                        Remove-Item -Path $selected.Command -Force -ErrorAction Stop
                    }
                    Write-Host "Removed successfully." -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to remove: $($_.Exception.Message)"
                }
                Start-Sleep -Seconds 1
            }
        }
        elseif ($choice -in "Q", "q") {
            return
        }
    }
}

Show-StartupMenu
