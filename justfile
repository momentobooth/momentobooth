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

# RUSTC_BOOTSTRAP: since Rust 1.100, cargo-expand (used by flutter_rust_bridge_codegen) no longer gets its nightly flag accepted on Windows.
gen-bridge $RUSTC_BOOTSTRAP="1":
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

watch-bridge $RUSTC_BOOTSTRAP="1":
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

# Runs the Rust unit tests. The CUPS integration tests skip themselves unless CUPS_TEST_URI is set (see test-cups).
[windows]
test-rust:
  $env:PATH = "{{justfile_directory()}}/.native_deps/windows-x64/bin;$env:PATH"; cargo test --manifest-path rust/Cargo.toml --lib

[unix]
test-rust:
  cargo test --manifest-path rust/Cargo.toml --lib

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

# The same versions as the documentation workflows.
install-mdbook:
  cargo install mdbook --version 0.5.1 --locked
  cargo install mdbook-mermaid --version 0.17.1 --locked

build-docs: install-mermaid
  mdbook build documentation

# Installs Mermaid in the documentation. mdbook-mermaid does not replace existing files, so the old ones go first.
[windows]
install-mermaid:
  -Remove-Item -ErrorAction Ignore documentation/mermaid.min.js, documentation/mermaid-init.js
  mdbook-mermaid install documentation

[unix]
install-mermaid:
  rm -f documentation/mermaid.min.js documentation/mermaid-init.js
  mdbook-mermaid install documentation

##
# Other commands
##

lint:
  fvm flutter analyze

# Runs the checks of the pull request CI: regenerates the bridge, Dart code and localizations, then runs the analyzer, the Flutter tests and the Rust unit tests. Run it before opening a pull request.
check: gen-bridge gen-code gen-l10n lint test test-rust

# Runs the analyzer and the Flutter tests without regenerating code first, for quick feedback while working.
check-quick: lint test

show-outdated:
  fvm flutter pub outdated
  cd rust && cargo update -n

upgrade-deps:
  fvm flutter pub upgrade
  cd rust && cargo update
