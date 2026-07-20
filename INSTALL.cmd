@echo off
:: Claude Desktop Multi-Instance - one-click installer
:: Self-elevates to Administrator (needed to read the protected WindowsApps folder)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator permission...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -WorkingDirectory '%~dp0'"
    exit /b
)

echo Running installer as administrator...
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1" -Instances 2
pause
