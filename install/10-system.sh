#!/bin/bash

# System phase - verify and install required system packages
section "System management"

log "Update system, and verify/install system packages..."

# Update our pacman.conf
PACMAN_CONF="/etc/pacman.conf"
log "Double check we have the omarchy pacman repo"
if ! grep -q "omarchy" $PACMAN_CONF; then
  run_logged "Creating pacman.conf backup: $PACMAN_CONF.bak" \
    sudo mv "$PACMAN_CONF" "$PACMAN_CONF.bak"

  run_logged "Copying from: $COFFEE_INSTALL/pacman.conf to: $PACMAN_CONF" \
    sudo cp "$COFFEE_INSTALL/pacman.conf" "$PACMAN_CONF"
else
  log "omarchy found in $PACMAN_CONF"
fi

# Update system
info "Updating system..."
if ! sudo pacman -Syu --noconfirm; then
  error "Failed to update system packages"
fi

# Install required system packages
log "Getting list of required system packages..."
if [ ! -f $COFFEE_INSTALL/system.packages ]; then
  error "Package list not found: $COFFEE_INSTALL/system.packages"
fi

# Array to track packages that need installation
declare -a system_packages=()
mapfile -t system_packages < <(
  grep -Ev '^(#|$)' "$COFFEE_INSTALL/system.packages" || true
)
install_missing_packages "${system_packages[@]}"

echo ""
success "System management phase complete"


# TODO-david move this to the login steps
# Setup greetd/tuigreet
# if ! id greeter &>/dev/null; then
#   sudo useradd -r -s /usr/bin/nologin greeter
# fi
#
# sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
# [terminal]
# vt = 1
#
# [default_session]
# command = "tuigreet --asterisks --window-padding 2 --container-padding 1 --width 50 --cmd niri-session"
# user = "greeter"
# EOF
