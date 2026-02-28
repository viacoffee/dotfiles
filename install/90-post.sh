#!/bin/bash

# Add daemons to niri-service
systemctl_want_enable() {
  if [[ "$#" -lt 1 ]]; then
    error "Usage: systemctl_want_enable SERVICE [SERVICE...]"
    return 1
  fi

  for svc in "$@"; do
    run_logged "enabling $svc" \
      systemctl --user add-wants default.target niri.service "$svc"
  done
}

# Create zsh cache
log "Creating zsh cache directory..."
mkdir -p ~/.cache/zsh

# add-wants for user/niri
systemctl_want_enable \
  waybar \
  mako \
  swaybg \
  swayidle \
  swayosd \
  coffee-first-login

log "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done

# Refresh font cache
fc-cache -f

# Array to track packages that need installation
declare -a optional_packages=()
mapfile -t optional_packages < <(
  grep -Ev '^(#|$)' "$COFFEE_INSTALL/optional.packages" || true
)
install_missing_packages "${optional_packages[@]}"

# Enable dnd mode for mako (deferred to first login)
touch "$HOME/.first-login"

log "Updating tldr"
tldr --update || true

# Set shell
log "Changing default shell..."
sudo usermod -s /bin/zsh "$COFFEE_DEFAULT_USER"
