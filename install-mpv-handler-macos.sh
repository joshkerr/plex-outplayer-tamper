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

# Create the app bundle
APP_NAME="MPV URL Handler"
APP_DIR="$HOME/Applications/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating app bundle at: $APP_DIR"

# Clean up existing installation
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create the handler script
cat > "$MACOS_DIR/mpv-handler" << 'HANDLER_SCRIPT'
#!/bin/bash
# MPV URL Handler - decodes base64 URL and launches mpv

URL="$1"

# Strip 'mpv://b64/' prefix (10 chars) and decode base64
BASE64_PART="${URL:10}"
DECODED_URL=$(echo "$BASE64_PART" | base64 -d 2>/dev/null)

if [ -n "$DECODED_URL" ]; then
    /usr/local/bin/mpv "$DECODED_URL" 2>/dev/null || /opt/homebrew/bin/mpv "$DECODED_URL" 2>/dev/null || mpv "$DECODED_URL"
else
    osascript -e "display dialog \"Failed to decode URL\" buttons {\"OK\"} default button \"OK\" with icon stop"
fi
HANDLER_SCRIPT

chmod +x "$MACOS_DIR/mpv-handler"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>mpv-handler</string>
    <key>CFBundleIdentifier</key>
    <string>com.plex-outplayer.mpv-handler</string>
    <key>CFBundleName</key>
    <string>MPV URL Handler</string>
    <key>CFBundleDisplayName</key>
    <string>MPV URL Handler</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>MPV Protocol</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>mpv</string>
            </array>
        </dict>
    </array>
    <key>LSBackgroundOnly</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
PLIST

# Register the URL handler by launching the app once
echo "Registering URL handler..."
open "$APP_DIR"

# Force macOS to update URL handlers
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo ""
echo "✓ MPV URL Handler installed successfully!"
echo ""
echo "The handler is installed at: $APP_DIR"
echo "You can now use MPV as your player in Plex Outplayer."
echo ""
echo "Note: If prompted by macOS, allow the app to run in"
echo "System Preferences > Security & Privacy."
