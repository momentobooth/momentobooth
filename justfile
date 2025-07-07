default: install-cargo-expand install-bridge-codegen install-flutter get-deps gen-bridge gen-code gen-l10n

set windows-shell := ["pwsh.exe", "-NoProfile", "-c"]

##
# Basic commands
##

install-cargo-expand:
  cargo install cargo-expand

install-bridge-codegen:
  cargo install flutter_rust_bridge_codegen@2.11.1

install-flutter:
  fvm install -s --skip-pub-get

get-deps:
  fvm flutter pub get

gen-bridge:
  flutter_rust_bridge_codegen generate

gen-code:
  fvm dart run build_runner build --delete-conflicting-outputs

gen-l10n:
  fvm flutter gen-l10n

##
# Signing
##

install-dev-cert:
  bundle exec fastlane match development

install-release-cert:
  bundle exec fastlane match developer_id

##
# Watching
##

watch-bridge:
  flutter_rust_bridge_codegen generate --watch

watch-code:
  fvm dart run build_runner watch --delete-conflicting-outputs

##
# Building
##

[windows]
build-release:
  fvm flutter build windows --release

[linux]
build-release:
  fvm flutter build linux --release

[macos]
build-release:
  fvm flutter build macos --release

test:
  fvm flutter test

##
# Docs
##

install-mdbook:
  cargo install mdbook mdbook-mermaid mdbook-admonish

build-docs:
  mdbook build documentation

##
# Other commands
##

lint:
  fvm flutter analyze

show-outdated:
  fvm flutter pub outdated
  cd rust && cargo update -n

upgrade-deps:
  fvm flutter pub upgrade
  cd rust && cargo update
