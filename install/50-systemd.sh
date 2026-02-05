#!/usr/bin/env bash
set -euo pipefail

# Bluetooth
if ! systemctl is-enabled --quiet bluetooth.service && ! systemctl is-active --quiet bluetooth.service; then
  sudo systemctl enable --now bluetooth.service
fi

# Wifi
if sudo systemctl is-active --quiet NetworkManager; then
  sudo systemctl disable --now NetworkManager
fi

if ! sudo systemctl is-active --quiet iwd; then
  sudo systemctl enable --now iwd.service
fi
