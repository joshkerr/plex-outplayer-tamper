#!/bin/bash
# MPV Protocol Handler Installer for macOS
# Run this script: chmod +x install-mpv-handler-macos.sh && ./install-mpv-handler-macos.sh

set -e

echo "MPV Protocol Handler Installer for macOS"
echo "========================================="
echo ""

# Check if mpv is installed
if ! command -v mpv &> /dev/null; then
    echo "ERROR: mpv not found. Install it first:"
    echo "  brew install mpv"
    exit 1
fi

MPV_PATH=$(which mpv)
echo "Found mpv at: $MPV_PATH"

APP_NAME="Plex MPV Handler"
APP_DIR="$HOME/Applications/$APP_NAME.app"

echo "Creating app bundle at: $APP_DIR"

# Clean up existing installation
rm -rf "$APP_DIR"
rm -rf "$HOME/Applications/MPV URL Handler.app"  # Remove old version

# Create app bundle structure manually (avoids osacompile issues on newer macOS)
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Create the shell script that handles the URL
cat > "$APP_DIR/Contents/MacOS/applet" << 'HANDLER'
#!/bin/bash
# Handle plex-mpv:// URLs
URL="$1"

if [ -z "$URL" ]; then
    exit 0
fi

# Strip 'plex-mpv://' prefix
BASE64_PART="${URL#plex-mpv://}"

# Decode base64 to get the actual media URL
DECODED_URL=$(echo "$BASE64_PART" | base64 -d 2>/dev/null)

if [ -z "$DECODED_URL" ]; then
    exit 1
fi

# Launch mpv
if [ -x /opt/homebrew/bin/mpv ]; then
    /opt/homebrew/bin/mpv "$DECODED_URL" &
elif [ -x /usr/local/bin/mpv ]; then
    /usr/local/bin/mpv "$DECODED_URL" &
fi
HANDLER
chmod +x "$APP_DIR/Contents/MacOS/applet"

# Create Info.plist with URL scheme
PLIST="$APP_DIR/Contents/Info.plist"
cat > "$PLIST" << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.plex-outplayer.mpv-handler</string>
    <key>CFBundleName</key>
    <string>Plex MPV Handler</string>
    <key>CFBundleExecutable</key>
    <string>applet</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Plex MPV Protocol</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>plex-mpv</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLISTEOF

# Register the URL handler
echo "Registering URL handler..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo ""
echo "✓ Plex MPV Handler installed successfully!"
echo ""
echo "The handler is installed at: $APP_DIR"
echo "You can now use MPV as your player in Plex Outplayer."
