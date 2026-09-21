# Changelog

All notable changes to this project will be documented in this file.
This changelog only shows changes from Version 3.0.0-beta.1 onwards.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] (3.0.0-rc.10)

### Added

- Added an optional Emergency Vehicle Handler (EVH) Auto Loader, with an installation prompt in the plugin. It loads the latest published handler when the game starts and helps vehicles inserted from the Toolbox run with the permissions they need.

### Changed

- Installing EVH or upgrading an older EVC Chassis Plugin now uses a confirmation popup.
- Improved compatibility with Roblox's script permissions when loading vehicles through the plugin.

### Fixed

#### Editing and saving

- Changing the plugin or Studio theme now reloads the selected vehicle's settings into the editor instead of leaving the panels empty. It also stops old pattern previews and prevents selection errors after the theme changes.
- Loading a saved pattern now marks it as needing export. Adding or removing fader and rotator steps also updates the export indicator, so those edits are no longer easy to miss.
- Loading a standalone pattern after editing a vehicle no longer causes an error or tries to change the previous vehicle.
- New activation rules are now included when you export, without requiring another edit first.
- Deleting faders and rotators now shows the confirmation popup correctly.
- Changing a fader or rotator step's type no longer leaves old controls behind.
- Deleting the first light column in a flasher section no longer causes an error.
- Settings rows no longer keep getting taller as their options change.
- The light transparency field now shows the vehicle's saved setting when it loads.
- Renaming a function now updates the override rules that depend on it, so those rules keep working.
- Function names that differ only by spaces or punctuation, such as "A B" and "AB", no longer conflict in-game. New or renamed functions receive a unique name when needed.
- Invalid function weights, such as zero, negative numbers, or fractions, no longer break the function list when entered in the editor.
- Selecting a range of lights with Shift no longer adds the same light to a group more than once. Deselecting a light now removes it as expected.
- New light groups receive unique names instead of all being called "Group" and controlling the same lights in-game.
- Deleting a color no longer changes the remaining pattern colors to the wrong colors. References to the deleted color are cleared in flashers, faders, and rotators.
- Fixed an error when checking for changes in saved patterns or pattern settings that contain mismatched data.

#### Vehicle setup and exports

- Fixed MG-Chassis vehicles not being recognized when checking, installing, or upgrading their lighting handler.
- Replacing or removing equipment now affects the selected mounting location, even when another location has equipment with the same name.
- Reopening equipment settings now shows the saved light prefix. Clicking into the field and leaving it unchanged no longer clears the prefix.
- Closing the plugin while placing a vehicle no longer leaves the placement overlay active the next time you open it.
- Fixed generated Custom Export scripts failing to run. Light names containing quotation marks or backslashes no longer break the exported script.
- The update notice no longer says a newer installed version is out of date. Preview versions are also compared in the correct order, including numbers such as rc.9 and rc.10.

#### Lighting in-game

- Rotators now turn at a consistent speed regardless of frame rate, both in previews and in-game.
- Quickly turning a rotator off and back on no longer leaves it stuck. Restarted patterns also begin their fade and rotation steps from the correct starting point.
- Faders now follow their scheduled steps and pauses across repeated loops. A pause holds the completed fade's brightness instead of leaving the light partway through the fade.
- Turning off a fader now fades smoothly from its current brightness, including when it is paused, instead of jumping to an incorrect brightness.
- Zero-duration fade steps and zero-wait flasher patterns no longer cause playback errors. Zero-wait flashers advance one step per frame.
- Empty fader or rotator sequences no longer interrupt playback for other lights.
- Faders now turn on particle-based lights when needed instead of leaving them disabled.
- Fades and rotations finishing after a function is turned off no longer interfere with another function controlling the same lights. Patterns that never ran no longer trigger unwanted fades or rotations.
- Lower-priority lighting functions now resume correctly when a higher-priority function stops, including existing functions with zero or negative weights. Lights also regain their normal brightness when switching back from a fade to a flasher.
- Using the same light more than once in a pattern no longer causes a function to remain active after it is turned off.
- In games that load nearby objects as you move, newly loaded lights now show their active pattern instead of staying off. Light images added later also return to their normal appearance after fading.
- Removing a vehicle now stops its lighting effects completely instead of continuing to process lights that are no longer in the game.
- Lights marked to be ignored are now excluded even when the ignore setting is placed directly on the light part.
- Incomplete vehicle configurations no longer lose valid effects just because another effect type is missing. Invalid functions no longer prevent the next valid function from loading correctly.
- Invalid pattern selections no longer cause lighting playback errors.
- Override rules now work when the function they depend on has spaces or punctuation in its name.
- Fixed the handler failing to start when it is moved into a vehicle after loading, and prevented duplicate copies of a newer handler from running together.

