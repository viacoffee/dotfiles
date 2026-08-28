#!/bin/bash

log "Updating system and installing required packages..."

# Update our pacman.conf
PACMAN_CONF="/etc/pacman.conf"
log "Double check we have the omarchy pacman repo"
if ! grep -q "omarchy" "$PACMAN_CONF"; then
  run_logged "Creating pacman.conf backup: $PACMAN_CONF.bak" \
    sudo mv "$PACMAN_CONF" "$PACMAN_CONF.bak"

  run_logged "Copying from: $DOTFILES_INSTALL_DEFAULTS_PATH/pacman/pacman.conf to: $PACMAN_CONF" \
    sudo cp "$DOTFILES_INSTALL_DEFAULTS_PATH/pacman/pacman.conf" "$PACMAN_CONF"
else
  log "omarchy found in $PACMAN_CONF"
fi

# Update system
log "Updating system..."
if ! sudo pacman -Syu --noconfirm; then
  error "Failed to update system"
  return 1
fi

# Install required packages
log "Getting list of required packages..."
if [[ ! -f "$DOTFILES_INSTALL/packages" ]]; then
  error "Package list not found: $DOTFILES_INSTALL/packages"
  return 1
fi

declare -a required_packages=()
mapfile -t required_packages < <(
  grep -Ev '^(#|$)' "$DOTFILES_INSTALL/packages" || true
)
install_missing_packages "${required_packages[@]}"
