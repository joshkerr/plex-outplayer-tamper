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

# Create AppleScript source file
SCRIPT_SOURCE=$(mktemp)
cat > "$SCRIPT_SOURCE" << 'APPLESCRIPT'
on open location theURL
    -- Strip 'plex-mpv://' prefix (first 11 characters)
    set base64Part to text 12 thru -1 of theURL

    -- Decode base64
    set decodedURL to do shell script "echo " & quoted form of base64Part & " | base64 -d"

    -- Launch mpv (try both possible locations)
    try
        do shell script "/opt/homebrew/bin/mpv " & quoted form of decodedURL & " > /dev/null 2>&1 &"
    on error
        try
            do shell script "/usr/local/bin/mpv " & quoted form of decodedURL & " > /dev/null 2>&1 &"
        end try
    end try
end open location
APPLESCRIPT

# Compile AppleScript to app bundle
osacompile -o "$APP_DIR" "$SCRIPT_SOURCE"
rm "$SCRIPT_SOURCE"

# Add URL scheme to Info.plist using PlistBuddy
PLIST="$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.plex-outplayer.mpv-handler" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.plex-outplayer.mpv-handler" "$PLIST"

/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Plex MPV Protocol'" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string plex-mpv" "$PLIST" 2>/dev/null || true

# Register the URL handler
echo "Registering URL handler..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo ""
echo "✓ Plex MPV Handler installed successfully!"
echo ""
echo "The handler is installed at: $APP_DIR"
echo "You can now use MPV as your player in Plex Outplayer."
