# Changelog

All notable changes to Clipper are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

## [2.0.0] — 2026-07-26

### Added
- **App icon** — calm dark-indigo clipboard icon; appears in Finder, About box, and dock when shown
- **Settings panel** — gear icon in header opens settings: launch at login, sound on copy, max history count, paste-plain-text mode
- **Launch at login** — toggle via settings; uses `SMAppService` (macOS 13+)
- **Sound on copy** — plays a soft "Pop" sound when a new item is captured (on by default)
- **Paste plain text** — strips rich-text formatting on paste so pasted text adopts target app's style
- **Character count** — each text entry shows its character count in the subtitle row
- **Quick Templates** — on first launch, pre-seeds the pinned section with email sign-off, today's date, separator, TODO, and a Lorem snippet
- **Max history limit** — configurable via settings (default 100, range 20–500)



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
