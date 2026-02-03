#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --needed --noconfirm \
  bluez \
  bluez-utils \
  blueman

sudo systemctl enable --now bluetooth.service
