# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MomentoBooth is a cross-platform photo booth application (Windows, Linux, macOS) built with **Flutter (Dart)** for the UI and **Rust** for performance-critical hardware control, image processing, and native integrations. The two layers communicate via **flutter_rust_bridge v2**.

## Commands

All build tasks use `just` (see `justfile`). Flutter commands use `fvm flutter` (Flutter Version Manager).

| Task | Command |
|------|---------|
| Install dependencies | `just` (default recipe) |
| Get Flutter deps | `just get-deps` |
| Run tests | `just test` |
| Lint (Dart analysis) | `just lint` |
| Build release | `just build-release` |
| Single test file | `fvm flutter test test/path/to/file_test.dart` |

### Code Generation

Generated files (`*.freezed.dart`, `*.g.dart`, `lib/src/rust/`) are not committed and must be regenerated after model or Rust API changes:

| Task | Command |
|------|---------|
| Generate Rust↔Dart bridge | `just gen-bridge` |
| Generate Freezed/MobX/JSON | `just gen-code` |
| Generate localizations | `just gen-l10n` |
| Watch bridge changes | `just watch-bridge` |
| Watch Dart gen changes | `just watch-code` |

After pulling changes that modify `rust/src/api/**/*.rs` or any `*.dart` model files, run `just gen-bridge` and/or `just gen-code` before building.

## Architecture

### Flutter Side (`lib/`)

```
lib/
├── main.dart                  # Entry point
├── momento_booth_app.dart     # Root widget + go_router routing
├── views/                     # UI screens (Fluent UI widgets)
├── managers/                  # MobX stores — all app state lives here
├── models/                    # Freezed immutable data classes
├── repositories/              # Persistence (TOML config, encrypted storage)
├── hardware_control/          # Camera/printer abstractions (Dart side)
├── l10n/                      # ARB localization files (en, nl, fr, de)
└── src/rust/                  # Auto-generated Rust↔Dart FFI bindings
```

**UI framework:** `fluent_ui` (Windows design language)
**Routing:** `go_router`
**State management:** MobX (`mobx` + `flutter_mobx`) — managers are MobX stores observed by views
**Models:** `freezed` for immutability and serialization

### Rust Side (`rust/src/`)

```
rust/src/
├── api/           # Functions exposed to Dart via flutter_rust_bridge
│   ├── nokhwa.rs  # Webcam capture
│   ├── gphoto2.rs # Digital camera (libgphoto2)
│   ├── cups.rs    # Printing (CUPS / IPP)
│   ├── ffsend.rs  # Photo sharing (Firefox Send)
│   ├── images.rs  # Image processing
│   └── sfx.rs     # Sound effects
├── hardware_control/
│   └── live_view/ # Live camera feed streaming
├── models/        # Shared data structures
└── utils/         # Image utilities, network clients
```

### Flutter↔Rust Bridge

- Config: `flutter_rust_bridge.yaml` maps `rust/src/api/**/*.rs` → `lib/src/rust/`
- To add a new Rust function callable from Dart: add it to a file under `rust/src/api/`, then run `just gen-bridge`
- Generated Dart bindings land in `lib/src/rust/api/` and `lib/src/rust/frb_generated.dart`

## Key Patterns

**Adding a new Dart model:** Create a Freezed class in `lib/models/`, run `just gen-code` to generate `.freezed.dart` and `.g.dart`.

**Adding a new Rust model:** Create a struct in `rust/src/models/`, run `just gen-bridge` to generate bridging code.

**Adding a new manager:** Create a MobX store in `lib/managers/` with `@observable`/`@action` annotations, run `just gen-code` to generate `.g.dart`.

**Hardware control flow:** Dart `hardware_control/` classes call generated Rust bindings in `lib/src/rust/api/` which dispatch to Rust implementations in `rust/src/api/`.

**Settings persistence:** Managed via `SettingsManager` + repositories using TOML files.

**Home Assistant integration:** `MqttManager` handles MQTT communication for automation (e.g., WLED lighting sync during countdown).

## Development Setup

Requires:

- Flutter 3.47.2 via FVM (`just install-flutter`)
- Rust via rustup
- `flutter_rust_bridge_codegen` 2.13.0 (`just install-bridge-codegen`)
- **Windows:** MSYS2 with `libgphoto2`, `pkgconf`, `curl`
- **Linux:** `llvm`, `libssl-dev`, `libcurl4-openssl-dev`, `libasound2-dev`
- **macOS:** Homebrew `pkgconf`, `libgphoto2`

Full setup guide: `documentation/src/dev_setup.md`
