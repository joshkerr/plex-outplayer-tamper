# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the userscript follows
its `@version` header.

## [1.13.0]

### Security
- **URL handlers no longer forward attacker-controlled options to the player.** Any web
  page can invoke a registered `plex-mpv://` / `plex-iina://` link, and the decoded payload
  was passed straight to mpv/IINA as an argument — a crafted link could smuggle options such
  as `--script` (arbitrary code execution). The macOS (`install-mpv-handler-macos.sh`,
  `install-iina-handler-macos.sh`) and Windows (`install-mpv-handler.ps1`) handlers now
  reject anything that is not an `http(s)://` URL and use `--` to stop mpv option parsing.
  **Re-run the installer for your platform to pick up the fix.**

### Added
- Fallback DOM selectors for the Plex play button, plus a watchdog that logs a distinctive
  console warning (with the repo issues URL) if the button can't be injected on a media page
  — so Plex markup changes surface as a report instead of a silent no-op.
- `@updateURL` / `@downloadURL` / `@homepageURL` / `@supportURL` metadata so installed users
  auto-update from `main`.
- ESLint flat config and a Node `node:test` suite covering the pure helpers
  (`redactUrl`, `makeFilesize`, `makeDuration`, `parseUrl`).
- GitHub Actions CI: lint + tests on push/PR, and a check that `@version` is bumped whenever
  `plex-outplayer.js` changes.

### Changed
- Renamed the internal `download.*` namespace to `playback.*` to match what the script now
  does (open in an external player, not download via iframes).

### Removed
- Dead code: the vestigial hidden-iframe download machinery (`frameClass`/`frames`/`trigger`/
  `cleanUp`) and two commented-out blocks (Letterboxd links, an alternate API-recursion path).

## Prior versions

Earlier releases (≤ 1.12.5) are recorded only in the git history. Notable milestones:
IINA support, MPV support with per-platform URL handlers, base64 encoding to prevent URL
mangling, and the switch to a manually-built macOS app bundle.
