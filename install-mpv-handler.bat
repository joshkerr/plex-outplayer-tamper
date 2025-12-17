@echo off
:: MPV Protocol Handler Installer for Windows
:: Run this script as Administrator

echo MPV Protocol Handler Installer
echo ==============================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Run the PowerShell installer
powershell.exe -ExecutionPolicy Bypass -Command ^
    "$mpvPath = (Get-Command mpv.exe -ErrorAction SilentlyContinue).Source; ^
    if (-not $mpvPath) { Write-Error 'mpv.exe not found in PATH. Install MPV first.'; exit 1 }; ^
    $handlerDir = \"$env:LOCALAPPDATA\mpv-handler\"; ^
    New-Item -Path $handlerDir -ItemType Directory -Force | Out-Null; ^
    $handlerScript = @' ^
param([string]$url) ^
$encoded = $url.Substring(11) ^
$decoded = [System.Uri]::UnescapeDataString($encoded) ^
& mpv $decoded ^
'@; ^
    $handlerScript | Out-File -FilePath \"$handlerDir\mpv-handler.ps1\" -Encoding UTF8; ^
    New-Item -Path 'HKCR:\mpv' -Force | Out-Null; ^
    Set-ItemProperty -Path 'HKCR:\mpv' -Name '(Default)' -Value 'URL:mpv Protocol'; ^
    Set-ItemProperty -Path 'HKCR:\mpv' -Name 'URL Protocol' -Value ''; ^
    New-Item -Path 'HKCR:\mpv\shell\open\command' -Force | Out-Null; ^
    $cmd = \"powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `\"$handlerDir\mpv-handler.ps1`\" `\"%1`\"\"; ^
    Set-ItemProperty -Path 'HKCR:\mpv\shell\open\command' -Name '(Default)' -Value $cmd; ^
    Write-Host 'mpv:// protocol handler installed successfully!' -ForegroundColor Green; ^
    Write-Host \"Handler script: $handlerDir\mpv-handler.ps1\""

echo.
if %errorlevel% equ 0 (
    echo Installation complete!
) else (
    echo Installation failed. Make sure MPV is installed and in your PATH.
)
echo.
pause
