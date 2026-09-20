# Setup

## Stack

* Languages: [Dart](https://dart.dev/), [Rust](https://www.rust-lang.org/), C++ (Windows, Linux), Swift (macOS)
  * Dart <-> Rust glue: [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge)
* UI: [Flutter](https://flutter.dev/)
  * UI kit: [fluent_ui](https://pub.dev/packages/fluent_ui)
  * Routing: [go_router](https://pub.dev/packages/go_router)
* Webcam: [Nokhwa](https://crates.io/crates/nokhwa)
* Printing: [Printing](https://pub.dev/packages/printing)
* Logging: [Talker](https://pub.dev/packages/talker)
* Data classes: [Freezed](https://pub.dev/packages/freezed)
* Firefox Send client: built into `rust/src/utils/ffsend_client`, on top of [tokio-tungstenite](https://crates.io/crates/tokio-tungstenite) and [aes-gcm](https://crates.io/crates/aes-gcm)
* JPEG decoding: [zune-jpeg](https://crates.io/crates/zune-jpeg), encoding: [jpeg-encoder](https://crates.io/crates/jpeg-encoder)

## Requirements

For all languages, frameworks and tools, we support the latest versions.

### For all platforms

* `flutter_rust_bridge_codegen`
  * Install using Cargo:

    ```sh
    cargo install flutter_rust_bridge_codegen --version 2.13.0
    ```

* Flutter SDK 3.47.0+
  * Be sure that the `flutter` command is available globally as `flutter_rust_bridge_codegen` needs it.\
    This is especially important when using Flutter SDK managers like `asdf` or `fvm`
* Optional: For building the documentation mdBook and some extensions for mdBook are needed
  * Install using Cargo:

    ```sh
    cargo install mdbook mdbook-mermaid
    ```

* Be sure to read the docs for troubleshooting and workarounds

### On Windows

* **Visual Studio 2026 Build Tools**
  * Optional: full Visual Studio 2026 installation
  * Select *Desktop development with C++* under the *Workloads* tab
    * Under installation details on the right panel, select the MSVC Build Tools, Windows 11 SDK, and C++ ATL (needed for Flutter secure storage plugin)
* **Rust**
  * Recommended installation via [`rustup`](https://rustup.rs/) to keep components up to date
  * Use default options (MSVC host, target, and toolchain)
* **MSYS2**
  * Follow the instructions on the [MSYS2 website](https://www.msys2.org/)
  * Install the following packages:

    ```
    mingw-w64-clang-x86_64-pkgconf mingw-w64-clang-x86_64-libgphoto2 mingw-w64-clang-x86_64-curl-winssl mingw-w64-clang-x86_64-nghttp2 mingw-w64-clang-x86_64-nghttp3
    ```

  * Make sure `{MSYS_INSTALL_PATH}\clang64\bin` is in your `PATH` (before other folders that also provide `pkg-config`/`pkgconf`)

### On macOS

* **Xcode**
  * Installing from the App Store is recommended (automatic updates)
* **Rust** (`aarch64-apple-darwin` or `x86_64-apple-darwin`, depending on your architecture)
  * Recommended installation via [`rustup`](https://rustup.rs/)
  * `rustup` is also available via [Homebrew](https://formulae.brew.sh/formula/rustup)
* **Homebrew**
  * Install with

    ```sh
    brew install pkgconf libgphoto2
    ```

* **Code signing certificates**
  * Both debug and release builds need a certificate and provisioning profile from the MomentoBooth certificates repository, see [Code signing on macOS](#code-signing-on-macos)

### On Linux

* **System packages**
  * See the [Flutter documentation](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools) for a list of required packages
  * Note: the installation command provided by Flutter may only work on Ubuntu — check your distro’s package names
* **Additional packages**

  ```
  llvm libssl-dev libdigest-sha-perl libcurl4-openssl-dev libasound2-dev
  ```

* **Rust** (`x86_64-unknown-linux-gnu` or `aarch64-unknown-linux-gnu`, depending on your architecture)
  * Recommended installation via [`rustup`](https://rustup.rs/)

## Build steps

### Using `just` (recommended)

Please note: This method expects global [fvm](https://fvm.app/) to be available and [just](https://github.com/casey/just?tab=readme-ov-file#installation).

1. Run `just` from the root folder of the repository
2. Run `flutter run` or use your IDE to run the application

### Manually

Please note: Run all commands from the root folder of the repository, unless mentioned otherwise.

1. Generate translation files.

   ```sh
   flutter gen-l10n
   ```

2. Generate Rust <-> Dart code

   ```
   flutter_rust_bridge_codegen generate
   ```

    * Note: Make sure to **re-run this command** if you changed anything in the Rust subproject.
3. Generate Dart helper code

   ```
   dart run build_runner build
   ```

4. Build and run the app with `flutter run` or use your IDE to run the application
    * Note: This will automatically build the Rust subproject before building the Flutter project, so no need to worry about that!

## Code signing on macOS

The macOS Xcode project uses **manual** code signing, so *both* debug and release builds need a certificate and a provisioning profile that are not part of this repository:

| Build configuration | Certificate | Provisioning profile |
| - | - | - |
| Debug & Profile (`flutter run`) | Apple Development | `match Development com.momentobooth.photobooth macos` |
| Release (`flutter build macos`) | Developer ID Application | `match Direct com.momentobooth.photobooth macos` |

These are shared through the private MomentoBooth certificates repository and are installed with [fastlane match](https://docs.fastlane.tools/actions/match/). You need read access to that repository — ask a maintainer if you do not have it.

### One-time setup

1. Install the Ruby dependencies (this installs fastlane in the version this repository is tested with):

   ```sh
   bundle install
   ```

2. Copy `.env.example` to `.env` in the root of the repository and fill in the values:

   ```ini
   MATCH_CERTIFICATES_GIT_URL=git@github.com:momentobooth/certificates.git
   MATCH_CERTIFICATES_GIT_FULL_NAME="Your Full Name"
   MATCH_CERTIFICATES_GIT_EMAIL=you@yourdomain.com

   APP_STORE_CONNECT_KEY_ID=ABCD123456
   APP_STORE_CONNECT_ISSUER_ID=00000000-0000-0000-0000-000000000000
   APP_STORE_CONNECT_KEY=base64-of-the-AuthKey_ABCD123456.p8-file
   ```

   * fastlane automatically picks up the `.env` in the root of the repository
   * `.env` is git ignored — never commit it
   * The match passphrase is not part of this file: fastlane asks for it the first time you run one of the lanes below and stores it in your macOS Keychain, so you only have to enter it once — ask a maintainer for it
   * The App Store Connect API key values are the same ones CI uses, see [On CI](#on-ci) for where they come from — ask a maintainer rather than creating a second key

3. Make sure the SSH key of your machine has access to the certificates repository (`ssh -T git@github.com` should greet you by name).

### Installing the certificates

```sh
bundle exec fastlane install_dev_cert      # needed to run debug builds
bundle exec fastlane install_release_cert  # needed to make release builds
```

If you have fastlane installed globally, you can leave out the `bundle exec` prefix.

Both lanes authenticate with the App Store Connect API key, so they never ask you to log in interactively. They install what is in the certificates repository into your login keychain, and create or renew a certificate when the repository does not hold a valid one.

Certificates land in your login keychain, provisioning profiles in `~/Library/Developer/Xcode/UserData/Provisioning Profiles`. To check what you have installed:

```sh
security find-identity -v -p codesigning
```

### When a certificate has expired

`install_dev_cert` renews an expired development certificate by itself: it deletes the old one from the certificates repository, creates a new one, and pushes it back, so everybody else only has to run the lane again.

Renewing the *Developer ID* certificate can not be done this way. Apple only allows that with an **Account Holder** Apple ID (username and password), an API key does not have enough access for that certificate type. Apple also limits how many Developer ID certificates a team can have, so check with the other maintainers first, then run:

```sh
bundle exec fastlane match developer_id --renew_expired_certs true
```

Note that renewing does *not* revoke the old certificate on the Apple Developer portal, so it keeps occupying a certificate slot of the team. Use `fastlane match nuke development` to free slots up, but be careful: that revokes certificates for the whole team.

### Troubleshooting

**`Service key is empty` / `Could not receive latest API key from App Store Connect`**

Apple removed the endpoint that fastlane uses to start an Apple ID login (`https://appstoreconnect.apple.com/olympus/v1/app/config` answers `404`), which breaks every interactive login, including `fastlane spaceauth`. The lanes above avoid it by using the API key.

If you do need an interactive login, hand fastlane the key it cannot fetch itself — it uses the contents of this file when it exists:

```sh
printf '%s' '<authServiceKey>' > /tmp/spaceship_itc_service_key.txt
```

You can read that value from your browser: open App Store Connect, sign out, and in the network tab of the developer tools look up the `X-Apple-Widget-Key` request header of the call to `idmsa.apple.com/appleauth/auth/signin`.

### On CI

CI uses the `ci_install_release_cert_using_api` lane, which is the same as `install_release_cert` but additionally runs `setup_ci` to install everything into a temporary keychain. **Do not run that lane on your own machine** — the temporary keychain disappears again, and the certificates will not be where Xcode expects them.

Its secrets are configured on the repository in GitHub. The App Store Connect API key values come from [App Store Connect](https://appstoreconnect.apple.com) → *Users and Access* → *Integrations* → *App Store Connect API* → *Team Keys*:

| Variable | Where to find it |
| - | - |
| `APP_STORE_CONNECT_KEY_ID` | The *Key ID* column of the key (10 characters) |
| `APP_STORE_CONNECT_ISSUER_ID` | The *Issuer ID* shown above the table |
| `APP_STORE_CONNECT_KEY` | The downloaded `.p8` file, base64 encoded: `base64 -i AuthKey_XXXXXXXXXX.p8` |

Note that Apple only lets you download the `.p8` file once, at the moment the key is created.

## Developing tips

### When to re-run build steps

* If you have changed any code in the **Dart** or **Rust** project that could *change the generated bridging code*, you should re-run the `flutter_rust_bridge_codegen generate` or `just gen-bridge` command
  * You can also run `flutter_rust_bridge_codegen generate --watch` or `just watch-bridge` to automatically regenerate the bridging code when you save a file
  * You might need to run `dart run build_runner build --delete-conflicting-outputs` or `just gen-code`
* If you have changed any code related to **JSON** or **TOML serialization**, or **MobX**, you should re-run the `dart run build_runner build --delete-conflicting-outputs` or `just gen-code` command
  * You can also run `dart run build_runner watch --delete-conflicting-outputs` or `just watch-code` to automatically regenerate the code when you save a file
* If you have changed any code related to the **localization**, you should re-run the `flutter gen-l10n` of `just gen-l10n` command

### Adding a new screen using the VS Code extension Template

1. Make sure to have the [Template extension](https://marketplace.visualstudio.com/items?itemName=yongwoo.templateplate) installed
2. Right click the `views` folder in VS Code Explorer
3. Click *Template: Create New (with rename)*, pick the `view` template
4. Pick a name, enter it in `{snake_case}_screen` format (e.g. `settings_screen` or `email_photo_screen`), press Enter
5. Your new view should be available!
