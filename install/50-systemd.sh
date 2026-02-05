#!/usr/bin/env bash
set -euo pipefail

# Bluetooth
sudo systemctl enable --now bluetooth.service

# Wifi
if sudo systemctl is-active --quiet NetworkManager; then
  sudo systemctl disable --now NetworkManager
fi
sudo systemctl enable --now iwd.service
