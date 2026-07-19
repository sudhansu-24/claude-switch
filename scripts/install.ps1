<#
.SYNOPSIS
    Set up multiple isolated Claude Desktop instances on Windows (MSIX install).

.DESCRIPTION
    Claude Desktop ships as an MSIX package. Windows blocks launching the .exe
    directly from C:\Program Files\WindowsApps, and the package is built for a
    single instance. This script copies Claude to a portable folder outside
    WindowsApps (where Windows allows direct launch) and creates desktop
    shortcuts, each with its own --user-data-dir so every instance has its own
    account, MCP servers, and settings.

.PARAMETER Instances
    How many extra isolated instances to create (default 2). Your normal Claude
    install stays as-is and is "instance 1"; this creates Claude 2 .. Claude N+1.

.PARAMETER PortableDir
    Where to copy Claude. Default: C:\ClaudePortable

.EXAMPLE
    # Run as Administrator (needed to read WindowsApps)
    powershell -ExecutionPolicy Bypass -File install.ps1 -Instances 2
#>
param(
    [int]$Instances = 2,
    [string]$PortableDir = "C:\ClaudePortable"
)
$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "   $msg" -ForegroundColor Red }

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Claude Desktop Multi-Instance Setup (Windows)"   -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# --- 1. Locate the installed Claude MSIX -------------------------------------
Write-Step "Locating Claude Desktop install..."
$installLoc = $null
try {
    $pkg = Get-AppxPackage -Name "*Claude*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pkg) { $installLoc = $pkg.InstallLocation; Write-Ok "Package: $($pkg.PackageFullName)" }
} catch {}

# Fallback: scan WindowsApps directly in case Get-AppxPackage misses the
# package (e.g. installed under a different user context).
if (-not $installLoc) {
    $p = Get-ChildItem "C:\Program Files\WindowsApps" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "Claude_*__*" } | Sort-Object Name -Descending | Select-Object -First 1
    if ($p) { $installLoc = $p.FullName }
}

if (-not $installLoc) {
    Write-Err "Could not find Claude Desktop. Is it installed? Run this script AS ADMINISTRATOR."
    pause; exit 1
}

$srcApp = Join-Path $installLoc "app"
if (-not (Test-Path (Join-Path $srcApp "Claude.exe"))) {
    Write-Err "Found the package but no app\Claude.exe inside ($srcApp)."
    Write-Err "Run AS ADMINISTRATOR so the protected WindowsApps folder is readable."
    pause; exit 1
}
Write-Ok "Source: $srcApp"

# --- 2. Copy Claude to a portable folder -------------------------------------
Write-Step "Copying Claude to portable folder: $PortableDir"
Write-Warn "This is ~200 MB, it may take a minute..."

# Close any portable instances so files aren't locked
Get-CimInstance Win32_Process -Filter "Name='Claude.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -like "$PortableDir\*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 1

# /MIR mirrors source (also removes stale files from old versions);
# the /N* flags just silence robocopy's per-file output.
robocopy $srcApp $PortableDir /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
$exe = Join-Path $PortableDir "Claude.exe"
if (-not (Test-Path $exe)) { Write-Err "Copy failed (no $exe)."; pause; exit 1 }
$ver = (Get-Item $exe).VersionInfo.ProductVersion
Write-Ok "Copied. Portable version: $ver"

# --- 3. Create desktop shortcuts ---------------------------------------------
Write-Step "Creating $Instances desktop shortcut(s)..."
$sh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")

# Instances are numbered 2..(Instances+1); instance 1 = your normal install.
for ($i = 2; $i -le ($Instances + 1); $i++) {
    $dir = Join-Path $env:APPDATA "Claude-Instance$i"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lnk = Join-Path $desktop "Claude $i.lnk"
    $sc = $sh.CreateShortcut($lnk)
    $sc.TargetPath = $exe
    $sc.Arguments = "--user-data-dir=`"$dir`""
    $sc.WorkingDirectory = $PortableDir
    $sc.IconLocation = "$exe,0"
    $sc.Description = "Claude Desktop - Instance $i (isolated profile)"
    $sc.Save()
    Write-Ok "Created: Claude $i  (profile: $dir)"
}

# --- 4. Done -----------------------------------------------------------------
Write-Host "`n=================================================" -ForegroundColor Green
Write-Host " Done!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host @"

 Instance 1  = your normal Claude (Start menu / taskbar icon)
 Claude 2..$($Instances + 1) = new shortcuts on your Desktop, each isolated.

 IMPORTANT - logging into different accounts:
 Log in to each NEW instance one at a time, with the others CLOSED.
 The login (claude:// deep link) goes to whichever instance is open,
 so open just one new instance, log in, then open the next.
 After the first login each session persists; you can run them all at once.

 To UPDATE after Claude auto-updates: just run this script again.
"@ -ForegroundColor White
pause
