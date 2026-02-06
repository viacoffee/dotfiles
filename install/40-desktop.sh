#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
if [[ ! -f "$INSTALL_DIR/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found: $INSTALL_DIR/lib/helpers.sh" >&2
  exit 1
fi

source "$INSTALL_DIR/lib/helpers.sh"

# Install desktop packages
install_packages_from_file "$INSTALL_DIR/desktop.packages"

# Rebuild font cache
fc-cache -fv >/dev/null

# Set shell
chsh -s /bin/zsh

# Create zsh cache
mkdir -p ~/.cache/zsh

# Safety: enable wayland for firefox
#echo 'export MOZ_ENABLE_WAYLAND=1' > ~/.config/environment.d/firefox.conf
