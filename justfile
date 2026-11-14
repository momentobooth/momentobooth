default: install-cargo-expand install-bridge-codegen install-cargo-bundle-licenses install-flutter get-deps get-native-deps gen-bridge gen-code gen-l10n gen-licenses

set windows-shell := ["pwsh.exe", "-NoProfile", "-c"]

##
# Basic commands
##

install-cargo-expand:
  cargo install cargo-expand

install-bridge-codegen:
  cargo install flutter_rust_bridge_codegen@2.13.0

install-cargo-bundle-licenses:
  cargo install cargo-bundle-licenses@4.2.0

install-flutter:
  fvm install -s --skip-pub-get

get-deps:
  fvm flutter pub get

[windows]
get-native-deps:
  ./windows/get_native_deps.ps1

[macos]
get-native-deps:
  ./macos/get_native_deps.sh

[linux]
get-native-deps:
  @echo "Native dependencies are installed through the system package manager on this platform"

gen-bridge:
  flutter_rust_bridge_codegen generate

gen-code:
  fvm dart run build_runner build

gen-l10n:
  fvm flutter gen-l10n

gen-licenses:
  fvm dart run tool/generate_licenses.dart

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
  fvm dart run build_runner watch

##
# Building
##

[windows]
build-release: gen-licenses
  fvm flutter build windows --release

[linux]
build-release: gen-licenses
  fvm flutter build linux --release

[macos]
build-release: gen-licenses
  fvm flutter build macos --release

test:
  fvm flutter test

cups_test_container := "momentobooth-cups-test"

# Starts a CUPS server in Docker with the queue for the CUPS integration tests, on port 6310. Replaces a running one.
start-cups-test-server:
  -docker rm -f {{cups_test_container}}
  docker run -d --name {{cups_test_container}} -p 6310:631 -e ADMIN_PASSWORD=momentobooth ydkn/cups:380
  docker cp test/cups/setup.sh {{cups_test_container}}:/tmp/setup.sh
  docker exec {{cups_test_container}} sh /tmp/setup.sh

# Runs the CUPS integration tests (rust/src/tests/cups.rs) against a fresh CUPS server in Docker. The server keeps running afterwards, for debugging.
[windows]
test-cups: start-cups-test-server
  $env:CUPS_TEST_URI = "http://localhost:6310/"; $env:CUPS_TEST_USERNAME = "admin"; $env:CUPS_TEST_PASSWORD = "momentobooth"; $env:PATH = "{{justfile_directory()}}/.native_deps/windows-x64/bin;$env:PATH"; cargo test --manifest-path rust/Cargo.toml --lib

[unix]
test-cups: start-cups-test-server
  CUPS_TEST_URI=http://localhost:6310/ CUPS_TEST_USERNAME=admin CUPS_TEST_PASSWORD=momentobooth cargo test --manifest-path rust/Cargo.toml --lib

##
# Docs
##

install-mdbook:
  cargo install mdbook mdbook-mermaid

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
