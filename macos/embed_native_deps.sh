#!/bin/sh
# Copies libgphoto2, its dependencies and its camera and port drivers into the app bundle, from the native dependencies downloaded by
# macos/get_native_deps.sh. Runs as a build phase of the Runner target, which provides the environment variables.

set -e

native_deps="$PROJECT_DIR/../.native_deps/macos-arm64"
if [ ! -f "$native_deps/manifest.json" ]; then
  echo "error: Native dependencies not found, run 'just get-native-deps' first" >&2
  exit 1
fi

# The Runner target has this directory as an rpath, through which the libraries and drivers find each other.
libs="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Libs"
rm -rf "$libs"
mkdir -p "$libs/Camlibs" "$libs/Iolibs"
# Only regular files: the symbolic links next to them are for linking.
find "$native_deps/lib" -maxdepth 1 -type f -name '*.dylib' -exec cp {} "$libs/" \;
# The driver directories are versioned (e.g. lib/libgphoto2/2.5.34), the application expects them at a fixed location.
cp "$native_deps"/lib/libgphoto2/*/*.so "$libs/Camlibs/"
cp "$native_deps"/lib/libgphoto2_port/*/*.so "$libs/Iolibs/"

# The native dependencies are ad hoc signed, Gatekeeper requires every binary in the app bundle to be signed with the identity of the app.
if [ -n "$EXPANDED_CODE_SIGN_IDENTITY" ]; then
  find "$libs" -type f -exec codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} {} +
fi
