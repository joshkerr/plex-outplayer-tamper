# Agent Guide for plex-outplayer-tamper

## Project Overview

**Type**: Tampermonkey userscript with platform-specific URL handler installers  
**Purpose**: Adds an external player button to Plex web interface to stream videos through Outplayer, SenPlayer, MPV, or IINA  
**Language**: JavaScript (userscript), Bash (macOS installers), PowerShell/Batch (Windows installers)  
**Target Platforms**: Browser (userscript), macOS (MPV/IINA), Windows (MPV), iOS (Outplayer/SenPlayer)

## Repository Structure

```
.
├── plex-outplayer.js              # Main Tampermonkey userscript
├── install-mpv-handler-macos.sh   # macOS MPV URL handler installer
├── install-iina-handler-macos.sh  # macOS IINA URL handler installer
├── install-mpv-handler.bat        # Windows MPV installer (launcher)
├── install-mpv-handler.ps1        # Windows MPV installer (PowerShell)
├── README.md                      # User documentation
└── LICENSE                        # MIT license
```

## Essential Commands

### Testing
**No automated tests exist.** Test manually by:
1. Installing the userscript in Tampermonkey
2. Navigating to Plex web interface (https://app.plex.tv/desktop/)
3. Selecting a media item
4. Clicking the external player button

### Installing URL Handlers

**macOS - MPV:**
```bash
chmod +x install-mpv-handler-macos.sh
./install-mpv-handler-macos.sh
```

**macOS - IINA:**
```bash
chmod +x install-iina-handler-macos.sh
./install-iina-handler-macos.sh
```

**Windows - MPV:**
```powershell
# Run as Administrator
.\install-mpv-handler.ps1
```

### Git Workflow
```bash
# Check recent commits
git log --oneline -15

# Common workflow
git checkout -b feature-name
# Make changes
git add .
git commit -m "Description"
git push origin feature-name
# Create PR via GitHub
```

## Code Organization

### Main Userscript (`plex-outplayer.js`)

The script is organized as an IIFE (Immediately Invoked Function Expression) with the following major sections:

1. **Configuration & Setup** (lines 26-103)
   - DOM prefix generation using random tokens
   - Player configurations object (outplayer, senplayer, mpv, iina)
   - LocalStorage-based player selection persistence

2. **Utility Functions** (lines 108-196)
   - Error handling and logging
   - URL redaction for security
   - File size formatting
   - Duration formatting (ms to HH:MM:SS)

3. **Modal Dialog** (lines 201-753)
   - Custom modal for multi-file selection (seasons, shows, collections)
   - CSS-in-JS styling
   - Keyboard navigation (Tab, Enter, Escape)
   - Player selector dropdown
   - File listing with metadata (watched status, runtime, resolution, type, size)

4. **DOM Observer** (lines 757-833)
   - MutationObserver to detect injection point
   - Retry logic with max attempts
   - Handles page navigation via hash changes

5. **Server Data Management** (lines 837-1335)
   - Plex API client
   - Server discovery via plex.tv API
   - Media metadata caching
   - Recursive API traversal for collections/shows
   - Fallback URI handling for network failures

6. **URL Parsing** (lines 1339-1402)
   - Hash-based routing detection
   - Client ID and metadata ID extraction
   - Regex patterns: `clientIdRegex`, `metadataIdRegex`

7. **Download/Playback** (lines 1407-1515)
   - External player URI construction
   - Base64 encoding for MPV/IINA URLs
   - Progress tracking (marks as in-progress in Plex)
   - Recursive playback for multi-file items

8. **DOM Injection** (lines 1519-1688)
   - Button creation and styling
   - Event handlers (click, right-click context menu)
   - Player selection UI

9. **Initialization** (lines 1691-1702)
   - Entry point: `init()`
   - Server data loading
   - Hash change monitoring

### Installer Scripts

**macOS Scripts (`install-*-macos.sh`):**
- Create AppleScript-based app bundles in `~/Applications/`
- Handle URL decoding (base64) and app launching
- Register custom URL schemes (`plex-mpv://`, `plex-iina://`) via PlistBuddy
- Use Launch Services to register handlers

**Windows Script (`install-mpv-handler.ps1`):**
- Creates handler script in `%LOCALAPPDATA%\plex-mpv-handler\`
- Registers `plex-mpv://` protocol in registry (`HKEY_CLASSES_ROOT`)
- Launches PowerShell in hidden window to decode and execute

## Naming Conventions & Code Style

### JavaScript Style
- **Variable naming**: `camelCase` for variables and functions, `PascalCase` for objects/namespaces
- **Constants**: `SCREAMING_SNAKE_CASE` for true constants (e.g., `DOM_OBSERVER_MAX_RETRIES`)
- **Prefixing**: All injected DOM elements use random `domPrefix` to avoid conflicts with Plex
- **Object organization**: Related functions grouped into objects (e.g., `modal.*`, `serverData.*`, `download.*`)
- **Async/await**: Preferred over raw Promises
- **Error handling**: Centralized via `errorHandle()` function

### DOM Elements
- Custom element tag: `<${domPrefix}element>` to avoid interference with Plex's DOM
- ID format: `${domPrefix}descriptive_name` (e.g., `${domPrefix}modal_container`)
- Class format: `${domPrefix}descriptive_name` (e.g., `${domPrefix}modal_table_cell`)

### Script Headers
- **Bash scripts**: Include shebang (`#!/bin/bash`), description, usage instructions
- **PowerShell**: Include `#Requires -RunAsAdministrator` directive
- **Userscript metadata**: Tampermonkey header with `@match`, `@include`, `@grant` directives

### Comments
- Explain *why*, not *what* (code should be self-documenting)
- Mark quirks and workarounds (e.g., Plex API peculiarities, browser bugs)
- Document security considerations (e.g., URL redaction, token handling)

## Player System Architecture

### Player Configuration Object
Each player has:
- `name`: Display name
- `buildUri(uri)`: Function that transforms Plex streaming URL into player-specific URI

### URL Encoding Schemes
- **Outplayer/SenPlayer**: x-callback-url format with URL encoding
  ```
  outplayer://x-callback-url/play?url=<ENCODED_URL>
  ```
- **MPV/IINA**: Custom protocol with base64 encoding (to prevent URL mangling by Windows/browsers)
  ```
  plex-mpv://<BASE64_ENCODED_URL>
  plex-iina://<BASE64_ENCODED_URL>
  ```

### Player Selection
- Stored in `localStorage` using stable key `plexExternalPlayer_selectedPlayer`
- Default: `outplayer`
- Changeable via right-click context menu on button
- Selection persists across page reloads

## Plex API Integration

### Authentication
- Tokens from `localStorage`: `myPlexAccessToken`, `clientID`
- Token passed as `X-Plex-Token` query parameter

### API Endpoints

**Server Discovery:**
```
GET https://clients.plex.tv/api/v2/resources
  ?includeHttps=1
  &includeRelay=1
  &X-Plex-Client-Identifier=<browserToken>
  &X-Plex-Token=<serverToken>
```

**Media Metadata:**
```
GET <baseUri>/library/metadata/<metadataId>
  ?X-Plex-Token=<accessToken>
```

**Children/Leaves:**
```
GET <baseUri>/library/metadata/<metadataId>/children
GET <baseUri>/library/metadata/<metadataId>/allLeaves
```
- Use `/allLeaves` when `childCount !== leafCount` (e.g., TV show with seasons and episodes)
- Use `/children` otherwise

**Progress Tracking:**
```
POST <baseUri>/:/progress
  ?X-Plex-Token=<accessToken>
  &key=<metadataId>
  &time=<milliseconds>  # 10% of runtime
  &state=playing
  &identifier=com.plexapp.plugins.library
```

**Streaming URL:**
```
GET <baseUri><mediaKey>
  ?X-Plex-Token=<accessToken>
  &download=1                        # Preserves audio tracks
  &audioStreamID=1                   # Force default audio
  &X-Plex-Platform=iOS
  &X-Plex-Client-Identifier=<playerName>
  &X-Plex-Client-Platform=iOS
  &X-Plex-Device=iPhone
  &X-Plex-Device-Name=<playerName>
  &playback=start
  &session=<playerKey>-<timestamp>
```

### API Quirks & Gotchas

1. **Empty Metadata**: Collections can return empty `Metadata` arrays - handle gracefully
2. **Leaf Count Mismatches**: Plex API sometimes reports leaves but returns nothing on `/allLeaves` - use children/leaves heuristic
3. **Fallback URIs**: Non-local connections have primary and relay URIs - try relay if primary fails
4. **Double-Requesting**: Media items in collections can be requested twice due to recursive traversal - cached promises help but don't fully prevent
5. **Response Format**: Must set `accept: application/json` header or Plex returns XML

## DOM Injection Strategy

### Injection Points
- **Target element**: `button[data-testid=preplay-play]` (Plex's Play button)
- **Position**: `after` (adjacent to Play button)

### Timing
- Use `MutationObserver` to detect when injection point appears
- Listen for `hashchange` events (Plex uses hash routing)
- Retry logic with delays if DOM not ready

### Styling
- Clone CSS classes from injection point
- Match font from first text node
- Custom styles applied via `domElementStyle`
- Button starts disabled (opacity 0.5) until data loads

### State Management
- Button disabled until server data and media data load
- Opacity indicates loading state:
  - `0.5`: Loading/disabled
  - `0.25`: Error/forbidden
  - `1.0`: Ready

## Security & Privacy

### URL Redaction
Function `redactUrl()` removes sensitive data before logging:
- IP addresses: `1-1-1-1` placeholder
- Server IDs (hex): `XXXXXXXXXXXXXXXX`
- `X-Plex-Token`: `REDACTED`

### Token Handling
- Never log raw tokens
- Never commit tokens to error messages
- Base64 encoding for URLs (not for security, for URL mangling prevention)

### XSS Prevention
- Custom DOM elements (`<${domPrefix}element>`) prevent tag conflicts
- All user/API data escaped when inserted into DOM
- No `innerHTML` with untrusted data

## Common Issues & Debugging

### "old_string not found" Errors
This is a hypothetical scenario - there are no edit operations in current workflow. If editing:
- View the file first to get exact text including whitespace
- Include 3-5 lines of context
- Match indentation exactly (spaces vs tabs)

### Button Not Appearing
1. Check URL matches pattern: `#!/server/<clientId>/details?key=/library/metadata/<id>`
2. Check browser console for error logs (prefix: `[USERJS Plex Outplayer]`)
3. Verify injection point exists: `document.querySelector('button[data-testid=preplay-play]')`
4. Check `errorLog` array in console

### Player Not Launching
1. **MPV/IINA**: Verify URL handler installed (`ls ~/Applications/`)
2. **MPV**: Check mpv in PATH: `which mpv` (macOS) or `Get-Command mpv` (Windows)
3. **IINA**: Verify IINA installed at `/Applications/IINA.app`
4. **Windows**: Check registry: `HKEY_CLASSES_ROOT\plex-mpv`
5. Test handler manually: `open plex-mpv://aHR0cHM6Ly9leGFtcGxlLmNvbQ==` (macOS)

### Modal Not Opening
- Media items with children (seasons, shows, collections) open modal
- Single files play immediately
- Check `serverData.servers[clientId].mediaData[metadataId].children` exists

### Progress Not Tracking
- Requires valid `runtimeMS` in media metadata
- Falls back to 30 seconds if runtime invalid
- Marks at 10% of duration
- POST to `/:/progress` may fail silently on some servers

## Development Workflow

### Making Changes
1. **Edit userscript**: Modify `plex-outplayer.js`
2. **Update version**: Change `@version` in Tampermonkey header (line 5)
3. **Test in browser**: Tampermonkey auto-reloads on file change (if sync enabled)
4. **Test installers**: Run installer scripts on target platforms
5. **Update README**: Document any new features or requirements
6. **Commit with clear message**: Follow existing commit style

### Adding New Players
1. Add entry to `players` object (line 39-79):
   ```javascript
   newplayer: {
       name: "Display Name",
       buildUri: function(uri) {
           // Transform uri to player-specific format
           return `custom-protocol://${encodedUri}`;
       }
   }
   ```
2. If player requires URL handler, create installer script(s)
3. Update README with setup instructions
4. Test on target platform

### Modifying Plex API Calls
- All API calls go through `serverData.apiCall(clientId, apiPath)`
- Use `serverData.updateMediaDirectly()` to cache results
- Respect existing promise system to avoid duplicate requests
- Test with various media types (movie, episode, season, show, collection)

### Changing DOM Injection
- Modify `injectionElement`, `injectPosition`, or `domElementStyle` (lines 34-36)
- Test that button appears in correct location
- Verify styling matches Plex's design
- Check accessibility (tab navigation, ARIA labels)

## File-Specific Notes

### `plex-outplayer.js`
- **Size**: ~1700 lines
- **Dependencies**: None (vanilla JavaScript)
- **Browser compatibility**: Modern browsers (ES6+)
- **Tampermonkey specific**: Uses `@match` and `@include` for URL filtering
- **Run timing**: `@run-at document-start` to inject before page loads

### Installer Scripts
- **macOS scripts**: Require `osacompile`, `PlistBuddy`, `lsregister` (all built-in)
- **Windows scripts**: Require Administrator privileges
- **Installation locations**:
  - macOS: `~/Applications/<App Name>.app`
  - Windows: `%LOCALAPPDATA%\plex-mpv-handler\`
- **Prerequisites**: Target player must be installed first

## Recent Changes (from Git Log)
- Added IINA player support (PR #14)
- Added MPV player support with URL handlers (PRs #8-#13)
- Fixed macOS installer to use AppleScript
- Implemented base64 encoding to prevent URL mangling
- Removed debug logging from handlers

## Important Caveats

1. **No TypeScript**: Pure JavaScript, no type checking
2. **No Build System**: Single-file userscript, no bundling/minification
3. **No Package Manager**: No npm/package.json - all code is self-contained
4. **No Linting/Formatting**: No ESLint, Prettier, or similar tools configured
5. **No CI/CD**: Manual testing required
6. **No Versioning Strategy**: Update `@version` manually in userscript header
7. **Platform-Specific**: macOS installers won't work on Windows and vice versa
8. **Plex-Specific**: Tightly coupled to Plex web interface DOM structure - may break on Plex updates
9. **Browser Extension Required**: Requires Tampermonkey (or similar userscript manager)

## Adding New Features

When adding features, maintain the existing architecture:
- Use `domPrefix` for all injected elements
- Add functions to appropriate namespace objects (`modal.*`, `serverData.*`, etc.)
- Use existing error handling (`errorHandle()`)
- Respect privacy (redact sensitive data in logs)
- Test on multiple media types (movies, episodes, seasons, shows, collections)
- Update both userscript and README
- Increment `@version` number

## Testing Checklist

Before committing:
- [ ] Test on movie (single file)
- [ ] Test on episode (single file with parent/grandparent)
- [ ] Test on season (multi-file with children)
- [ ] Test on show (multi-file with nested children)
- [ ] Test on collection (multi-file, no parent relationship)
- [ ] Test player selection via right-click menu
- [ ] Test all supported players (if hardware available)
- [ ] Test URL handler installers (if platform available)
- [ ] Verify no console errors
- [ ] Check button appears in correct location
- [ ] Verify progress tracking works
- [ ] Test keyboard navigation in modal
