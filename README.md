# plex-outplayer-tamper
Places an external player button on the Plex website to stream videos through Outplayer, SenPlayer, or MPV. This is a Tampermonkey script file. If you right-click on the player button, you can choose the player you want to use. The button will change to reflect the selected player.

## Supported Players

- **Outplayer** (iOS) - Works out of the box
- **SenPlayer** (iOS) - Works out of the box
- **MPV** (Mac/Windows) - Requires URL handler setup (see below)

## MPV Setup

MPV requires a URL protocol handler (`plex-mpv://`) to be registered on your system before it can be launched from the browser.

### macOS

**Prerequisites:** Install MPV first via Homebrew (`brew install mpv`). Verify with `mpv --version`.

**Quick Install:** Download and run the installer script:

```bash
curl -O https://raw.githubusercontent.com/joshkerr/plex-outplayer-tamper/main/install-mpv-handler-macos.sh
chmod +x install-mpv-handler-macos.sh
./install-mpv-handler-macos.sh
```

Or if you have the repo cloned:

```bash
./install-mpv-handler-macos.sh
```

This creates an app bundle at `~/Applications/Plex MPV Handler.app` that handles `plex-mpv://` URLs.

**Note:** If macOS blocks the app, go to System Preferences > Security & Privacy and allow it to run.

### Windows

**Prerequisites:** Install MPV first via [Chocolatey](https://community.chocolatey.org/packages/mpvio) (`choco install mpvio`) or download from [mpv.io](https://mpv.io/installation/). Make sure `mpv.exe` is in your PATH (verify with `mpv --version`).

**Quick Install:** Download both files and run `install-mpv-handler.bat` as Administrator:
- [`install-mpv-handler.bat`](install-mpv-handler.bat)
- [`install-mpv-handler.ps1`](install-mpv-handler.ps1)

**Or** run the PowerShell script directly **as Administrator**:

```powershell
.\install-mpv-handler.ps1
```

After setup, when you select MPV as your player and click the button, it will launch MPV with the Plex stream URL.
