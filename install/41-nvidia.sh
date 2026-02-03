#!/usr/bin/env bash
set -euo pipefail

# Detect NVIDIA GPU
NVIDIA="$(lspci | grep -i 'nvidia')" || true

if [ -z "$NVIDIA" ]; then
  echo "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
  exit 0
fi

echo "NVIDIA GPU detected: $NVIDIA"

# Verify RTX 30xx+ (Ampere and newer)
if ! echo "$NVIDIA" | grep -qE "RTX (30|40|50)|RTX [4-9]|A[0-9]{2,}|H[0-9]{2,}"; then
  echo "Warning: NVIDIA GPU detected but not RTX 30xx or newer."
  echo "Only RTX 30xx+ (Ampere) and newer cards are supported."
  echo "For older cards, see: https://wiki.archlinux.org/title/NVIDIA"
  exit 0
fi

echo "RTX 30xx+ GPU detected. Configuring open-source NVIDIA drivers..."

# Note: Packages installed by 10-system.sh from system.packages
# - nvidia-open-dkms
# - nvidia-utils
# - lib32-nvidia-utils
# - libva-nvidia-driver
# - egl-wayland

# Configure modprobe for early KMS
sudo mkdir -p /etc/modprobe.d
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
EOF

# Configure mkinitcpio for early module loading
sudo mkdir -p /etc/mkinitcpio.conf.d
sudo tee /etc/mkinitcpio.conf.d/nvidia.conf >/dev/null <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF

# Regenerate initramfs with NVIDIA modules
echo "Regenerating initramfs with NVIDIA modules..."
sudo mkinitcpio -P

# Set NVIDIA environment variables for Wayland/Niri
mkdir -p ~/.config/environment.d
cat >> ~/.config/environment.d/nvidia.conf <<'EOF'
# NVIDIA drivers for Wayland/Niri
NVD_BACKEND=direct
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
EOF

echo "NVIDIA drivers configured successfully."
echo "Note: System reboot may be required for changes to take effect."
