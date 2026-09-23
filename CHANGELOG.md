# Changelog

## Unreleased

### New features
- MomentoBooth checks GitHub for newer releases on startup and shows the changelog of every newer version during onboarding
- Added a "Releases" item to the Help menu
- The About screen now shows which version was taken into use on which date

### Changes
- Added a setting to enable or disable the check for new versions

### Dev changes
- Release notes on GitHub now contain the changelog section of the released version
- Add a debug-only mock app version setting to test the update check

## 0.16.1

### New features
- A project can now hide the gallery for events where guests should not browse previously captured photos
- A project can now hide the 'Get QR' button for events where online sharing is not used

### Changes
- Details can now be shown for successful external health checks runs
- Settings screen now opens on the Quick Settings tab instead of Project settings
- Added back and close buttons to the Settings screen navigation

### Dev changes
- Updated Flutter to 3.47.2
- Updated Dart and Rust dependencies
- Removed unused dependencies (Dart: wave; Rust: num, plus the unused bindgen/pkg-config build dependencies)
- Add photos and capture section to debug panel in settings
- Add debug actions to start and stop video recording on supported cameras
- Add debug action to retrieve the list of files stored on supported cameras
- Add camera config getters and setters to debug screen
- Add debug button to dump full camera info to clipboard

## 0.16.0

### New features
- Add support for a live view overlay image
- Introduced .webp as a supported template format
- Add return to home warning overlay

### Changes
- Reworked imaging device selection with one-click device buttons (including onboarding integration) for simpler setup

### Bugfixes
- Fix cases where toggling a setting then trying to close the Settings screen could cause an overlay of a new Settings screen instance
- Fix position/size of Hollywood theme stars

### Dev changes
- Updated Flutter to 3.41.0
- Updated Dart and Rust dependencies
- Switch linker on Windows to `lld-link` to speedup build

## 0.15.7

### Bugfixes
- Fix wrong page size in print job generation causing paper layout issues

### Dev changes
- Updated Flutter to 3.38.7
- Updated Dart and Rust dependencies
- Add optional extensive print job logging

## 0.15.6

### Bugfixes
- Fix collage flow still taking one capture

## 0.15.5

### New features
- A project can now define a display language that, if set, overrides the system setting
- A project can now define a set of available languages that users can choose from themselves for multi-lingual events
- Show an optional touch indicator on the start screen
- Add option for a no border layout for single photo collages
- Add German and French translations (quality is yet to be verified!)

### Changes
- Choose capture mode screen is changed to a more general purpose navigation screen

### Dev changes
- Updated Flutter to 3.38.4
- Updated Dart and Rust dependencies
- Add color vision deficiency simulation

## 0.15.4

### Dev changes
- Updated Flutter to 3.38.3
- Updated Dart and Rust dependencies

## 0.15.3

### Bugfixes
- Fix `-f` argument not working
- Workaround full screen not working properly on Windows when window was maximized

### Dev changes
- Updated Dart and Rust dependencies

## 0.15.2

### New features
- Add setting to show a 'Open Settings' button on the Start screen
- Add Wedding theme
- Add ffsend timeout option with more sensible defaults instead of relying using the library's far too high defaults

### Dev changes
- Fix Windows release pipeline not bundling library (and yank 0.15.1 and 0.15.0 from GitHub releases due to this issue)
- Replace EXIF reading with exiv2 and gexiv2 by the native Rust crate `little_exif`

## 0.15.1

### Dev changes
- Fix Windows release workflow crashing due to missing h3xup binary

## 0.15.0

### New features
- Add themes
- Add systems health check to test if user provided external services are online
- Add settings for controlling available capture type options
- Add wakelock setting to try keeping the computer and screen awake

### Changes
- Improve print job names with naming convention
- Improve application stability and observability by showing app initialization state
- Block further usage of the application when critical issues occur during initialization
- Onboarding wizard now only appears when it has not been finished yet or when there are issues the user needs to know about
- Increase some UI scaling

