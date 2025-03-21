#!/bin/bash

# Check if the directory is provided as a parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Convert the given directory to an absolute path
DIRECTORY=$(realpath "$1")

# Calculate the desired paths
PARENT_DIR=$(realpath "$DIRECTORY/..")
GRANDPARENT_DIR=$(realpath "$PARENT_DIR/..")
LIB_PATH="$PARENT_DIR"
INCLUDE_PATH="$GRANDPARENT_DIR/include"

# Iterate over all pkg-config files in the directory
for FILE in "$DIRECTORY"/*.pc; do
  if [ -f "$FILE" ]; then
    # Adjust libdir and includedir to the desired path
    sed -i "" "s|^libdir=.*|libdir=$LIB_PATH|" "$FILE"
    sed -i "" "s|^includedir=.*|includedir=$INCLUDE_PATH|" "$FILE"
    echo "Modified: $FILE"
  fi
done
