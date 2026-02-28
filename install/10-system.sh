#!/bin/bash

log "Update system, and verify/install base packages..."

# Update our pacman.conf
PACMAN_CONF="/etc/pacman.conf"
log "Double check we have the omarchy pacman repo"
if ! grep -q "omarchy" "$PACMAN_CONF"; then
  run_logged "Creating pacman.conf backup: $PACMAN_CONF.bak" \
    sudo mv "$PACMAN_CONF" "$PACMAN_CONF.bak"

  run_logged "Copying from: $COFFEE_INSTALL_DEFAULTS_PATH/pacman/pacman.conf to: $PACMAN_CONF" \
    sudo cp "$COFFEE_INSTALL_DEFAULTS_PATH/pacman/pacman.conf" "$PACMAN_CONF"
else
  log "omarchy found in $PACMAN_CONF"
fi

# Update system
log "Updating system..."
if ! sudo pacman -Syu --noconfirm; then
  error "Failed to update base packages"
  return 1
fi

# Install required base packages
log "Getting list of required base packages..."
if [[ ! -f "$COFFEE_INSTALL/base.packages" ]]; then
  error "Package list not found: $COFFEE_INSTALL/base.packages"
  return 1
fi

# Array to track packages that need installation
declare -a base_packages=()
mapfile -t base_packages < <(
  grep -Ev '^(#|$)' "$COFFEE_INSTALL/base.packages" || true
)
install_missing_packages "${base_packages[@]}"
