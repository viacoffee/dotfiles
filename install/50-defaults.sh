#!/usr/bin/env bash
set -euo pipefail

# Default terminal
xdg-mime default alacritty.desktop x-scheme-handler/terminal || true

# Default browser
xdg-settings set default-web-browser firefox.desktop || true