### Bugfixes
- Fix collage generation issues in multi capture
- Fix (subtle but noticeable) black border around live view background
- Fix Settings overlay closing spontaneously sometimes
- Fix application not fully initializing and being mostly unusable in some cases
- Fix gallery empty screen when PNGs are present in output folder
- Fix MQTT current route reporting
- Subsystem warnings were incorrectly reported as the subsystem being busy

### Dev changes
- Updated Flutter to 3.35.4
- Updated Dart and Rust dependencies
- Updated Rust library to Rust 2024 edition
- Fix hot reload not functioning
- Revamp photo booth theming system with `theme_tailor`
- Remove obsolete external libraries naming instructions for Windows
- Replace Dart `audio_player` with Rust `cpal`
- Use `cargo-binstall` for Rust dependency installations in workflows
- Implement `h3xUpdtr` in Windows workflows for fast and easy version switching
- Enable MSVC `/MP` compiler option to speedup compilation a bit
- Fix sccache not being used by the Windows workflows

## 0.14.5

### Bugfixes
- Fix laggy rotate animation in collage creator screen
- Fix image preview issues

### Changes
- Show progress ring when collage is being generated

## 0.14.4

### Bugfixes
- Fix sound effects not working on Windows and macOS
- Fix TLS connections to IPP print servers not working anymore
- Fix progress bars being large and overflowing in the UI

### Changes
- Improved look of Settings screen

## 0.14.3

### Bugfixes
- Fix settings not being saved in some exceptional cases
- Windows installer now checks version of C++ redistributable libraries (might fix crashes due to outdated libraries)

### Changes
- About screen now shows libusb version

### Dev changes
- Updated Flutter to 3.29.2
- Updated Dart and Rust dependencies

## 0.14.2

### Bugfixes
- Fix multi capture not continuing after first capture

## 0.14.1

### Bugfixes
- Improve camera live view (re)connect stability (again)
- Fix crash when having no webcams connected on Windows

### Dev changes
- Updated Flutter to 3.29.1
- Updated Dart and Rust dependencies

## 0.14.0

### New features
- Onboarding wizard showing app status, allowing to pick the project folder, etc.
- Settings screen now has a subsystem status page showing app status
- Having an invalid setting file now results in a subsystem warning (granting the opportunity to fix the issue) instead of just writing defaults to the file
- Menu bar (hidden when full screen) showing the options that were previously only available as hotkey
- Command line options (`--fullscreen` of `-f` to open the app in full screen, `--open` or `-o` to open a project at startup)
- Settings import (to merge the provided settings with the existing settings)

### Bugfixes
- Fix animation glitchyness when opening a photo from the Gallery
- Improve camera live view (re)connect stability

### Changes
- When in Photo Details screen, don't show the live view (except the blurry background) to decrease amount of visual clutter
- App requires a project folder now (used for storing project specific settings, photos, templates, etc.)

### Dev changes
- Updated Flutter to 3.29.0
- Updated Dart and Rust dependencies

## 0.13.1

### Bugfixes
- Fix macOS release script (no effect on Windows and Linux)

## 0.13.0

### Changes
- App releases are being build for macOS now (Apple Silicon and Intel)

### Dev changes
- Updated Flutter to 3.24.3
- Updated Dart and Rust dependencies

## 0.12.1

### Bugfixes
- Workaround error spam caused by Windows printer status detection

## 0.12.0

### Changes
- Show libgphoto2, libgexiv2 and libexiv2 versions in About screen
- App now available as installer

## 0.11.0

### New features
- Allow overriding the default 'Touch to start' text
- Add About tab to Settings screen, that shows app/library/Flutter/Rust versions

### Bugfixes
- Fixed several issues with newer Sony cameras with Windows builds

### Dev changes
- Updated Flutter to 3.24.1
- Windows builds now use the latest master version of libgphoto2
- Updated Dart and Rust dependencies

## 0.10.0

### New features
- Log (accessible from Settings screen) now also includes libgphoto2 library logging (mostly camera errors)

### Bugfixes
- Any configured directories (e.g. capture output, templates) are now created to fix errors occuring due to non-existent directories
- Fix errors occuring due to asking for status updates while the camera is not ready yet
- Fix errors occuring due to printer status detection using wrong code for logging

### Changes
- Helper library now utilizes `log` crate instead of custom 'log to Dart' solution
