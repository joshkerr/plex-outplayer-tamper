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

**Prerequisites:** Install MPV first via [Chocolatey](https://community.chocolatey.org/packages/mpvio) (`choco install mpvio`) or download from [mpv.io](https://mpv.io/installation/). Make sure `mpv.exe` is in your PATH.

**Option 1: mpv-url-proto (Recommended)**

Download and run the installer from [mpv-url-proto](https://github.com/b01o/mpv-url-proto):

```powershell
# Download and run the installer (Run as Administrator)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/b01o/mpv-url-proto/main/mpv-url-proto-install.bat" -OutFile "$env:TEMP\mpv-url-proto-install.bat"; Start-Process -FilePath "$env:TEMP\mpv-url-proto-install.bat" -Verb RunAs
```

**Option 2: Manual Registry Setup**

Run this PowerShell script as Administrator to register the `mpv://` protocol:

```powershell
# Register mpv:// protocol handler (Run as Administrator)
$mpvPath = (Get-Command mpv.exe -ErrorAction SilentlyContinue).Source
if (-not $mpvPath) { Write-Error "mpv.exe not found in PATH"; exit 1 }

New-Item -Path "HKCR:\mpv" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "(Default)" -Value "URL:mpv Protocol"
Set-ItemProperty -Path "HKCR:\mpv" -Name "URL Protocol" -Value ""
New-Item -Path "HKCR:\mpv\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\mpv\shell\open\command" -Name "(Default)" -Value "`"$mpvPath`" `"%1`""
Write-Host "mpv:// protocol registered successfully!"
```

After setup, when you select MPV as your player and click the button, it will launch MPV with the Plex stream URL.
