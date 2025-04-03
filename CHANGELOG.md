# Changelog

## Unreleased

## 0.14.3

- Bugfix: Fix settings not being saved in some exceptional cases
- Bugfix: Windows installer now checks version of C++ redistributable libraries (might fix crashes due to outdated libraries)
- Change: About screen now shows libusb version
- Dependency update: Updated Flutter to 3.29.2
- Dependency update: Updated several Dart and Rust packages

## 0.14.2

- Bugfix: Fix multi capture not continuing after first capture

## 0.14.1

- Bugfix: Improve camera live view (re)connect stability (again)
- Bugfix: Fix crash when having no webcams connected on Windows
- Dependency update: Updated Flutter to 3.29.1
- Dependency update: Updated several Dart and Rust packages

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
- Dependency update: Updated Flutter to 3.29.0
- Dependency update: Updated several Dart and Rust packages

## 0.13.1

- Bugfix: Fix macOS release script (no effect on Windows and Linux) (#503)

## 0.13.0

- Change: App releases are being build for macOS now (Apple Silicon and Intel) (#499)
- Dependency update: Updated Flutter to 3.24.3 (#490)
- Dependency update: Updated several Dart and Rust packages (#490, #496, #499)

## 0.12.1

- Bugfix: Workaround error spam caused by Windows printer status detection (#486)

## 0.12.0

- Change: Show libgphoto2, libgexiv2 and libexiv2 versions in About screen (#462)
- Change: App now available as installer (#478)

## 0.11.0

- New feature: Allow overriding the default 'Touch to start' text (#468)
- New feature: Add About tab to Settings screen, that shows app/library/Flutter/Rust versions (#462)
- Bugfix: Fixed several issues with newer Sony cameras with Windows builds (#469)
- Dependency update: Updated Flutter to 3.24.1 (#465)
- Dependency update: Windows builds now use the latest master version of libgphoto2 (#469)
- Dependency update: Updated several Dart and Rust packages (#459, #461)

## 0.10.0

- New feature: Log (accessible from Settings screen) now also includes libgphoto2 library logging (mostly camera errors) (#457)
- Bugfix: Any configured directories (e.g. capture output, templates) are now created to fix errors occuring due to non-existent directories (#457)
- Bugfix: Fix errors occuring due to asking for status updates while the camera is not ready yet (#457)
- Bugfix: Fix errors occuring due to printer status detection using wrong code for logging (#457)
- Change: Helper library now utilizes `log` crate instead of custom 'log to Dart' solution (#457)
