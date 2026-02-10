#!/bin/bash

# TODO-david need a better setup for mise installs
# echo "Install/update Mise"
# if ! command -v mise >/dev/null; then
#   curl -fsSL https://mise.run | sh
# else
#   mise self-update || true
# fi

# Update tldr definitions
tldr --update || true

# Install optional packages
log "Getting list of optional packages to install..."
if [ ! -f $COFFEE_INSTALL/optional.packages ]; then
  error "Package list not found: $COFFEE_INSTALL/optional.packages"
  exit 1
fi

# Array to track packages that need installation
declare -a optional_packages=()
mapfile -t optional_packages < <(
  grep -Ev '^(#|$)' "$COFFEE_INSTALL/optional.packages" || true
)
install_missing_packages "${optional_packages[@]}"

# Default browser
xdg-settings set default-web-browser firefox.desktop

# Create base home directories
log "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  run_logged "Creating $HOME/$dir" \
    "mkdir -p "$HOME/$dir""
done

# Rebuild font cache
log "Rebuilding font cache..."
fc-cache -fv >/dev/null

# Create zsh cache
log "Creating zsh cache directory..."
mkdir -p ~/.cache/zsh

# TODO-david move to env var
# Safety: enable wayland for firefox
# echo 'export MOZ_ENABLE_WAYLAND=1' > ~/.config/environment.d/firefox.conf

# Set shell
log "Changing default shell..."
chsh -s /bin/zsh
