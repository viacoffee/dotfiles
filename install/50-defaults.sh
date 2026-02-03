#!/usr/bin/env bash
set -euo pipefail

# Default terminal
echo "Set default terminal to alacritty"
xdg-mime default alacritty.desktop x-scheme-handler/terminal || true

# Default browser
echo "Set default browser to firefox"
xdg-settings set default-web-browser firefox.desktop || true

echo "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
mkdir -p "$HOME"/"${DEFAULT_DIRS[@]}"
