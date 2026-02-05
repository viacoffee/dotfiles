#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
if [[ ! -f "$INSTALL_DIR/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found: $INSTALL_DIR/lib/helpers.sh" >&2
  exit 1
fi

source "$INSTALL_DIR/lib/helpers.sh"

# Update our pacman.conf
PACMAN_CONF="/etc/pacman.conf"
sudo mv "$PACMAN_CONF" "$PACMAN_CONF.bak"
sudo cp "$INSTALL_DIR/pacman.conf" "$PACMAN_CONF"

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

# Setup greetd/tuigreet
sudo useradd -r -s /usr/bin/nologin greeter
sudo mkdir -p /etc/greetd && sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --asterisks --cmd niri-session"
user = "greeter"
EOF
