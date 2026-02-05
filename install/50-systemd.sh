#!/usr/bin/env bash
set -euo pipefail

# Bluetooth
if ! systemctl is-enabled --quiet bluetooth.service && ! systemctl is-active --quiet bluetooth.service; then
  sudo systemctl enable --now bluetooth.service
fi

# Wifi
if systemctl is-active --quiet NetworkManager; then
  sudo systemctl disable --now NetworkManager
fi

if ! systemctl is-active --quiet iwd; then
  sudo systemctl enable --now iwd.service
fi

# Snapper-sync
if ! systemctl is-active --quiet limine-snapper-sync; then
  sudo systemctl enable --now limine-snapper-sync.service
fi
