# Changelog

## Unreleased

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
