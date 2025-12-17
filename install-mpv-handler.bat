@echo off
:: MPV Protocol Handler Installer for Windows
:: Run this script as Administrator

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Run the PowerShell installer script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-mpv-handler.ps1"

pause
