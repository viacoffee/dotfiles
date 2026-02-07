#!/usr/bin/env bash
set -euo pipefail

# Try for force dark mode on gtk applications
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Create base home directories
echo "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
mkdir -p "$HOME"/"${DEFAULT_DIRS[@]}"
