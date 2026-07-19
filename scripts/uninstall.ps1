<#
.SYNOPSIS
    Remove the portable Claude copy, its shortcuts, and (optionally) the
    isolated instance profiles. Does NOT touch your normal Claude install.

.PARAMETER PortableDir
    Where the portable copy lives. Must match what was passed to install.ps1.
    Default: C:\ClaudePortable

.PARAMETER KeepProfiles
    Keep the %APPDATA%\Claude-InstanceN profile folders (logged-in sessions,
    MCP config) so a later reinstall picks them up again.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File uninstall.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File uninstall.ps1 -KeepProfiles
#>
param(
    [string]$PortableDir = "C:\ClaudePortable",
    [switch]$KeepProfiles
)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Uninstall Claude Multi-Instance ===" -ForegroundColor Cyan

# Kill only Claude processes running FROM the portable folder — leaves the
# user's normal (MSIX) Claude untouched even if it's open.
Get-CimInstance Win32_Process -Filter "Name='Claude.exe'" |
    Where-Object { $_.ExecutablePath -like "$PortableDir\*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Seconds 1

# Remove desktop shortcuts "Claude N.lnk"
$desktop = [Environment]::GetFolderPath("Desktop")
Get-ChildItem $desktop -Filter "Claude *.lnk" | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Removed shortcut: $($_.Name)" -ForegroundColor Green
}

# Remove portable folder
if (Test-Path $PortableDir) {
    Remove-Item $PortableDir -Recurse -Force
    Write-Host "Removed portable folder: $PortableDir" -ForegroundColor Green
}

# Optionally remove instance profiles
if (-not $KeepProfiles) {
    Get-ChildItem $env:APPDATA -Directory -Filter "Claude-Instance*" | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
        Write-Host "Removed profile: $($_.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "Kept instance profiles (-KeepProfiles)." -ForegroundColor Yellow
}

Write-Host "`nDone. Your normal Claude install was not touched." -ForegroundColor Cyan
pause