#### Sirens

- Hold-to-play sirens now stop when you release the key, even if a menu captures the release, and when you leave the driver's seat while holding the key.
- With multiple siren modifiers, an inactive modifier no longer restarts the normal siren while another active modifier is supposed to stop it.
- Sirens set to override other sounds no longer mute their own modified sounds.

---

## [3.0.0-rc.9] (2026-03-21)

### Fixed

- Save/Load popup breaking after using it once.

### Removed

- Removed the unfinished "Custom Export" button that was accidently added

---

## [3.0.0-rc.8] (2026-03-20)

### Fixed

- Reverted the bump to lemon (the Fusion fork we use) as it somehow broke our add buttons on list components. 

---

## [3.0.0-rc.7] (2026-03-11)

### Fixed

- Bumped luaencode again to hopefully fix the plugin again. ([#553](https://github.com/Redon-Tech/Emergency-Vehicle-Creator/pull/55))

---

## [3.0.0-rc.6] (2026-03-10)

### Fixed

- Bumped luaencode to latest which fixes exports failing.
- Refactored popup system. (#53)
- (EVH) Fixed return to zero on faders sometimes causing errors. AFAIK this didn't actually affect anything functionally.
- (EVH) Fixed lights not respecting light settings when first being loaded.

---

## [3.0.0-rc.5] (2025-11-04)

### Fixed

- (EVH) Fixed sirens not being detected in the vehicle properly loading sirens to not work
- (EVH) Fixed a bug with modifiers causing all sirens to play at once

---

## [3.0.0-rc.4] - 2025-10-08

### Fixed

- (EVH) Version being incorrect causing the plugin to not update the handler

---

## [3.0.0-rc.3] - 2025-10-07

### Fixed

- Fixed the export button not showing whent the plugin was closed without returning to menu
- (EVH) Fixed an issue were one row patterns would not reactivate correctly
- (EVH) Fixed an issue were faders/rotators were not advancing properly leading to incorrect behavior
- (EVH) Fixed an issue were overrides were not turning off when the dependent function turns off

---

## [3.0.0-rc.2] - 2025-10-02

### Fixed

- Plugin always reporting out of date

---

## [3.0.0-rc.1] - 2025-10-02

### Added

- (EVH) Added back UpdateFunction event to allow manual control over functions from client scripts

### Changed

- (EVH) Changed the way EVH handles lighting to improve accuracy and performance
- (EVH) sirensLocation is no longer required, like lights, sirens will now be automatically detected

### Fixed

- Fixed customization buttons remaining visible when closing the plugin via the plugins menu
- Fixed a problem where users could select the same light group on itself causing crashes
- Fixed a problem where with HTTP disabled the plugin would refuse to load
- Fixed a problem where changing function weights could cause the numbers to fall out of sync
- (EVH) Fixed modifiers

---

## [3.0.0-beta.6] - 2025-02-24

### Fixed

- Export button dissapearing when returning to menu and editing previously opened vehicle
- (EVH) ColorableLightos not loading correctly when streamed in

---

## [3.0.0-beta.5] - 2025-02-23

### Added

- Support for AG-Chassis built in Stages, Traffic Advisor, and Scene events
- Ability to exclude models/folders lights from being loaded

### Fixed

- Siren modifiers not being saved to a vehicle properly causing the vehicle to be corrupted
- Light names not visually updating when changed
- (EVH) Vehicles now work properly in StreamingEnabled games

---

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

---

## [3.0.0-beta.3] - 2025-02-07

### Fixed

- Severely reduced the character count of exports to help solve some problems with exports failing

---

## [3.0.0-beta.2] - 2025-02-07

### Fixed

- Fixed a problem where saveLoad will error trying to convert old saves preventing the plugin from loading

## [3.0.0-beta.1] - 2025-02-07

- Initial public beta release.

[unreleased]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/compare/3.0.0-rc.9...main
[3.0.0-rc.9]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.9
[3.0.0-rc.8]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.8
[3.0.0-rc.7]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.7
[3.0.0-rc.6]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.6
[3.0.0-rc.5]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.5
[3.0.0-rc.4]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.4
[3.0.0-rc.3]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.3
[3.0.0-rc.2]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.2
[3.0.0-rc.1]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-rc.1
[3.0.0-beta.6]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.6
[3.0.0-beta.5]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.5
[3.0.0-beta.4]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.4
[3.0.0-beta.3]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.3
[3.0.0-beta.2]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.2
[3.0.0-beta.1]: https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/tag/3.0.0-beta.1