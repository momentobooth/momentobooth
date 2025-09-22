# Changelog

## Unreleased

- New feature: Add themes
- New feature: Add systems health check to test if user provided external services are online
- New feature: Add settings for controlling available capture type options
- New feature: Add wakelock setting to try keeping the computer and screen awake
- Change: Improve print job names with naming convention
- Change: Improve application stability and observability by showing app initialization state
- Change: Block further usage of the application when critical issues occur during initialization
- Change: Onboarding wizard now only appears when it has not been finished yet or when there are issues the user needs to know about
- Bugfix: Fix collage generation issues in multi capture
- Bugfix: Fix (subtle but noticeable) black border around live view background
- Bugfix: Fix Settings overlay closing spontaneously sometimes
- Bugfix: Fix application not fully initializing and being mostly unusable in some cases
- Bugfix: Fix gallery empty screen when PNGs are present in output folder
- Bugfix: Fix MQTT current route reporting

- Dev change: Updated Flutter to 3.35.1
- Dev change: Updated Dart and Rust dependencies
- Dev change: Updated Rust library to Rust 2024 edition
- Dev change: Fix hot reload not functioning
- Dev change: Revamp photo booth theming system with `theme_tailor`
- Dev change: Remove obsolete external libraries naming instructions for Windows
- Dev change: Replace Dart `audio_player` with Rust `cpal`
- Dev change: Use `cargo-binstall` for Rust dependency installations in workflows
- Dev change: Implement `h3xUpdtr` in Windows workflows for fast and easy version switching
- Dev change: Enable MSVC `/MP` compiler option to speedup compilation a bit
- Dev change: Fix sccache not being used by the Windows workflows

## 0.14.5

- Bugfix: Fix laggy rotate animation in collage creator screen
- Bugfix: Fix image preview issues
- Change: Show progress ring when collage is being generated

## 0.14.4

- Bugfix: Fix sound effects not working on Windows and macOS
- Bugfix: Fix TLS connections to IPP print servers not working anymore
- Bugfix: Fix progress bars being large and overflowing in the UI
- Change: Improved look of Settings screen

## 0.14.3

- Bugfix: Fix settings not being saved in some exceptional cases
- Bugfix: Windows installer now checks version of C++ redistributable libraries (might fix crashes due to outdated libraries)
- Change: About screen now shows libusb version

- Dev change: Updated Flutter to 3.29.2
- Dev change: Updated Dart and Rust dependencies

## 0.14.2

- Bugfix: Fix multi capture not continuing after first capture

## 0.14.1

- Bugfix: Improve camera live view (re)connect stability (again)
- Bugfix: Fix crash when having no webcams connected on Windows

- Dev change: Updated Flutter to 3.29.1
- Dev change: Updated Dart and Rust dependencies

## 0.14.0

- New feature: Onboarding wizard showing app status, allowing to pick the project folder, etc.
- New feature: Settings screen now has a subsystem status page showing app status
- New feature: Having an invalid setting file now results in a subsystem warning (granting the opportunity to fix the issue) instead of just writing defaults to the file
- New feature: Menu bar (hidden when full screen) showing the options that were previously only available as hotkey
- New feature: Command line options (`--fullscreen` of `-f` to open the app in full screen, `--open` or `-o` to open a project at startup)
- New feature: Settings import (to merge the provided settings with the existing settings)
- Bugfix: Fix animation glitchyness when opening a photo from the Gallery
- Bugfix: Improve camera live view (re)connect stability
- Change: When in Photo Details screen, don't show the live view (except the blurry background) to decrease amount of visual clutter
- Change: App requires a project folder now (used for storing project specific settings, photos, templates, etc.)

- Dev change: Updated Flutter to 3.29.0
- Dev change: Updated Dart and Rust dependencies

## 0.13.1

- Bugfix: Fix macOS release script (no effect on Windows and Linux)

## 0.13.0

- Change: App releases are being build for macOS now (Apple Silicon and Intel)

- Dev change: Updated Flutter to 3.24.3
- Dev change: Updated Dart and Rust dependencies

## 0.12.1

- Bugfix: Workaround error spam caused by Windows printer status detection

## 0.12.0

- Change: Show libgphoto2, libgexiv2 and libexiv2 versions in About screen
- Change: App now available as installer

## 0.11.0

- New feature: Allow overriding the default 'Touch to start' text
- New feature: Add About tab to Settings screen, that shows app/library/Flutter/Rust versions
- Bugfix: Fixed several issues with newer Sony cameras with Windows builds

- Dev change: Updated Flutter to 3.24.1
- Dev change: Windows builds now use the latest master version of libgphoto2
- Dev change: Updated Dart and Rust dependencies

## 0.10.0

- New feature: Log (accessible from Settings screen) now also includes libgphoto2 library logging (mostly camera errors)
- Bugfix: Any configured directories (e.g. capture output, templates) are now created to fix errors occuring due to non-existent directories
- Bugfix: Fix errors occuring due to asking for status updates while the camera is not ready yet
- Bugfix: Fix errors occuring due to printer status detection using wrong code for logging
- Change: Helper library now utilizes `log` crate instead of custom 'log to Dart' solution
