#!/bin/bash

show_help() {
  echo "Usage: $0 [options] <package1> <package2> ..."
  echo ""
  echo "Options:"
  echo "  -a, --architectures <arch1,arch2,...>   Comma-separated list of architectures"
  echo "  -h, --help                              Show this help message"
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a|--architectures)
      architectures="$2"
      shift 2;;
    -h|--help)
      show_help
      exit 0;;
    -*|--*)
      echo "Unknown option: $1"
      show_help
      exit 1;;
    *)
      packages+=("$1")
      shift;;
  esac
done

# Check if at least one package is provided
if [ ${#packages[@]} -eq 0 ]; then
  echo "Error: No packages specified."
  show_help
  exit 1
fi

download_package() {
  local package=$1
  local json=$(brew info --json=v2 $package)

  # Download bottles for specified architectures
  IFS=',' read -ra arch_array <<< "$architectures"
  for arch in "${arch_array[@]}"; do
    # Gebruik 'jq' om specifiek de URL van de bottle te pakken
    local url=$(echo $json | jq -r ".formulae[0].bottle.stable.files.\"$arch\".url")
    if [ "$url" != "null" ]; then
      local filename="${arch}_${package}.tar.gz"
      echo $filename
      if [ -f "$filename" ]; then
        echo "$filename already exists, skipping download..."
      else
        echo "Downloading $package for $arch..."
        curl --header "Authorization: Bearer QQ==" -L -o brew_downloads/$filename $url
      fi

      if [[ $filename == *.tar.gz ]]; then
        # Extract the version directory directly to the architecture-specific directory
        mkdir -p "$arch"
        tar -xzf brew_downloads/$filename --strip-components=2 -C "$arch" "${package}/*"
      else
        echo "Downloaded file format not recognized for extraction: $filename"
      fi
    else
      echo "No bottle available for $package on $arch"
    fi
  done
  
  # Recursively download dependencies
  local dependencies=$(echo $json | jq -r ".formulae[0].dependencies[]")
  for dep in $dependencies; do
    download_package $dep
  done
}

# Start by downloading the specified packages
mkdir brew_downloads
for pkg in "${packages[@]}"; do
  download_package $pkg
done
