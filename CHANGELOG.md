# Changelog

All notable changes to Clipper are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

## [1.1.0] — 2026-07-26

### Added
- Global hotkey changed to `⌘⇧C` (previously `⌘⇧V`)
- Popover now opens near the mouse cursor when invoked via hotkey
- Menu-bar icon click still anchors the popover to the icon (unchanged)

### Fixed
- Popover clamps to screen edges on any monitor

## [1.0.0] — 2026-07-26

### Added
- Menu-bar clipboard history (text + images)
- `⌘⇧V` global hotkey to toggle
- Click-to-paste with automatic focus restoration and CGEvent `⌘V`
- Live search / filter
- Pin items (persist across restarts)
- Delete individual items; bulk-clear unpinned
- Source app icon + name + relative timestamp per entry
- Native dark popover with NSVisualEffectView vibrancy
- Max 100 items; oldest unpinned auto-evicted
