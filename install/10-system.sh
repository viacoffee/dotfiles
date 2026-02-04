#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
if [[ ! -f "$INSTALL_DIR/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found: $INSTALL_DIR/lib/helpers.sh" >&2
  exit 1
fi

source "$INSTALL_DIR/lib/helpers.sh"

# Make sure multilib is active
PACMAN_CONF="/etc/pacman.conf"

if ! grep -q '^\[multilib\]' "$PACMAN_CONF"; then
  sudo tee -a "$PACMAN_CONF" >/dev/null <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
else
  sudo sed -i \
    -e 's/^#\[multilib\]/[multilib]/' \
    -e 's|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|' \
    "$PACMAN_CONF"
fi

# Update system
info "Updating package manager..."
if ! sudo pacman -Syu --noconfirm; then
  error "Failed to update system packages"
  exit 1
fi

# Install required system packages
if [[ ! -f "$INSTALL_DIR/system.packages" ]]; then
  error "Package list not found: $INSTALL_DIR/system.packages"
  exit 1
fi

install_packages_from_file "$INSTALL_DIR/system.packages" || exit 1
