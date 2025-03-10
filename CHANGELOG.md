# Changelog

All notable changes to this project will be documented in this file.
This changelog only shows changes from Version 3.0.0-beta.1 onwards.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.0-beta.6] - 2025-02-24

### Fixed

- Export button dissapearing when returning to menu and editing previously opened vehicle
- (EVH) ColorableLightos not loading correctly when streamed in

## [3.0.0-beta.5] - 2025-02-23

### Added

- Support for AG-Chassis built in Stages, Traffic Advisor, and Scene events
- Ability to exclude models/folders lights from being loaded

### Fixed

- Siren modifiers not being saved to a vehicle properly causing the vehicle to be corrupted
- Light names not visually updating when changed
- (EVH) Vehicles now work properly in StreamingEnabled games

## [3.0.0-beta.4] - 2025-02-09

### Added

- (EVH) ParticleEmitter support (disabled by default)

### Changed

- Removed usage of Attachments for Light Name display
- Made light groups recompute possible lights whenever the page is reopened
- (ELS Creator) Pausing after some actions is now automatically unpaused
- (EVH) Made unknown keybinds not load as a minor optimization

### Fixed

- Actually consider prerelease versions when checking version
- LuaEncode outputting warnings which would cause corrupt exports
- Fixed a problem where saveLoad would not let you load a save you already have loaded before without restarting
- Major overhauls to the handling of scopes throughout the UI to reduce errors/warnings
- Added a error correction system to vehicle loading to prevent corrupted exports from causing errors
- Fixed not being able to add siren modifiers
- (EVH) Fixed a problem where not having a dependent function set would cause the handler to error
- (EVH) Fixed a problem where EVH would not check descendants of a light but only children ([#33](https://github.com/Redon-Tech/Emergency-Vehicle-Creator/pull/33))
- (EVH) Added a ton of checks to prevent corrupted exports from causing the vehicle to not load

## [3.0.0-beta.3] - 2025-02-07

### Fixed

- Severely reduced the character count of exports to help solve some problems with exports failing

## [3.0.0-beta.2] - 2025-02-07

### Fixed

- Fixed a problem where saveLoad will error trying to convert old saves preventing the plugin from loading

## [3.0.0-beta.1] - 2025-02-07

- Initial public beta release.

[unreleased]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/compare/3.0.0-beta.6...main
[3.0.0-beta.6]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.6
[3.0.0-beta.5]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.5
[3.0.0-beta.4]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.4
[3.0.0-beta.3]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.3
[3.0.0-beta.2]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.2
[3.0.0-beta.1]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.1