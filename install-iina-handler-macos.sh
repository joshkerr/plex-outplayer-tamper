#!/bin/bash
# IINA Protocol Handler Installer for macOS
# Run this script: chmod +x install-iina-handler-macos.sh && ./install-iina-handler-macos.sh

set -e

echo "IINA Protocol Handler Installer for macOS"
echo "=========================================="
echo ""

# Check if IINA is installed
IINA_APP="/Applications/IINA.app"
if [ ! -d "$IINA_APP" ]; then
    echo "ERROR: IINA not found at $IINA_APP"
    echo "Install IINA first from: https://iina.io"
    echo "  Or via Homebrew: brew install --cask iina"
    exit 1
fi

echo "Found IINA at: $IINA_APP"

APP_NAME="Plex IINA Handler"
APP_DIR="$HOME/Applications/$APP_NAME.app"

echo "Creating app bundle at: $APP_DIR"

# Clean up existing installation
rm -rf "$APP_DIR"

# Create AppleScript source file
SCRIPT_SOURCE=$(mktemp)
cat > "$SCRIPT_SOURCE" << 'APPLESCRIPT'
on open location theURL
    -- Strip 'plex-iina://' prefix (first 12 characters)
    set base64Part to text 13 thru -1 of theURL

    -- Decode base64
    set decodedURL to do shell script "echo " & quoted form of base64Part & " | base64 -d"

    -- Launch IINA with the URL
    do shell script "/Applications/IINA.app/Contents/MacOS/iina-cli --no-stdin " & quoted form of decodedURL & " > /dev/null 2>&1 &"
end open location
APPLESCRIPT

# Compile AppleScript to app bundle
osacompile -o "$APP_DIR" "$SCRIPT_SOURCE"
rm "$SCRIPT_SOURCE"

# Add URL scheme to Info.plist using PlistBuddy
PLIST="$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.plex-outplayer.iina-handler" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.plex-outplayer.iina-handler" "$PLIST"

/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Plex IINA Protocol'" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string plex-iina" "$PLIST" 2>/dev/null || true

# Register the URL handler
echo "Registering URL handler..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo ""
echo "Plex IINA Handler installed successfully!"
echo ""
echo "The handler is installed at: $APP_DIR"
echo "You can now use IINA as your player in Plex Outplayer."
