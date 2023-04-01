# Flutter + Rust example for `flutter_rust_bridge`

## Development

### Requirements

### Getting Started

1. Run `flutter_rust_bridge_codegen --rust-input rust/src/dart_bridge/api.rs --dart-output lib/rust_bridge/library_api.generated.dart --rust-output rust/src/dart_bridge/ffi_exports.rs --skip-add-mod-to-lib --no-build-runner`

### Adding a new screen using the VS Code extension Template

1. Make sure to have the [Template](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) extension installed
2. Right click the `views` folder in VS Code Explorer
3. Click _Template: Create New (with rename)_, pick the `view` template
4. Pick a name, enter it in `snake_case`, press Enter
5. Your new view should be available!

## Features

### Currently available

- [X] Flutter/Rust bridge working on
  - [X] Windows
  - [X] macOS
  - [ ] Linux

### Planned

- [ ] Proper docs
