#!/bin/bash
# shellcheck disable=SC2034 # Values are consumed by build_project after sourcing.

BUILD_NAME=dot-system
BUILD_SOURCE="$DOTFILES_PATH/bin/dot-system"
BUILD_REVISION=$(find "$BUILD_SOURCE" -type f \( -name '*.go' -o -name go.mod -o -name go.sum \) -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  | sha256sum \
  | awk '{print $1}')
BUILD_KIND=go
BUILD_BINARY=dot-system
BUILD_BINARIES=(dot-system update-helper)
BUILD_INSTALL_DIR="$HOME/.local/bin"
