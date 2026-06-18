# Plex MPV Protocol Handler Setup for Windows
# Run this script as Administrator: Right-click PowerShell -> Run as Administrator
# Then: .\install-mpv-handler.ps1

#Requires -RunAsAdministrator

Write-Host "Plex MPV Protocol Handler Installer" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
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
$handlerDir = "$env:LOCALAPPDATA\plex-mpv-handler"
New-Item -Path $handlerDir -ItemType Directory -Force | Out-Null

# Create the handler script that decodes the URL and launches MPV
$handlerScript = @'
param([string]$url)

$ErrorActionPreference = "Stop"
$logPath = Join-Path $PSScriptRoot "handler.log"
$mpvPath = '__MPV_PATH__'

function Write-HandlerLog {
    param([string]$Message)
    Add-Content -Path $logPath -Value "$(Get-Date -Format o) $Message"
}

function ConvertFrom-Base64Url {
    param([string]$Value)

    $base64 = $Value.Replace("-", "+").Replace("_", "/")
    switch ($base64.Length % 4) {
        0 { break }
        2 { $base64 += "==" }
        3 { $base64 += "=" }
        default { throw "Invalid base64url length." }
    }

    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
}

try {
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw "No URL argument was provided."
    }

    Write-HandlerLog "Received plex-mpv URL with length $($url.Length)."

    if ($url -match '^plex-mpv://play/(.+)$') {
        $decoded = ConvertFrom-Base64Url $Matches[1].TrimEnd("/")
    } elseif ($url -match '^plex-mpv://(.+)$') {
        # Compatibility with older userscript versions that used raw base64.
        $base64 = $Matches[1].TrimEnd("/")
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
    } else {
        throw "Unexpected URL format."
    }

    if (-not (Test-Path -LiteralPath $mpvPath)) {
        throw "mpv.exe was not found at the installed path: $mpvPath"
    }

    Start-Process -FilePath $mpvPath -ArgumentList @($decoded)
    Write-HandlerLog "Started mpv with decoded URL length $($decoded.Length)."
} catch {
    Write-HandlerLog "ERROR: $($_.Exception.Message)"
    exit 1
}
'@
$handlerScript = $handlerScript.Replace('__MPV_PATH__', $mpvPath.Replace("'", "''"))
$handlerScript | Out-File -FilePath "$handlerDir\plex-mpv-handler.ps1" -Encoding UTF8
Write-Host "Created handler script: $handlerDir\plex-mpv-handler.ps1" -ForegroundColor Green

# Register the plex-mpv:// protocol
Write-Host "Registering plex-mpv:// protocol..." -ForegroundColor Yellow
New-Item -Path "Registry::HKEY_CLASSES_ROOT\plex-mpv" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\plex-mpv" -Name "(Default)" -Value "URL:Plex MPV Protocol"
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\plex-mpv" -Name "URL Protocol" -Value ""
New-Item -Path "Registry::HKEY_CLASSES_ROOT\plex-mpv\shell\open\command" -Force | Out-Null
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handlerDir\plex-mpv-handler.ps1`" `"%1`""
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\plex-mpv\shell\open\command" -Name "(Default)" -Value $cmd

Write-Host ""
Write-Host "plex-mpv:// protocol handler installed successfully!" -ForegroundColor Green
Write-Host "Handler logs will be written to: $handlerDir\handler.log" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use MPV as your player in Plex Outplayer." -ForegroundColor Cyan
