#!/usr/bin/env bash
set -euo pipefail

# Bluetooth
systemctl enable --now bluetooth.service

# Wifi
if systemctl is-active --quiet NetworkManager; then
  systemctl disable --now NetworkManager
fi
systemctl enable --now iwd.service
