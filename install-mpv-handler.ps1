# MPV Protocol Handler Setup for Windows
# Run this script as Administrator: Right-click PowerShell -> Run as Administrator
# Then: .\install-mpv-handler.ps1

#Requires -RunAsAdministrator

Write-Host "MPV Protocol Handler Installer" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if MPV is installed
$mpvPath = (Get-Command mpv.exe -ErrorAction SilentlyContinue).Source
if (-not $mpvPath) {
    Write-Error "mpv.exe not found in PATH. Install MPV first:"
    Write-Host "  - Chocolatey: choco install mpvio"
    Write-Host "  - Or download from: https://mpv.io/installation/"
    exit 1
}

Write-Host "Found MPV at: $mpvPath" -ForegroundColor Green

# Create handler script directory
$handlerDir = "$env:LOCALAPPDATA\mpv-handler"
New-Item -Path $handlerDir -ItemType Directory -Force | Out-Null

# Create the handler script that decodes the URL and launches MPV
$handlerScript = @'
param([string]$url)
# Strip 'mpv://play/' prefix (11 chars) and URL-decode
$encoded = $url.Substring(11)
$decoded = [System.Uri]::UnescapeDataString($encoded)
& mpv $decoded
'@
$handlerScript | Out-File -FilePath "$handlerDir\mpv-handler.ps1" -Encoding UTF8
Write-Host "Created handler script: $handlerDir\mpv-handler.ps1" -ForegroundColor Green

# Register the mpv:// protocol
Write-Host "Registering mpv:// protocol..." -ForegroundColor Yellow
New-Item -Path "Registry::HKEY_CLASSES_ROOT\mpv" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\mpv" -Name "(Default)" -Value "URL:mpv Protocol"
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\mpv" -Name "URL Protocol" -Value ""
New-Item -Path "Registry::HKEY_CLASSES_ROOT\mpv\shell\open\command" -Force | Out-Null
$cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handlerDir\mpv-handler.ps1`" `"%1`""
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\mpv\shell\open\command" -Name "(Default)" -Value $cmd

Write-Host ""
Write-Host "mpv:// protocol handler installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use MPV as your player in Plex Outplayer." -ForegroundColor Cyan
