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

All platforms:
- `flutter_rust_bridge_codegen`
  - Install using Cargo: `cargo install flutter_rust_bridge_codegen`
- Flutter SDK 3.7+
  - When using Flutter SDK managers like `asdf` or `fvm` be sure that the `flutter` command is available globally as `flutter_rust_bridge_codegen` needs it

For all tools, we support the latest versions.

### Getting Started

1. Run `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --skip-add-mod-to-lib --no-build-runner`

### Adding a new screen using the VS Code extension Template

1. Make sure to have the [Template](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) extension installed
2. Right click the `views` folder in VS Code Explorer
3. Click _Template: Create New (with rename)_, pick the `view` template
4. Pick a name, enter it in `{snake_case}_screen` format (e.g. `settings_screen` or `email_photo_screen`), press Enter
5. Your new view should be available!

## Features

### Currently available

- [X] Flutter/Rust bridge working on
  - [X] Windows
  - [X] macOS
  - [ ] Linux

### Planned

- [ ] Proper docs
