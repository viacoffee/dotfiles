#!/usr/bin/env bash
set -euo pipefail

# Try for force dark mode on gtk applications
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-blue"

# Default browser
xdg-settings set default-web-browser firefox.desktop

# Create base home directories
echo "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
mkdir -p "$HOME"/"${DEFAULT_DIRS[@]}"
