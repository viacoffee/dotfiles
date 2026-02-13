#!/bin/bash

# Add daemons to niri-service
systemctl_want_enable() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: autostart_user_service SERVICE [SERVICE...]"
    return 1
  fi

  for svc in "$@"; do
    # Add to default.target wants
    run_logged "enabling $svc" \
      "systemctl --user add-wants default.target niri.service $svc"
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
  swayosd

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

log "Updating tldr"
tldr --update || true

# Set shell
log "Changing default shell..."
chsh -s /bin/zsh
