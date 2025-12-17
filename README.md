# plex-outplayer-tamper
Places an external player button on the Plex website to stream videos through Outplayer, SenPlayer, or MPV. This is a Tampermonkey script file. If you right-click on the player button, you can choose the player you want to use. The button will change to reflect the selected player.

## Supported Players

- **Outplayer** (iOS) - Works out of the box
- **SenPlayer** (iOS) - Works out of the box
- **MPV** (Mac/Windows) - Requires URL handler setup (see below)

## MPV Setup

MPV requires a URL protocol handler to be registered on your system before it can be launched from the browser.

### macOS

Install the mpv-handler using Homebrew:

```bash
brew install stolendata/mpv-handler/mpv-handler
```

Or manually register the `mpv://` protocol using a third-party tool like [open-mpv](https://github.com/nicetip/open-mpv) or similar.

### Windows

**Prerequisites:** Install MPV first via [Chocolatey](https://community.chocolatey.org/packages/mpvio) (`choco install mpvio`) or download from [mpv.io](https://mpv.io/installation/). Make sure `mpv.exe` is in your PATH (verify with `mpv --version`).

**Quick Install:** Download both files and run `install-mpv-handler.bat` as Administrator:
- [`install-mpv-handler.bat`](install-mpv-handler.bat)
- [`install-mpv-handler.ps1`](install-mpv-handler.ps1)

**Or** run the PowerShell script directly **as Administrator**:

```powershell
# MPV Protocol Handler Setup for Windows (Run as Administrator)
# This creates a PowerShell-based handler that properly decodes URLs

$mpvPath = (Get-Command mpv.exe -ErrorAction SilentlyContinue).Source
if (-not $mpvPath) { Write-Error "mpv.exe not found in PATH. Install MPV first."; exit 1 }

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

# Register the mpv:// protocol
New-Item -Path "HKCR:\mpv" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "(Default)" -Value "URL:mpv Protocol"
Set-ItemProperty -Path "HKCR:\mpv" -Name "URL Protocol" -Value ""
New-Item -Path "HKCR:\mpv\shell\open\command" -Force | Out-Null
$cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handlerDir\mpv-handler.ps1`" `"%1`""
Set-ItemProperty -Path "HKCR:\mpv\shell\open\command" -Name "(Default)" -Value $cmd

Write-Host "mpv:// protocol handler installed successfully!" -ForegroundColor Green
Write-Host "Handler script: $handlerDir\mpv-handler.ps1"
```

After setup, when you select MPV as your player and click the button, it will launch MPV with the Plex stream URL.
