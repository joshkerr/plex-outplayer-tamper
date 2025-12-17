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

1. Download and install [mpv-handler](https://github.com/nicetip/open-mpv) or a similar URL protocol handler for MPV
2. Alternatively, you can manually register the `mpv://` protocol in the Windows Registry:
   - Create a registry key at `HKEY_CLASSES_ROOT\mpv`
   - Set the default value to `URL:mpv Protocol`
   - Add a string value `URL Protocol` (empty)
   - Create `shell\open\command` subkey with default value pointing to your mpv executable with `"%1"` parameter

After setup, when you select MPV as your player and click the button, it will launch MPV with the Plex stream URL.
