#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --needed --noconfirm \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  libva-nvidia-driver \
  egl-wayland

# Enable DRM KMS (required for Wayland)
if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="nvidia_drm.modeset=1 /' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Ensure modules load early
sudo mkdir -p /etc/modprobe.d
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<EOF
options nvidia_drm modeset=1
EOF

echo "NVIDIA installed. Reboot required before starting niri."
