#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/install" && pwd)"
source "$INSTALL_DIR/lib/helpers.sh"

# Install desktop packages
install_packages_from_file "$INSTALL_DIR/desktop.packages"

# Install extra packages
install_packages_from_file "$INSTALL_DIR/extra.packages"

# Rebuild font cache
fc-cache -fv >/dev/null
