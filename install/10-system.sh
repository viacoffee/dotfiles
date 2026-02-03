#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/install" && pwd)"
source "$INSTALL_DIR/lib/helpers.sh"

# Update system
sudo pacman -Syu --noconfirm

# Install required system packages
install_packages_from_file "$INSTALL_DIR/system.packages"
