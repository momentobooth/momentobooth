# MomentoBooth

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-linux-appimage-x64.yml?label=Linux%20build)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-macos-x64.yml?label=macOS%20build)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-win-x64.yml?label=Windows%20build)
[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/momentobooth/momentobooth?include_prereleases&label=Latest%20version)](https://github.com/momentobooth/momentobooth/releases)

MomentoBooth is a cross-platform open source photo booth software. Capture your events in an easy and fun way!

[Download from GitHub](https://github.com/momentobooth/momentobooth/releases)

Check the online documentation at [https://momentobooth.github.io/momentobooth/](https://momentobooth.github.io/momentobooth/).

## Features

* Single capture
* Multi-capture\
  Shoot 4 photos and then select the ones you like to for a collage of 1, 2, 3, or 4 photos
* User friendly touch-centered interface
* Photo printing\
  Lots of settings included to size and position your print well
* Photo sharing using [`ffsend`](https://github.com/timvisee/ffsend) QR code
* Theming with collage template images (background and foreground)
* Webcam live view and capture support
  * Use HDMI capture dongles that act as a webcam
  * Use any cameras that support live view over USB through libgphoto2
* Camera capture support
  * With Sony Imaging Edge Remote using AutoIt
  * Capture using a camera that supports capture over USB through libgphoto2
* Statistics
* Clear settings panel
* Gallery with created images
  * Re-print or -share
* Manual collage creation for untethered handheld shooting
* Beautiful animations

### Planned

* Linux Flatpak distribution (x86_64 and arm64)
* Windows arm64 distribution (waiting for public GitHub Actions runners)

## Development

### Stack

* Languages: [Dart](https://dart.dev/), [Rust](https://www.rust-lang.org/), C++ (Windows, Linux), Swift (macOS)
  * Dart <-> Rust glue: [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge)
* UI: [Flutter](https://flutter.dev/)
  * UI kit: [fluent_ui](https://pub.dev/packages/fluent_ui)
  * Routing: [go_router](https://pub.dev/packages/go_router)
* Webcam: [Nokhwa](https://crates.io/crates/nokhwa)
* Printing: [Printing](https://pub.dev/packages/printing)
* Logging: [Talker](https://pub.dev/packages/talker)
* Data classes: [Freezed](https://pub.dev/packages/freezed)
* Firefox Send client: [ffsend-api](https://crates.io/crates/ffsend-api)
* JPEG decoding: [zune-jpeg](https://crates.io/crates/zune-jpeg), encoding: [jpeg-encoder](https://crates.io/crates/jpeg-encoder)

### Requirements

<details>
  <summary>On Windows:</summary>

* **Visual Studio 2022 Build Tools**
  * Optional: full Visual Studio 2022 installation
  * Select *Desktop development with C++* under the *Workloads* tab
* **Rust**
  * Recommended installation via [`rustup`](https://rustup.rs/) to keep components up to date
  * Use default options (MSVC host, target, and toolchain)
* **MSYS2**
  * Follow the instructions on the [MSYS2 website](https://www.msys2.org/)
  * Install the following packages:
    `mingw-w64-clang-x86_64-pkgconf mingw-w64-clang-x86_64-libgphoto2 mingw-w64-clang-x86_64-gexiv2 mingw-w64-clang-x86_64-curl-winssl mingw-w64-clang-x86_64-nghttp2 mingw-w64-clang-x86_64-nghttp3`
  * Make sure `{MSYS_INSTALL_PATH}\clang64\bin` is in your `PATH` (before other folders that also provide `pkg-config`/`pkgconf`)

</details>

<details>
  <summary>On macOS:</summary>

* **Xcode**
  * Installing from the App Store is recommended (automatic updates)
* **Rust** (`aarch64-apple-darwin` or `x86_64-apple-darwin`, depending on your architecture)
  * Recommended installation via [`rustup`](https://rustup.rs/)
  * `rustup` is also available via [Homebrew](https://formulae.brew.sh/formula/rustup)
* **Homebrew**
  * Install: `pkgconf libgphoto2 gexiv2`

</details>

<details>
  <summary>On Linux:</summary>

* **System packages**
  * See the [Flutter documentation](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools) for a list of required packages
  * Note: the installation command provided by Flutter may only work on Ubuntu — check your distro’s package names
* **Additional packages**
  * `llvm libssl-dev libdigest-sha-perl libcurl4-openssl-dev libasound2-dev`
* **Rust** (`x86_64-unknown-linux-gnu` or `aarch64-unknown-linux-gnu`, depending on your architecture)
  * Recommended installation via [`rustup`](https://rustup.rs/)

</details>

<details>
  <summary>All platforms:</summary>

* `flutter_rust_bridge_codegen`
  * Install using Cargo: `cargo install flutter_rust_bridge_codegen --version 2.11.1`
* Flutter SDK 3.29.0+
  * Be sure that the `flutter` command is available globally as `flutter_rust_bridge_codegen` needs it\
    This is especially important when using Flutter SDK managers like `asdf` or `fvm`
* Optional: For building the documentation mdBook and some extensions for mdBook are needed
  * Install using Cargo: `cargo install mdbook mdbook-mermaid mdbook-admonish`
* Be sure to read the docs for troubleshooting and workarounds

</details>

For all languages, frameworks and tools, we support the latest versions.

### Build steps

#### Using `just` (recommended)

Please note: This method expects global [fvm](https://fvm.app/) to be available and [just](https://github.com/casey/just?tab=readme-ov-file#installation).

1. Run `just` from the root folder of the repository
2. Run `flutter run` or use your IDE to run the application

#### Manually

<details>
  <summary>Instructions:</summary>

Please note: Run all commands from the root folder of the repository, unless mentioned otherwise.

1. Run `flutter gen-l10n`.
2. Run `flutter_rust_bridge_codegen generate`:
    * Note: Make sure to re-run this command if you changed anything in the Rust subproject
3. Run `dart run build_runner build`
4. Run `flutter run` or use your IDE to run the application
    * Note: This will automatically build the Rust subproject before building the Flutter project, so no need to worry about that!

</details>

#### Some additional notes

* If you have changed any code in the Dart or Rust project that could change the generated bridging code, you should re-run the `flutter_rust_bridge_codegen generate` or `just gen-bridge` command
  * You can also run `flutter_rust_bridge_codegen generate --watch` or `just watch-bridge` to automatically regenerate the bridging code when you save a file
  * You might need to run `dart run build_runner build --delete-conflicting-outputs` or `just gen-code`
* If you have changed any code related to JSON or TOML serialization, or MobX, you should re-run the `dart run build_runner build --delete-conflicting-outputs` or `just gen-code` command
  * You can also run `dart run build_runner watch --delete-conflicting-outputs` or `just watch-code` to automatically regenerate the code when you save a file
* If you have changed any code related to the localization, you should re-run the `flutter gen-l10n` of `just gen-l10n` command

<details>
  <summary>Adding a new screen using the VS Code extension Template:</summary>

1. Make sure to have the [Template](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) extension installed
2. Right click the `views` folder in VS Code Explorer
3. Click *Template: Create New (with rename)*, pick the `view` template
4. Pick a name, enter it in `{snake_case}_screen` format (e.g. `settings_screen` or `email_photo_screen`), press Enter
5. Your new view should be available!

</details>
