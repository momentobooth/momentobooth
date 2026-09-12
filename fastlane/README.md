fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### ci_install_release_cert_using_api

```sh
[bundle exec] fastlane ci_install_release_cert_using_api
```

CI: install the Developer ID certificate and Direct profile using an App Store Connect API key

### install_dev_cert

```sh
[bundle exec] fastlane install_dev_cert
```

Install the development certificate and profile into your login keychain, needed to run debug builds

### install_release_cert

```sh
[bundle exec] fastlane install_release_cert
```

Install the Developer ID certificate and profile into your login keychain, needed to make release builds

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
