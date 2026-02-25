# Changelog

## [2.0.0+5] - 2026-02-25

### Added
- Playable Zero character with full moveset (saber combos, Raijingeki, Hyouretsuzan, Kuuenzan, Rekkoha)
- Playable Axl character with full moveset (pistol, Roll Dash, Copy Shot, Blast Launcher, hover)
- Ultimate X armor mod
- Character selection screen with X, Zero and Axl
- Difficulty mode selection (Normal / Hard)
- Remix music system with alternate stage tracks
- Final elevator cutscene
- Japanese language localization
- In-game timer (IGT) display option
- Boss achievement handler for multi-character tracking
- New Game+ support in save metadata

### Changed
- Refactored Player system to support multi-character state machine
- Updated all levels, bosses and enemies for multi-character compatibility
- Updated UI/menus for character selection and difficulty modes
- Updated base classes with time-stop support and multi-character hooks
- Bumped version to 2.0.0+5

### Fixed
- "Start Game" no longer resumes from previous save data — now properly starts fresh
- "Load Game" transitions directly to gameplay instead of returning to main menu
- Loading screen no longer briefly flashes the main menu before transitioning
- Back button in character selection returns to main menu instead of replaying intro
- Returning to main menu from character selection preserves background and music
- Null tween crash in Tools.gd when node is freed before tween executes
- DisclaimerScreen text centering restored to proper margins
- Missing resources and StageInfo type resolution errors
- WeaponDeflectable class registration and extends path
- Double spaces in translation strings
- Duplicate src/BossIntro/ directory removed
- Fullscreen toggle no longer triggers a full game save (now only saves config)

### Security
- Save system rewritten with A/B dual-slot protection against corruption
  - Each save slot now uses two alternating files (A and B) with a safety marker
  - Writes go to the inactive sub-slot; marker updates only after successful write
  - Loading reads from the safe sub-slot with automatic fallback to the other if corrupt
  - Old single-file saves are migrated automatically on first load
