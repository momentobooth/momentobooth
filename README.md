# MomentoBooth

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/h3x4d3c1m4l/momento-booth/release-linux-appimage-x64.yml?label=Linux%20build)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/h3x4d3c1m4l/momento-booth/release-macos-x64.yml?label=macOS%20build)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/h3x4d3c1m4l/momento-booth/release-win-x64.yml?label=Windows%20build)
[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/h3x4d3c1m4l/momento-booth?include_prereleases&label=Latest%20version)](https://github.com/h3x4d3c1m4l/momento-booth/releases)

MomentoBooth is a cross-platform open source photo booth software. Capture your events in an easy and fun way!

[Download from GitHub](https://github.com/h3x4d3c1m4l/momento-booth/releases)

## Features

* Single capture
* Multi-capture  
  Shoot 4 photos and then select the ones you like to for a collage of 1, 2, 3, or 4 photos
* User friendly touch-centered interface
* Photo printing  
  Lots of settings included to size and position your print well
* Photo sharing using [`ffsend`](https://github.com/timvisee/ffsend) QR code
* Theming with collage template images (background and foreground)
* Webcam live view and capture support
* Camera capture support
  * With Sony Imaging Edge Remote using AutoIt
* Statistics
* Clear settings panel
* Gallery with created images
  * Re-print or -share
* Manual collage creation for untethered handheld shooting
* Beautiful animations

### Planned

* Image capture support using gPhoto2
  * Windows first, but looking into other platforms as well
  * Because this library cannot "just" be compiled with MSVC, maybe use a second subproject and connect using shared memory
  * Capture first, then possibly also add live view
* Linux, macOS support
* User manual

### Maybe

* Direct printing support (using libusb) to fully control printing queue
  * Focus would be on Canon CP1300, Canon CP1500

## Development

### Stack

* Languages: [Dart](https://dart.dev/), [Rust](https://www.rust-lang.org/), C++ (Windows, Linux), Swift (macOS)
  * Dart/Rust glue: [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge)
* UI: [Flutter](https://flutter.dev/)
  * UI kit: [fluent_ui](https://pub.dev/packages/fluent_ui)
  * Routing: [go_router](https://pub.dev/packages/go_router)
* Webcam: [Nokhwa](https://crates.io/crates/nokhwa)
* Printing: [Printing](https://pub.dev/packages/printing)
* Logging: [Loggy](https://pub.dev/packages/loggy)
* Data classes: [Freezed](https://pub.dev/packages/freezed)
* Firefox Send client: [ffsend-api](https://crates.io/crates/ffsend-api)
* JPEG decoding: [zune-jpeg](https://crates.io/crates/zune-jpeg), encoding: [jpeg-encoder](https://crates.io/crates/jpeg-encoder)

### Requirements

On Windows:

* Visual Studio 2022 Build Tools
  * Optional: A full Visual Studio 2022 install
  * Make sure to select "Desktop development with C++" on the Workloads tab when installing
* Rust (`x86_64-pc-windows-gnu` target)
  * Install using `rustup` is recommended, to keep all components up to date

On macOS:

* Xcode
  * Install using App Store is recommended, to keep it up to date
* Rust (`aarch64-apple-darwin` and `x86_64-apple-darwin` targets)
  * Install using `rustup` is recommended, to keep all components up to date

On Linux:

* [This list](https://docs.flutter.dev/get-started/install/linux#additional-linux-requirements) of packages from the Flutter website
  * The install command provided by the Flutter website may only work on Ubuntu, please check your distro website for the corresponding package names
* Additional packages: llvm, libkeybinder-3.0-dev, libssl-dev
* Rust (`x86_64-unknown-linux-gnu` target)
  * Install using `rustup` is recommended, to keep all components up to date

All platforms:

* `flutter_rust_bridge_codegen`
  * Install using Cargo: `cargo install flutter_rust_bridge_codegen`
* Flutter SDK 3.10.0+
  * Be sure that the `flutter` command is available globally as `flutter_rust_bridge_codegen` needs it\
    This is especially important when using Flutter SDK managers like `asdf` or `fvm`

For all tools, we support the latest versions.

### Getting Started

### Build steps

Please note: Run all commands from the root folder of the repository, unless mentioned otherwise.

1. Run `flutter_rust_bridge_codegen`:
    * Windows/Linux: `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --skip-add-mod-to-lib --no-build-runner`
    * macOS: `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --c-output macos/Runner/bridge_generated.h --skip-add-mod-to-lib --no-build-runner`
    * Note: Make sure to re-run this command if you changed anything in the Rust subproject
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
    * Note: During development, it may be convenient to run `watch` instead of `build` to keep the script running to process any new or changes files
3. Run `flutter run` or use your IDE to run the application
    * Note: This will automatically build the Rust subproject before building the Flutter project, so no need to worry about that!

### Current workarounds which should be removed ASAP

* Pods `MACOSX_DEPLOYMENT_TARGET` is overridden to 11.0 due to macOS build error which seems to come from the `hotkey_manager` package

### Adding a new screen using the VS Code extension Template

1. Make sure to have the [Template](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) extension installed
2. Right click the `views` folder in VS Code Explorer
3. Click _Template: Create New (with rename)_, pick the `view` template
4. Pick a name, enter it in `{snake_case}_screen` format (e.g. `settings_screen` or `email_photo_screen`), press Enter
5. Your new view should be available!
