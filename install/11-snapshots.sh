#!/usr/bin/env bash
set -euo pipefail

# Create default snapper configuration for root filesystem if not exists
if [ ! -d /etc/snapper/configs ]; then
  sudo mkdir -p /etc/snapper/configs
fi

# Initialize snapper for root filesystem if not already configured
if ! sudo snapper list-configs | grep -q root; then
  sudo snapper -c root create-config / || true
fi

# Enable and start snapper timeline service
sudo systemctl enable --now snapper-timeline.timer || true
sudo systemctl enable --now snapper-cleanup.timer || true
