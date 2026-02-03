#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
if [[ ! -f "$INSTALL_DIR/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found: $INSTALL_DIR/lib/helpers.sh" >&2
  exit 1
fi

source "$INSTALL_DIR/lib/helpers.sh"

# Detect NVIDIA GPU with error handling
NVIDIA=""
if ! NVIDIA="$(lspci | grep -i 'nvidia')" 2>/dev/null; then
  warn "Failed to query GPU info (lspci not available or error occurred)"
  NVIDIA=""
fi

if [[ -z "$NVIDIA" ]]; then
  info "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
  exit 0
fi

info "NVIDIA GPU detected: $NVIDIA"

# Verify RTX 30xx+ (Ampere and newer)
if ! echo "$NVIDIA" | grep -qE "RTX (30|40|50)|RTX [4-9]|A[0-9]{2,}|H[0-9]{2,}"; then
  warn "Warning: NVIDIA GPU detected but not RTX 30xx or newer."
  warn "Only RTX 30xx+ (Ampere) and newer cards are supported."
  warn "For older cards, see: https://wiki.archlinux.org/title/NVIDIA"
  exit 0
fi

info "RTX 30xx+ GPU detected. Configuring open-source NVIDIA drivers..."

# Verify required packages were installed
# Note: Packages installed by 10-system.sh from system.packages
# - nvidia-open-dkms
# - nvidia-utils
# - lib32-nvidia-utils
# - libva-nvidia-driver
# - egl-wayland

# Configure modprobe for early KMS
info "Configuring modprobe for NVIDIA early KMS..."
if ! sudo mkdir -p /etc/modprobe.d; then
  error "Failed to create modprobe.d directory"
  exit 1
fi

if ! sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
EOF
then
  error "Failed to write modprobe configuration"
  exit 1
fi

# Configure mkinitcpio for early module loading
info "Configuring mkinitcpio for NVIDIA modules..."
if ! sudo mkdir -p /etc/mkinitcpio.conf.d; then
  error "Failed to create mkinitcpio.conf.d directory"
  exit 1
fi

if ! sudo tee /etc/mkinitcpio.conf.d/nvidia.conf >/dev/null <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF
then
  error "Failed to write mkinitcpio configuration"
  exit 1
fi

# Regenerate initramfs with NVIDIA modules
info "Regenerating initramfs with NVIDIA modules..."
if ! sudo mkinitcpio -P; then
  error "Failed to regenerate initramfs"
  exit 1
fi

# Set NVIDIA environment variables for Wayland/Niri
info "Configuring NVIDIA environment variables..."
if ! mkdir -p ~/.config/environment.d; then
  error "Failed to create environment.d directory"
  exit 1
fi

if ! cat >> ~/.config/environment.d/nvidia.conf <<'EOF'
# NVIDIA drivers for Wayland/Niri
NVD_BACKEND=direct
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
then
  error "Failed to write environment configuration"
  exit 1
fi

info "NVIDIA drivers configured successfully."
warn "Note: System reboot may be required for changes to take effect."

NVIDIA=""
if ! NVIDIA="$(lspci | grep -i 'nvidia')" 2>/dev/null; then
  warn "Failed to query GPU info (lspci not available or error occurred)"
  NVIDIA=""
fi

if [[ -z "$NVIDIA" ]]; then
  info "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
  exit 0
fi

info "NVIDIA GPU detected: $NVIDIA"

# Verify RTX 30xx+ (Ampere and newer)
if ! echo "$NVIDIA" | grep -qE "RTX (30|40|50)|RTX [4-9]|A[0-9]{2,}|H[0-9]{2,}"; then
  warn "Warning: NVIDIA GPU detected but not RTX 30xx or newer."
  warn "Only RTX 30xx+ (Ampere) and newer cards are supported."
  warn "For older cards, see: https://wiki.archlinux.org/title/NVIDIA"
  exit 0
fi

info "RTX 30xx+ GPU detected. Configuring open-source NVIDIA drivers..."

# Verify required packages were installed
# Note: Packages installed by 10-system.sh from system.packages
# - nvidia-open-dkms
# - nvidia-utils
# - lib32-nvidia-utils
# - libva-nvidia-driver
# - egl-wayland

# Configure modprobe for early KMS
info "Configuring modprobe for NVIDIA early KMS..."
if ! sudo mkdir -p /etc/modprobe.d; then
  error "Failed to create modprobe.d directory"
  exit 1
fi

if ! sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
EOF
then
  error "Failed to write modprobe configuration"
  exit 1
fi

# Configure mkinitcpio for early module loading
info "Configuring mkinitcpio for NVIDIA modules..."
if ! sudo mkdir -p /etc/mkinitcpio.conf.d; then
  error "Failed to create mkinitcpio.conf.d directory"
  exit 1
fi

if ! sudo tee /etc/mkinitcpio.conf.d/nvidia.conf >/dev/null <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF
then
  error "Failed to write mkinitcpio configuration"
  exit 1
fi

# Regenerate initramfs with NVIDIA modules
info "Regenerating initramfs with NVIDIA modules..."
if ! sudo mkinitcpio -P; then
  error "Failed to regenerate initramfs"
  exit 1
fi

# Set NVIDIA environment variables for Wayland/Niri
info "Configuring NVIDIA environment variables..."
if ! mkdir -p ~/.config/environment.d; then
  error "Failed to create environment.d directory"
  exit 1
fi

if ! cat >> ~/.config/environment.d/nvidia.conf <<'EOF'
# NVIDIA drivers for Wayland/Niri
NVD_BACKEND=direct
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
then
  error "Failed to write environment configuration"
  exit 1
fi

info "NVIDIA drivers configured successfully."
warn "Note: System reboot may be required for changes to take effect."
