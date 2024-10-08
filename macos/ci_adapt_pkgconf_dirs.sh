#!/bin/bash

# Controleer of de directory is opgegeven als parameter
if [ -z "$1" ]; then
  echo "Gebruik: $0 <directory>"
  exit 1
fi

# Zet de opgegeven directory om in een absoluut pad
DIRECTORY=$(realpath "$1")

# Bereken de gewenste paden
PARENT_DIR=$(realpath "$DIRECTORY/..")
GRANDPARENT_DIR=$(realpath "$PARENT_DIR/..")
LIB_PATH="$PARENT_DIR"
INCLUDE_PATH="$GRANDPARENT_DIR/include"

# Itereer over alle pkg-config bestanden in de directory
for FILE in "$DIRECTORY"/*.pc; do
  if [ -f "$FILE" ]; then
    # Pas libdir en includedir aan naar het gewenste pad
    sed -i "" "s|^libdir=.*|libdir=$LIB_PATH|" "$FILE"
    sed -i "" "s|^includedir=.*|includedir=$INCLUDE_PATH|" "$FILE"
    echo "Aangepast: $FILE"
  fi
done
