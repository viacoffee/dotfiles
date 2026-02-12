#!/bin/bash

# Bluetooth
if ! systemctl is-enabled --quiet bluetooth.service && ! systemctl is-active --quiet bluetooth.service; then
  sudo systemctl enable bluetooth.service
fi

# Wifi
if systemctl is-active --quiet NetworkManager; then
  sudo systemctl disable NetworkManager
fi

if ! systemctl is-active --quiet iwd && ! systemctl is-active --quiet NetworkManager; then
  sudo systemctl enable iwd.service
fi

# Snapper-sync
if ! systemctl is-active --quiet limine-snapper-sync; then
  sudo systemctl enable limine-snapper-sync.service
fi

# Greetd
if ! systemctl is-enabled --quiet greetd.service; then
  sudo systemctl enable greetd.service
fi
