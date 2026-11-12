#!/usr/bin/env bash
# Has Apple notarize an app bundle or disk image, and staples the resulting ticket to it, so that Gatekeeper accepts it without having
# to contact Apple.
#
# Usage: macos/ci_notarize.sh <app bundle or dmg>
# Needs the App Store Connect API key in the environment variables that fastlane uses as well: APP_STORE_CONNECT_KEY_ID,
# APP_STORE_CONNECT_ISSUER_ID and APP_STORE_CONNECT_KEY (the base64 encoded .p8 file).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <app bundle or dmg>" >&2
  exit 1
fi
target=$1

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
base64 --decode <<<"$APP_STORE_CONNECT_KEY" > "$work/AuthKey.p8"
credentials=(--key "$work/AuthKey.p8" --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$APP_STORE_CONNECT_ISSUER_ID")

upload=$target
if [[ -d "$target" ]]; then
  # The notary service only accepts archives. ditto keeps the symbolic links in the bundle, which its signature depends on.
  upload=$work/$(basename "$target").zip
  ditto -c -k --keepParent "$target" "$upload"
fi

echo "Notarizing $target"
submission=$(xcrun notarytool submit "$upload" "${credentials[@]}" --wait --output-format json)
if [[ "$(jq -r .status <<<"$submission")" != Accepted ]]; then
  echo "Notarization failed: $submission" >&2
  # The log lists the binaries that were rejected, and why.
  xcrun notarytool log "$(jq -r .id <<<"$submission")" "${credentials[@]}" >&2
  exit 1
fi

xcrun stapler staple "$target"
