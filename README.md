<p align="center"> 
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/svg/MomentoBooth-combined-logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="assets/svg/MomentoBooth-combined-logo-light.svg">
  <img  style="max-width: 800px" alt="MomentoBooth combined logo" src="assets/svg/MomentoBooth-combined-logo-light.svg">
</picture>
</p>

<h3 align="center">Cross-platform open source photo booth software. Capture your events in an easy and fun way!</h3>

<p align="center">
<a href="https://discord.gg/mCMEv2fHSN" title="Join our Discord server!">
  <img src="https://img.shields.io/discord/1434316075633344643?label=Discord">
</a>
<img src="https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-win-x64.yml?label=Windows%20build" alt="GitHub Windows build workflow status">
<img src="https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-macos-arm64.yml?label=macOS%20build" alt="GitHub macOS build workflow status">
<img src="https://img.shields.io/github/actions/workflow/status/momentobooth/momentobooth/release-linux-appimage-x64.yml?label=Linux%20build" alt="GitHub linux build workflow status">
<a href="https://github.com/momentobooth/momentobooth/releases">
  <img title="GitHub release (latest SemVer including pre-releases)" src="https://img.shields.io/github/v/release/momentobooth/momentobooth?include_prereleases&label=Latest%20version">
</a>
<a href="https://hosted.weblate.org/engage/momentobooth-photobooth/">
  <img src="https://hosted.weblate.org/widget/momentobooth-photobooth/svg-badge.svg" alt="Translation status" />
</a>
</p>

## Links
- [Download the latest release from GitHub](https://github.com/momentobooth/momentobooth/releases)
- [Documentation](https://momentobooth.github.io/momentobooth/)
- Join our [Discord server](https://discord.gg/mCMEv2fHSN)!

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
* Windows arm64 distribution
* Up to date macOS builds (with correct signing)

## Development

For development setup instructions, see the [dev documentation](https://momentobooth.github.io/momentobooth/dev_setup.html).

## Translations

MomentoBooth [uses the awesome Weblate](https://hosted.weblate.org/engage/momentobooth-photobooth/) to manage translations. If you would like to add a new language or improve existing translations, please use Weblate to make suggestions — Weblate will automatically create a PR for you!
