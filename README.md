# MomentoBooth

## Development

### Requirements

On Windows:
- Visual Studio 2022 Build Tools
  - Optional: A full Visual Studio 2022 install
  - Make sure to select "Desktop development with C++" on the Workloads tab when installing
- Rust (`x86_64-pc-windows-msvc` target)
  - Install using `rustup` is recommended, to keep all components up to date

On macOS:
- Xcode
  - Install using App Store is recommended, to keep it up to date
- Rust (`aarch64-apple-darwin` and `x86_64-apple-darwin` targets)
  - Install using `rustup` is recommended, to keep all components up to date

On Linux:
- [This list](https://docs.flutter.dev/get-started/install/linux#additional-linux-requirements) of packages from the Flutter website
  - The install command provided by the Flutter website may only work on Ubuntu, please check your distro website for the corresponding package names
- Additional packages: llvm, libkeybinder-3.0-dev, libssl-dev
- Rust (`x86_64-unknown-linux-gnu` target)
  - Install using `rustup` is recommended, to keep all components up to date

All platforms:
- `flutter_rust_bridge_codegen`
  - Install using Cargo: `cargo install flutter_rust_bridge_codegen`
- Flutter SDK 3.7+
  - Be sure that the `flutter` command is available globally as `flutter_rust_bridge_codegen` needs it\
    This is especially important when using Flutter SDK managers like `asdf` or `fvm`

For all tools, we support the latest versions.

### Getting Started

### Build steps

Please note: Run all commands from the root folder of the repository, unless mentioned otherwise.

1. Run `flutter_rust_bridge_codegen`:
    - Windows/Linux: `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --skip-add-mod-to-lib --no-build-runner`
    - macOS: `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --c-output macos/Runner/bridge_generated.h --skip-add-mod-to-lib --no-build-runner`
    - Note: Make sure to re-run this command if you changed anything in the Rust subproject
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
    - Note: During development, it may be convenient to run `watch` instead of `build` to keep the script running to process any new or changes files
3. Run `flutter run` or use your IDE to run the application
    - Note: This will automatically build the Rust subproject before building the Flutter project, so no need to worry about that!

### Current workarounds which should be removed ASAP

- `screenshot` is imported from git due to being incompatible with Flutter 3.10.x
- Pods `MACOSX_DEPLOYMENT_TARGET` is overridden to 10.13 due to macOS build error which seems to come from the `hotkey_manager` package
- `*.generated.dart` is temporarily un-ignored from source control (and `library_api.generated.dart` is included) due to `ffigen` generating code which doesn't directly compile on Flutter 3.10.x
  - If you have to regenerate it, make sure to add `final` to all classes that inherit from `ffi.Struct`
  - For CI/CD the build step is temporarily disabled

### Adding a new screen using the VS Code extension Template

1. Make sure to have the [Template](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) extension installed
2. Right click the `views` folder in VS Code Explorer
3. Click _Template: Create New (with rename)_, pick the `view` template
4. Pick a name, enter it in `{snake_case}_screen` format (e.g. `settings_screen` or `email_photo_screen`), press Enter
5. Your new view should be available!

## Features

### Currently available

- [X] App works on
  - [X] Windows
  - [X] macOS
  - [X] Linux

### Planned

- [ ] Proper docs
