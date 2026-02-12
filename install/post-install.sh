#!/bin/bash

# Exit immediately if a command exists with a non-zero status
set -eEo pipefail

# if [ -z "$COFFEE_INSTALL" ]; then
#   export COFFEE_INSTALL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# fi
#
# Update tldr definitions
tldr --update || true

# Install optional packages
echo "Getting list of optional packages to install..."
if [ ! -f $COFFEE_INSTALL/optional.packages ]; then
  echo "Package list not found: $COFFEE_INSTALL/optional.packages"
  exit 1
fi

# echo "Installing optional packages..."
# # Array to track packages that need installation
# declare -a optional_packages=()
# mapfile -t optional_packages < <(
#   grep -Ev '^(#|$)' "$COFFEE_INSTALL/optional.packages" || true
# )
#
# if ((${#optional_packages[@]})); then
#   sudo pacman -S --noconfirm --needed "${optional_packages[@]}"
# fi

# Rebuild font cache
# echo "Rebuilding font cache..."
# fc-cache -fv >/dev/null

# Default browser
# xdg-settings set default-web-browser firefox.desktop

# Create base home directories
echo "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done

source "$COFFEE_INSTALL/post-install/all.sh"

echo "Post installation complete! You may now exit."
